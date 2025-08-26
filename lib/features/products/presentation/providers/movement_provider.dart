


import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/locator_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_movement.dart';
import '../../domain/idempiere/idempiere_movement_line.dart';
import '../../domain/sql/common_sql_data.dart';
import '../../domain/sql/sql_data_movement_line.dart';
import '../screens/store_on_hand/memory_products.dart';


final isMovementCreateScreenShowedProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final scannedMovementIdForSearchProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
final stringForSearchProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final resultOfSqlQueryMovementProvider = StateProvider.autoDispose<IdempiereMovement>((ref) {
  return IdempiereMovement(id:Memory.INITIAL_STATE_ID);
});

final resultOfSqlQueryMovementLineProvider = StateProvider.autoDispose<List<IdempiereMovementLine>?>((ref) {
  return null;
});

final resultOfCreateMovementLinesProvider = StateProvider.autoDispose<List<IdempiereMovementLine>?>((ref) {
  return null;
});

final movementSqlQueryTypeProvider = StateProvider.autoDispose<int>((ref) {
  return ProductsScanNotifier.SQL_QUERY_SELECT;
});

final movementIdForMovementLineSearchProvider = StateProvider.autoDispose<int?>((ref) {
  return null;
});

final resultOfSearchMovementsProvider = StateProvider.autoDispose<List<IdempiereMovement>?>((ref) {
  return null;
});

final canCreateMovementProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});


final movementLineScrollAtEndProvider = Provider.autoDispose<bool>((ref) {
  return false;
});

final  startedCreateNewPutAwayMovementProvider = StateProvider.autoDispose<bool?>((ref) {
  return null;
});

final newSqlDataMovementProvider = StateProvider.autoDispose<SqlDataMovement>((ref) {
  return SqlDataMovement(id:Memory.INITIAL_STATE_ID,name: Messages.EMPTY);
});
final newSqlDataMovementLineProvider = StateProvider.autoDispose<SqlDataMovementLine>((ref) {
  return SqlDataMovementLine(id:Memory.INITIAL_STATE_ID,name: Messages.EMPTY);
});
final newSqlDataPutAwayMovementProvider = StateProvider.autoDispose<SqlDataMovement>((ref) {
  return SqlDataMovement(id:-1,name: Messages.EMPTY);
});

final allowedLocatorFromIdProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});
final allowedLocatorToMoveIdProvider = StateProvider.autoDispose<int?>((ref) {
  return null;
});



final createNewMovementProvider = FutureProvider.autoDispose<IdempiereMovement?>((ref) async {
  print('----------------------------------start createMovementLine');
  SqlDataMovement newMovement = ref.watch(newSqlDataMovementProvider);
  if(newMovement.id!=null && newMovement.id!>0) return null;
  if(newMovement.mWarehouseID==null || newMovement.mWarehouseID!.id==null || newMovement.mWarehouseID!.id!<=0){
    return null;
  }
  if(newMovement.mWarehouseToID==null || newMovement.mWarehouseToID!.id==null || newMovement.mWarehouseToID!.id!<=0){
    return null;
  }

  print('---------------------------------create new  movement line');

  Dio dio = await DioClient.create();
  try {
    String url = newMovement.getInsertUrl();
    final response = await dio.post(url, data: newMovement.getInsertJson());
    ref.read(movementIdForMovementLineSearchProvider.notifier).state = null;
    if (response.statusCode == 201) {

      SqlDataMovement movement =  SqlDataMovement.fromJson(response.data);
      if (movement.id != null && movement.id! > 0) {
        MemoryProducts.lastMovement = movement;
        ref.read(resultOfSqlQueryMovementProvider.notifier).state = movement;
        ref.read(allowedLocatorFromIdProvider.notifier).state = movement.locatorFromId ?? 0 ;
        return movement;
      } else {
        return ref.read(resultOfSqlQueryMovementProvider.notifier).state = IdempiereMovement(id:Memory.ERROR_ID,name: Messages.ERROR);
      }
    } else {
      throw Exception(
          'Error al obtener la lista de $url: ${response.statusCode}');
    }

  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }

});

