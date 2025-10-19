import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../../../../../../config/http/dio_client.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../../shared/domain/entities/response_api.dart';
import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../providers/locator_provider.dart';
import '../../store_on_hand/memory_products.dart';

final movementAndLinesProvider = StateProvider.autoDispose<MovementAndLines>((ref) {
  return MemoryProducts.movementAndLines;
});



final quantityToMoveProvider = StateProvider.autoDispose<double>((ref) {
  return 0;
});

final checkCanInsertMovementProvider = Provider<bool>((ref) {
  final quantity = ref.watch(quantityToMoveProvider);
  final locatorTo = ref.watch(selectedLocatorToProvider);
  return quantity > 0 && locatorTo.id != null && locatorTo.id! > 0;
});

final putAwayMovementCreateProvider = StateProvider.autoDispose<PutAwayMovement?>((ref) {
  return null;
});

final newPutAwayMovementProvider = FutureProvider.autoDispose<MovementAndLines?>((ref) async {

  PutAwayMovement? newMovement = ref.watch(putAwayMovementCreateProvider);
  if(newMovement == null) return null;
  print('-${newMovement.canCreatePutAwayMovement() ==PutAwayMovement.SUCCESS}------newSqlDataPutAwayMovementProvider.notifier');

  Dio dio = await DioClient.create();
  MemoryProducts.movementAndLines = MovementAndLines(user: Memory.sqlUsersData);

  try {
    String url = newMovement.movementInsertUrl!;
    final response = await dio.post(url, data: newMovement.movementInsertJson);
    print(url);
    if (response.statusCode == 201) {

      IdempiereMovement movement =  IdempiereMovement.fromJson(response.data);
      if (movement.id != null && movement.id! > 0) {
        MemoryProducts.movementAndLines.cloneMovement(movement);
        newMovement.movementLineToCreate!.mMovementID = movement;
        var creteDataJsonEncode2 =  newMovement.movementLineInsertJson! ;
        String url2 = newMovement.movementLineInsertUrl!;
        print(url2);
        print(creteDataJsonEncode2);
        print('----------------------------------createTed');
        final responseLine = await dio.post(url2, data: creteDataJsonEncode2);
        if (responseLine.statusCode == 201) {
          final IdempiereMovementLine movementLine =  IdempiereMovementLine.fromJson(responseLine.data);
          MemoryProducts.movementAndLines.movementLines = [movementLine];
        }
        return MemoryProducts.movementAndLines;
      } else {
        return MemoryProducts.movementAndLines;
      }
    } else {
      return MemoryProducts.movementAndLines;
    }
  } on DioException {
    return MemoryProducts.movementAndLines;
  } catch (e) {
    return MemoryProducts.movementAndLines;
  }

});

final newScannedMovementIdForSearchProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
final newMovementIdForMovementLineSearchProvider  = StateProvider.autoDispose<int>((ref) {
  return -1;
});



final newFindMovementByIdOrDocumentNOProvider = FutureProvider.autoDispose<MovementAndLines>((ref) async {
  final String scannedCode = ref.watch(newScannedMovementIdForSearchProvider).toUpperCase();
  print('----------------------------------start new searchMovementByIdOrDocumentNo $scannedCode');
  if(scannedCode=='') {
    MemoryProducts.movementAndLines.clearData();
    return MemoryProducts.movementAndLines;}
  String idempiereModelName ='m_movement';
  Dio dio = await DioClient.create();
  try {
    String url =  "/api/v1/models/$idempiereModelName";
    int? aux = int.tryParse(scannedCode);
    if(aux==null){
      url = "/api/v1/models/$idempiereModelName?\$filter=DocumentNo eq '$scannedCode'";
    } else{
      url = "/api/v1/models/$idempiereModelName?\$filter=M_Movement_ID eq $scannedCode";
    }
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereMovement>.fromJson(response.data, IdempiereMovement.fromJson);
      late IdempiereMovement m;
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        m = responseApi.records![0];
        if(m.id!=null) {
          MemoryProducts.movementAndLines.cloneMovement(m);
          await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, MemoryProducts.movementAndLines);
          //ref.read(newMovementIdForMovementLineSearchProvider.notifier).state = m.id!;

          if(m.id==null || m.id==Memory.INITIAL_STATE_ID || m.id!<=0) return MemoryProducts.movementAndLines;
          String searchField ='M_Movement_ID';
          String idempiereModelName ='m_movementline';
          Dio dio = await DioClient.create();
          String url =
              "/api/v1/models/$idempiereModelName?\$filter=$searchField eq ${m.id!}&\$orderby=Line";
          url = url.replaceAll(' ', '%20');
          print(url);
          final response = await dio.get(url);

          if (response.statusCode == 200) {

            final responseApi =
            ResponseApi<IdempiereMovementLine>.fromJson(response.data, IdempiereMovementLine.fromJson);
            if (responseApi.records != null && responseApi.records!.isNotEmpty) {
              final dataList = responseApi.records!;
              MemoryProducts.movementAndLines.movementLines = dataList;

            } else {
              MemoryProducts.movementAndLines.movementLines = [];
            }

          }


        } else {
          MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.NOT_FOUND,
              id: Memory.NOT_FOUND_ID,
              identifier: scannedCode));
        }

      } else {
        MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode));
      }

    } else {
      MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode));
    }
    return MemoryProducts.movementAndLines;
  } on DioException {
    MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.ERROR, id: Memory.ERROR_ID, identifier: scannedCode));
    return MemoryProducts.movementAndLines;

  } catch (e) {
    MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.ERROR, id: Memory.ERROR_ID, identifier: scannedCode));
    return MemoryProducts.movementAndLines;
  } finally {
    await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, MemoryProducts.movementAndLines);
  }

});


final newFindMovementLinesByMovementIdProvider = FutureProvider.autoDispose<MovementAndLines>((ref) async {
  final int? id = ref.watch(newMovementIdForMovementLineSearchProvider);
  print('----------------------------------start findMovementLinesByMovementIdProvider $id');
  MemoryProducts.movementAndLines.movementLines = null;
  if(id==null || id==Memory.INITIAL_STATE_ID || id<=0) return MemoryProducts.movementAndLines;
  String searchField ='M_Movement_ID';
  String idempiereModelName ='m_movementline';
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=$searchField eq $id&\$orderby=Line";
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {

      final responseApi =
      ResponseApi<IdempiereMovementLine>.fromJson(response.data, IdempiereMovementLine.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final dataList = responseApi.records!;
        if(dataList.isEmpty){
          MemoryProducts.movementAndLines.movementLines = [];
          await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, MemoryProducts.movementAndLines);
        } else {
          MemoryProducts.movementAndLines.movementLines = dataList;
          await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, MemoryProducts.movementAndLines);
          return MemoryProducts.movementAndLines;
        }
      }
    }
    MovementAndLines movementAndLines = MovementAndLines();
    movementAndLines.cloneMovementAndLines(MemoryProducts.movementAndLines);
    return MemoryProducts.movementAndLines;
  } on DioException {
    MovementAndLines movementAndLines = MovementAndLines();
    movementAndLines.cloneMovementAndLines(MemoryProducts.movementAndLines);
    return MemoryProducts.movementAndLines;
  } catch (e) {
    MovementAndLines movementAndLines = MovementAndLines();
    movementAndLines.cloneMovementAndLines(MemoryProducts.movementAndLines);
    return MemoryProducts.movementAndLines;
  }

});



