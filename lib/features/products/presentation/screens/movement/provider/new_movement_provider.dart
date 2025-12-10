import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/auth/presentation/providers/auth_provider.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../../../../../../config/http/dio_client.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../../shared/domain/entities/response_api.dart';
import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_confirm.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/locator_provider.dart';
import '../../store_on_hand/memory_products.dart';

final movementAndLinesProvider = StateProvider.autoDispose<MovementAndLines>((ref) {
  return MemoryProducts.movementAndLines;
});
final documentTyprFilterProvider = StateProvider<String>((ref) {
  return 'DR'; // valor inicial
});

// Opciones disponibles, fácil de expandir luego
const List<String> documentTypeOptionsAll = ['DR', 'IP', 'CO'];
const List<String> documentTypeOptionsForMovementConfirm = ['DR', 'IP', 'CO'];
const List<String> documentTypeOptionsForInventory = ['DR','CO'];

final copyLastLocatorToProvider = StateProvider<bool>((ref) => true);

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
  print('--------------------------------provider--start new searchMovementByIdOrDocumentNo $scannedCode');
  if(scannedCode=='') {
    MemoryProducts.movementAndLines.clearData();
    return MemoryProducts.movementAndLines;}
  String idempiereModelName ='m_movement';
  Dio dio = await DioClient.create();
  try {
    String url =  "/api/v1/models/$idempiereModelName";
    int? aux = int.tryParse(scannedCode);
    if(aux==null || scannedCode.startsWith('0')){
      url = "/api/v1/models/$idempiereModelName?\$filter=DocumentNo eq '$scannedCode'";
    } else{
      url = "/api/v1/models/$idempiereModelName?\$filter=M_Movement_ID eq $scannedCode";
    }
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      print(response.data);
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
          final String searchField ='M_Movement_ID';
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
          idempiereModelName ='m_movementconfirm';
          url =
              "/api/v1/models/$idempiereModelName?\$filter=$searchField eq ${m.id!}&\$orderby=Line";
          url = url.replaceAll(' ', '%20');
          print(url);
          final response2 = await dio.get(url);
          if (response2.statusCode == 200) {
            final responseApi =
            ResponseApi<IdempiereMovementConfirm>.fromJson(response2.data, IdempiereMovementConfirm.fromJson);
            if (responseApi.records != null && responseApi.records!.isNotEmpty) {
              final dataList = responseApi.records!;
              MemoryProducts.movementAndLines.movementConfirms = dataList;

            } else {
              MemoryProducts.movementAndLines.movementConfirms  = [];
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

final movementLineForEditQuantityToMoveProvider =
StateProvider.autoDispose.family<IdempiereMovementLine?, int>((ref, lineId) {
  return null;
});

final movementLineQuantityToMoveProvider =
StateProvider.autoDispose.family<IdempiereMovementLine?, int>((ref, lineId) {
  return null;
});


final editQuantityToMoveProvider =
FutureProvider.autoDispose.family<double?, int>((ref, lineId) async {

  final ml = ref.watch(movementLineForEditQuantityToMoveProvider(lineId));

  if (ml == null ||
      ml.id == null ||
      ml.id! < 0 ||
      ml.movementQty == null ||
      ml.movementQty! < 0) {
    return null;
  }

  Dio dio = await DioClient.create();

  try {
    SqlDataMovementLine movementLine =
    SqlDataMovementLine(id: ml.id, movementQty: ml.movementQty);
    Memory.sqlUsersData.copyToSqlData(movementLine);

    String url = movementLine.getUpdateUrl();
    print(url);
    print('---start-------------editMovementQuantityProvider');
    final response =
    await dio.put(url, data: movementLine.getUpdateMovementQuantityJson());
    print('---result-------------editMovementQuantityProvider ${response.statusCode}');

    if (response.statusCode == 200) {
      IdempiereMovementLine res = IdempiereMovementLine.fromJson(response.data);
      return res.movementQty;
    } else {
      // -1 = error HTTP
      return -1;
    }
  } on DioException catch (_) {
    // invalidamos solo el provider de esta línea
    ref.invalidate(movementLineForEditQuantityToMoveProvider(lineId));
    return -2;
  } catch (_) {
    ref.invalidate(movementLineForEditQuantityToMoveProvider(lineId));
    return -3;
  }
});

final movementNotCompletedToFindByDateProvider  = StateProvider.autoDispose<IdempiereMovement?>((ref) {
  return null;
});



final findMovementNotCompletedByDateProvider = FutureProvider.autoDispose<List<IdempiereMovement>?>((ref) async {
  final IdempiereMovement? movement = ref.watch(movementNotCompletedToFindByDateProvider);
  print('----------------------------------findMovementNotCompletedByDateProvider');
  if(movement== null || movement.movementDate == null) return null;
  bool? isIn ;

  String docStatus = movement.docStatus?.id ?? 'DR' ;



  /*if(movement.mWarehouseID !=null && movement.mWarehouseToID != null){
    isIn = null;
    warehouse = movement.mWarehouseID!.id!;
  } else {
    if(movement.mWarehouseID ==null){
      isIn = false;

      fileWarehouse ='M_WarehouseTo_ID';
    } else {
      isIn = true;

      fileWarehouse ='M_Warehouse_ID';
    }
  }*/

  String date = movement.movementDate!;

  String idempiereModelName ='m_movement';
  Dio dio = await DioClient.create();
  try {
    String url =  "/api/v1/models/$idempiereModelName";
    int warehouse = Memory.sqlUsersData.mWarehouseID?.id ?? -1;
    if(movement.mWarehouseID ==null && movement.mWarehouseToID == null){
      url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' AND (M_WarehouseTo_ID eq $warehouse OR M_Warehouse_ID eq $warehouse)&\$orderby=MovementDate desc";
    } else if(movement.mWarehouseID !=null && movement.mWarehouseToID != null){
      int warehouse = movement.mWarehouseID!.id!;
      int warehouseTo = movement.mWarehouseToID!.id!;
      url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' AND M_WarehouseTo_ID eq $warehouseTo AND M_Warehouse_ID eq $warehouse&\$orderby=MovementDate desc";
    } else if(movement.mWarehouseID ==null){
      //int warehouseTo = movement.mWarehouseToID!.id!;
      //url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' AND M_WarehouseTo_ID eq $warehouseTo&\$orderby=MovementDate desc";
      int warehouse = movement.mWarehouseToID!.id!;
      int warehouseTo = movement.mWarehouseToID!.id!;
      url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' AND M_WarehouseTo_ID eq $warehouseTo AND M_Warehouse_ID neq $warehouse&\$orderby=MovementDate desc";
    } else {
      //int warehouse = movement.mWarehouseID!.id!;
      //url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' AND M_Warehouse_ID eq $warehouse&\$orderby=MovementDate desc";
      int warehouse = movement.mWarehouseID!.id!;
      int warehouseTo = movement.mWarehouseID!.id!;
      url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' AND M_WarehouseTo_ID neq $warehouseTo AND M_Warehouse_ID eq $warehouse&\$orderby=MovementDate desc";
    }
    print(url);
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereMovement>.fromJson(response.data, IdempiereMovement.fromJson);
      late List<IdempiereMovement> m;
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        m = responseApi.records!;
      } else {
        m = [IdempiereMovement(name: Messages.NO_DATA_FOUND, id: Memory.NOT_FOUND_ID)];
      }
      return m;


    } else {
      return [IdempiereMovement(name: Messages.ERROR, id: response.statusCode)];
    }

  } on DioException {
    return [IdempiereMovement(name: '${Messages.ERROR} DioException', id: Memory.ERROR_ID)];

  } catch (e) {
    return [IdempiereMovement(name: Messages.ERROR +e.toString(), id: Memory.ERROR_ID)];
  }

});