final createNewMovementLineProvider = FutureProvider.autoDispose<bool?>((ref) async {
  print('----------------------------------start createMovementLine');
  SqlDataMovementLine newMovementLine = ref.watch(newSqlDataMovementLineProvider);
  print('----------------------------------start createMovementLine');
  if(newMovementLine.id!=null && newMovementLine.id!>0) return null;
  print('----------------------------------start createMovementLine');
  if(newMovementLine.mMovementID==null || newMovementLine.mMovementID!.id!<=0) return null;
  print('----------------------------------start createMovementLine');
  if(newMovementLine.mLocatorID ==null || newMovementLine.mLocatorID!.id==null || newMovementLine.mLocatorID!.id!<=0){
    return null;
  }
  print('----------------------------------start createMovementLine');
  if(newMovementLine.mLocatorToID==null || newMovementLine.mLocatorToID!.id==null || newMovementLine.mLocatorToID!.id!<=0){
    return null;
  }

  print('---------------------------------create new  movementLine');

  Dio dio = await DioClient.create();
  try {
    String url = newMovementLine.getInsertUrl();
    final response = await dio.post(url, data: newMovementLine.getInsertJson());
    if (response.statusCode == 201) {

      SqlDataMovementLine movementLine =  SqlDataMovementLine.fromJson(response.data);
      if (movementLine.id != null && movementLine.id! > 0) {
        MemoryProducts.lastMovementLine = movementLine;
        MemoryProducts.createdSqlDataMovementLines.add(movementLine);

        print(movementLine.toJson());
        var results = ref.read(resultOfSqlQueryMovementLineProvider.notifier).state;
        if(results==null){
          results = [movementLine];
          ref.read(allowedLocatorFromIdProvider.notifier).state = movementLine.mLocatorID?.id ?? 0 ;
        } else if(results.isEmpty){
          results.add(movementLine);
          ref.read(allowedLocatorFromIdProvider.notifier).state = movementLine.mLocatorID?.id ?? 0 ;
        }else {
          results.add(movementLine);
        }
        return true;

      } else {

        return false;
      }
    } else {
      throw Exception(
          'Error al obtener la lista de $url: ${response.statusCode}');
    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }

});
final scannedConfirmMovementProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final confirmMovementProvider = FutureProvider.autoDispose<bool?>((ref) async {

  int id = ref.watch(scannedConfirmMovementProvider);
  if(id <=0) return null;
  print('--------------------------------------0');
  print('--------------------------------------1');
  Dio dio = await DioClient.create();
  try {
    SqlDataMovement movement = SqlDataMovement(id:id);

    String url =movement.getUpdateUrl();
    final response = await dio.put(url, data: movement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));
    print('----------------------------------response${response.data}');
    if (response.statusCode == 200) {
      movement =  SqlDataMovement.fromJson(response.data);
      ref.read(resultOfSqlQueryMovementProvider.notifier).state = movement;
      print('----------confirm---${ref.read(resultOfSqlQueryMovementProvider.notifier).state.toJson()}');
      return true;
    } else {
      throw Exception(
          'Error al obtener la lista de $url: ${response.statusCode}');
    }



  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }
  return null;

});

