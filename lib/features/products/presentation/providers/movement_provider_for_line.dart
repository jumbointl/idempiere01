

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/persitent_provider.dart';

import '../../../../config/http/dio_client.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../domain/idempiere/idempiere_locator.dart';
import '../../domain/idempiere/idempiere_movement.dart';
import '../../domain/idempiere/idempiere_movement_line.dart';
import '../../domain/sql/sql_data_movement_line.dart';
import '../screens/store_on_hand/memory_products.dart';
import 'movement_provider_old.dart';




final scannedMovementIdForSearchProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
final findMovementByIdOrDocumentNOProvider = FutureProvider.autoDispose<IdempiereMovement>((ref) async {
  final String scannedCode = ref.watch(scannedMovementIdForSearchProvider).toUpperCase();
  print('----------------------------------start searchMovementByIdOrDocumentNo $scannedCode');
  if(scannedCode=='') {
    return IdempiereMovement(id:Memory.INITIAL_STATE_ID);}
  MemoryProducts.movementAndLines.clearData();

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
      }
      //IdempiereDocumentStatus documentStatus = m.docStatus ?? IdempiereDocumentStatus();
      //ref.read(movementDocumentStatusProvider.notifier).state = documentStatus.id ??'';
      if(m.id!=null){
        //ref.read(persistentMovementProvider.notifier).state = m;
        MemoryProducts.movementAndLines.cloneMovement(m);
        ref.read(movementIdForMovementLineSearchProvider.notifier).state =m.id;
        await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, MemoryProducts.movementAndLines.toJson());
        return m;

      } else {
        //ref.read(persistentMovementProvider.notifier).state = IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode);
        //ref.read(movementIdForMovementLineSearchProvider.notifier).state = null;
        MemoryProducts.movementAndLines.clearData();
        return IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode);
      }



    } else {
      MemoryProducts.movementAndLines.clearData();
      ref.read(movementIdForMovementLineSearchProvider.notifier).state = null;
      return IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode);
      /*throw Exception(
          'Error al obtener la lista de $scannedCode: ${response.statusCode}');*/
    }
  } on DioException {
    ref.read(movementIdForMovementLineSearchProvider.notifier).state = null;
    MemoryProducts.movementAndLines.clearData();
    //final authDataNotifier = ref.read(authProvider.notifier);
    //throw CustomErrorDioException(e, authDataNotifier);
    return IdempiereMovement(name: Messages.ERROR, id: Memory.ERROR_ID, identifier: scannedCode);

  } catch (e) {
    MemoryProducts.movementAndLines.clearData();
    ref.read(movementIdForMovementLineSearchProvider.notifier).state = null;
    return IdempiereMovement(name: Messages.ERROR, id: Memory.ERROR_ID, identifier: scannedCode);
    throw Exception(e.toString());
  }

});

final findMovementLinesByMovementIdProvider = FutureProvider.autoDispose<List<IdempiereMovementLine>?>((ref) async {
  final int? id = ref.watch(movementIdForMovementLineSearchProvider);
  print('----------------------------------start findMovementLinesByMovementIdProvider $id');
  if(id==null || id==Memory.INITIAL_STATE_ID) return null;
  if(id<=0) return [];
  String searchField ='M_Movement_ID';
  String idempiereModelName ='m_movementline';
  MemoryProducts.movementAndLines.clearData();
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=$searchField eq $id";
    url = url.replaceAll(' ', '%20');
    print(url);
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
            if(locatorTo.value==null || locatorTo.value!.isEmpty){
              locatorTo.value = locatorTo.identifier;
            }
            ref.read(persistentLocatorToProvider.notifier).state = locatorTo;
          }
          MemoryProducts.movementAndLines.movementLines = dataList;
          return dataList;
        }

      } else {
        return [];
      }
    } else {
      return [];
      /*throw Exception(
          'Error al obtener la lista de $id: ${response.statusCode}');*/
    }
  } on DioException {
    return [];
    /*final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);*/
  } catch (e) {
    //throw Exception(e.toString());
    return [];
  }

});

final createNewMovementLineProvider = FutureProvider.autoDispose<IdempiereMovementLine?>((ref) async {
  print('newSqlDataMovementLineProvider 0');
  SqlDataMovementLine newMovementLine = ref.watch(newSqlDataMovementLineProvider);

  if(newMovementLine.id!=null && newMovementLine.id!>0){
    print('Error id :${newMovementLine.id} ');
    return null;
  }
  print('newSqlDataMovementLineProvider 1');
  if(newMovementLine.mMovementID==null || newMovementLine.mMovementID!.id!<=0) {
    print('Error movement id :${newMovementLine.mMovementID?.id ??'id null'} ');
    return null;}
  print('newSqlDataMovementLineProvider 2');
  if(newMovementLine.mLocatorID ==null || newMovementLine.mLocatorID!.id==null || newMovementLine.mLocatorID!.id!<=0){
    print('Error mLocatorID id :${newMovementLine.mLocatorID?.id ??'locator id null'} ');
    return null;
  }
  print('newSqlDataMovementLineProvider 3');
  if(newMovementLine.mLocatorToID==null || newMovementLine.mLocatorToID!.id==null || newMovementLine.mLocatorToID!.id!<=0){
    print('Error mLocatorToID id :${newMovementLine.mLocatorToID?.id ?? 'locator to id null'} ');
    return null;
  }
  print('newSqlDataMovementLineProvider 4');



  Dio dio = await DioClient.create();
  try {
    String url = newMovementLine.getInsertUrl();
    print('newSqlDataMovementLineProvider 2');
    final response = await dio.post(url, data: newMovementLine.getInsertJson());
    print(url);
    print(newMovementLine.getInsertJson());
    if (response.statusCode == 201) {

      IdempiereMovementLine result =  IdempiereMovementLine.fromJson(response.data);
      if (result.id != null && result.id! > 0) {
        newMovementLine.id = result.id;
        //MemoryProducts.movementAndLinesLine = result;
        //MemoryProducts.movementAndLines.movementLines?.add(result);
        newMovementLine.id = result.id;
        //ref.read(persistentMovementLinesProvider.notifier).state = MemoryProducts.movementAndLines.movementLines?;
        print('-----lines length  :${MemoryProducts.movementAndLines.movementLines?.length ?? 0}');
        return result;

      } else {
        print(response.statusCode);
        //ref.invalidate(newSqlDataMovementLineProvider);
        return null;
      }
    } else {
      //ref.invalidate(newSqlDataMovementLineProvider);
      print(response.statusCode);
      return null;
      /*throw Exception(
          'Error al obtener la lista de $url: ${response.statusCode}');*/
    }
  } on DioException {
    /* final authDataNotifier = ref.read(authProvider.notifier);
    ref.invalidate(newSqlDataMovementLineProvider);
    ref.read(isCreatingMovementLineProvider.notifier).state = false;*/
    print('DioException');
    return null;
    //throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    //throw Exception(e.toString());
    /*ref.invalidate(newSqlDataMovementLineProvider);
    ref.read(isCreatingMovementLineProvider.notifier).state = false;*/
    print('Exception : ${e.toString()}');
    return null;
  }

});