final newPutAwayMovementProvider = FutureProvider.autoDispose<bool?>((ref) async {

  SqlDataMovement newMovement = ref.watch(newSqlDataPutAwayMovementProvider);
  if(newMovement.id!=null) return null;

  //ref.watch(sqlDataMovementResultProvider.notifier).update((state) => SqlDataMovement(id:-1,name: Messages.EMPTY));
  print('--------------------------------------0');
  //ref.watch(sqlDataMovementLinesResultProvider.notifier).update((state) => []);
  print('--------------------------------------1');
  Dio dio = await DioClient.create();
  try {
    String url = newMovement.getInsertUrl();
    final response = await dio.post(url, data: newMovement.getInsertJson());
    if (response.statusCode == 201) {

      SqlDataMovement movement =  SqlDataMovement.fromJson(response.data);
      if (movement.id != null && movement.id! > 0) {
        print('--------------------start create line id${movement.id}');
        MemoryProducts.newSqlDataMovementLineToCreate.mMovementID = movement;
        print(MemoryProducts.newSqlDataMovementLineToCreate.toJson());
        int aux =MemoryProducts.createdSqlDataMovementLines.length;
        MemoryProducts.newSqlDataMovementLineToCreate.line = (aux+1)*10;

        var creteDataJsonEncode2 = MemoryProducts.newSqlDataMovementLineToCreate.getInsertJson();
        url = MemoryProducts.newSqlDataMovementLineToCreate.getInsertUrl();
        final responseLine = await dio.post(url, data: creteDataJsonEncode2);
        print('-------------------${responseLine.data}');
        if (responseLine.statusCode == 201) {
          final SqlDataMovementLine movementLine =  SqlDataMovementLine.fromJson(responseLine.data);
          ref.read(resultOfCreateMovementLinesProvider.notifier).state = [movementLine];
          MemoryProducts.createdSqlDataMovementLines.add(movementLine);
          return true;
        } else {
          return false;
        }


        for(int i=0; i< MemoryProducts.newSqlDataMovementLinesToCreate.length ; i++){
          MemoryProducts.newSqlDataMovementLinesToCreate[i].mMovementID = movement;
          MemoryProducts.newSqlDataMovementLinesToCreate[i].line = (i+1)*10;
          var creteDataJsonEncode2 = MemoryProducts.newSqlDataMovementLinesToCreate[i].getInsertJson();
          url = MemoryProducts.newSqlDataMovementLinesToCreate[i].getInsertUrl();
          print('-----------$i---------start create line');
          final responseLine = await dio.post(url, data: creteDataJsonEncode2);
          if (responseLine.statusCode == 201) {
            final SqlDataMovementLine movementLine =  SqlDataMovementLine.fromJson(responseLine.data);
            MemoryProducts.newSqlDataMovementLinesToCreate[i] = movementLine;
            print('-----------$i----------${MemoryProducts.newSqlDataMovementLinesToCreate[i].toJson()}');
            ref.read(resultOfCreateMovementLinesProvider.notifier).state = [movementLine];
            MemoryProducts.createdSqlDataMovementLines.add(movementLine);
            return true;
          } else {
            return false;
          }


        }

        /*url =movement.getUpdateUrl();
        final responseLine = await dio.put(url, data: movement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));

        if (responseLine.statusCode == 200) {
          movement =  SqlDataMovement.fromJson(responseLine.data);
          MemoryProducts.newSqlDataMovement = movement;
          print(MemoryProducts.newSqlDataMovement.toJson());
          ref.read(sqlDataMovementResultProvider.notifier).state = movement;
          print('----------state---${ref.read(sqlDataMovementResultProvider.notifier).state.toJson()}');
          print('--------------------------state-------${ref.read(sqlDataMovementLinesResultProvider.notifier).state.length}');
          print('--------------------------------------${MemoryProducts.newSqlDataMovementLines.length}');
          return true;
        } else {
          return false;
        }*/

      } else {

        return false;
      }
    } else {
      throw Exception(
          'Error al obtener la lista de $url: ${response.statusCode}');
    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }
  return null;

});

final findMovementByIdProvider = FutureProvider.autoDispose<IdempiereMovement>((ref) async {
  print('---------------------------------find movement');
  final String scannedCode = ref.watch(scannedMovementIdForSearchProvider).toUpperCase();
  print('---------------------------------scannedCode  $scannedCode');
  if(scannedCode=='') return IdempiereMovement(id:Memory.INITIAL_STATE_ID);
  int? aux = int.tryParse(scannedCode);
  if(aux==null){
    return IdempiereMovement(id:Memory.ERROR_ID,name: Messages.ERROR_ID);
  }
  String searchField ='M_Movement_ID';
  String idempiereModelName ='m_movement';
  Dio dio = await DioClient.create();
  try {
    //String url =  "/api/v1/models/$idempiereModelName?\$filter=$searchField eq $aux";
    String url =  "/api/v1/models/$idempiereModelName/$aux";
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);
    print('---------------------------------response ${response.data} ${response.statusCode}');
    if (response.statusCode == 200) {

      final responseApi =
      ResponseApi<IdempiereMovement>.fromJson(response.data, IdempiereMovement.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        if(productsList.length==1){
          ref.read(resultOfSqlQueryMovementProvider.notifier).state = productsList[0];
          ref.read(movementIdForMovementLineSearchProvider.notifier).state = productsList[0].id;

        } else {
          ref.read(movementIdForMovementLineSearchProvider.notifier).state = null;
          ref.watch(resultOfSqlQueryMovementProvider.notifier).state =
              IdempiereMovement(id:Memory.TOO_MUCH_RECORDS_ID,name: Messages.TOO_MUCH_RECORDS
              ,identifier: scannedCode);
        }


        return productsList[0];

      } else {
        ref.read(resultOfSqlQueryMovementProvider.notifier).state = IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode);
        ref.read(movementIdForMovementLineSearchProvider.notifier).state = null;
        return IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode);
      }
    } else {
      return IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode);
      /*throw Exception(
          'Error al obtener la lista de $scannedCode: ${response.statusCode}');*/
    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    print('---------------------------------catch');return IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode);
    throw Exception(e.toString());
  }

});

final findMovementLinesByMovementIdProvider = FutureProvider.autoDispose<List<IdempiereMovementLine>?>((ref) async {
  print('---------------------------------find movement line');
  final int? id = ref.watch(movementIdForMovementLineSearchProvider);
  if(id==null || id==Memory.INITIAL_STATE_ID) return null;
  if(id<=0) return [];
  String searchField ='M_Movement_ID';
  String idempiereModelName ='m_movementline';

  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=$searchField eq $id";
    url = url.replaceAll(' ', '%20');

    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereMovementLine>.fromJson(response.data, IdempiereMovementLine.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final dataList = responseApi.records!;
        if(dataList.isEmpty){
          return [];
        } else {
          IdempiereLocator? locatorFrom = dataList[0].mLocatorID;
          IdempiereLocator? locatorTo = dataList[0].mLocatorToID;
          if(locatorFrom!=null){
            locatorFrom.value = locatorFrom.identifier;
          }
          if(locatorTo!=null){
            locatorTo.value = locatorTo.identifier;
          }
          ref.read(allowedLocatorFromIdProvider.notifier).state = locatorFrom?.id ?? 0 ;
          ref.read(allowedLocatorToMoveIdProvider.notifier).state = locatorTo?.id ?? 0 ;
          ref.read(selectedLocatorToProvider.notifier).state = locatorTo ?? IdempiereLocator();
          print(ref.read(selectedLocatorToProvider.notifier).state.toJson());
          ref.read(selectedLocatorFromProvider.notifier).state = locatorFrom ?? IdempiereLocator();
          print(ref.read(selectedLocatorFromProvider.notifier).state.toJson());


          ref.read(resultOfSqlQueryMovementLineProvider.notifier).state =
              dataList;
          return dataList;
        }




      } else {
        return [];
      }
    } else {
      throw Exception(
          'Error al obtener la lista de $id: ${response.statusCode}');
    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }

});

