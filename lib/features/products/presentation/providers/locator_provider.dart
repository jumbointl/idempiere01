import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_locator.dart';
import '../../domain/idempiere/idempiere_warehouse.dart';

final persistentLocatorToProvider = StateProvider<IdempiereLocator>((ref) {
  return IdempiereLocator(id:Memory.INITIAL_STATE_ID,value: Messages.FIND);
});
final scannedBarcodeProvider = StateProvider<String?>((ref) => null);

final isScanningLocatorToProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});




final scannedLocatorsListProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final allowedWarehouseToProvider = StateProvider<int>((ref) {
  return 0;
});
final excludedWarehouseToProvider = StateProvider<int>((ref) {
  return 0;
});

final actualLocatorFromProvider = StateProvider<int>((ref) {
  return 0;
});

final userWarehouseIdForSearchLocatorProvider = StateProvider.autoDispose<int>((ref) {
  return Memory.sqlUsersData.mWarehouseID?.id ?? 0;
});

final filterWarehouseValueForSearchLocatorProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
});

final resultOfSqlQueryLocatorProvider = StateProvider.autoDispose<List<IdempiereLocator>>((ref){
  return [];
});


final selectedLocatorToProvider = StateProvider<IdempiereLocator>((ref) {
  return IdempiereLocator(id: Memory.INITIAL_STATE_ID,value: Messages.FIND);
});
final selectedLocatorToProvider2 = StateProvider.autoDispose<IdempiereLocator>((ref) {
  final value = ref.watch(persistentLocatorToProvider);
  return value;
});

final selectedLocatorFromProvider = StateProvider.autoDispose<IdempiereLocator>((ref) {
  return IdempiereLocator(id: Memory.INITIAL_STATE_ID,value: Messages.FIND);
});
final selectedLocatorFromProvider2 = StateProvider.autoDispose<IdempiereLocator>((ref) {
  return IdempiereLocator(id: Memory.INITIAL_STATE_ID,value: Messages.FIND);

});
final selectedLocatorToProvider3 = StateProvider.autoDispose<IdempiereLocator>((ref) {
  return IdempiereLocator(id: Memory.INITIAL_STATE_ID,value: Messages.FIND);

});


final findLocatorProvider = FutureProvider.autoDispose.family<IdempiereLocator, String>((ref, scannedCode) async {
  final upperCaseScannedCode = scannedCode.toUpperCase().trim();
  if (upperCaseScannedCode == '') {
    return IdempiereLocator(id: Memory.INITIAL_STATE_ID, value: Messages.FIND);
  }

  String searchField = 'Value';
  String idempiereModelName = 'm_locator';
  Dio dio = await DioClient.create();
  try {
    String url = "/api/v1/models/$idempiereModelName?\$filter=$searchField eq '$upperCaseScannedCode'";
    url = url.replaceAll(' ', '%20');
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      final responseApi = ResponseApi<IdempiereLocator>.fromJson(response.data, IdempiereLocator.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        return responseApi.records![0];
      } else {
        return IdempiereLocator(value: Messages.NOT_FOUND, name: upperCaseScannedCode, id: Memory.NOT_FOUND_ID);
      }
    } else {
      return IdempiereLocator(id: Memory.ERROR_ID, value: '${Messages.ERROR} ${response.statusCode}');
    }
  } catch (e) {
    // Consider logging the error or rethrowing a more specific error
    return IdempiereLocator(id: Memory.ERROR_ID, value: Messages.ERROR);
  }
});





final findLocatorsListProvider = FutureProvider.autoDispose<List<IdempiereLocator>>((ref) async {
  final String scannedCode = ref.watch(scannedLocatorsListProvider).toUpperCase();
  if(scannedCode=='') return [];

  String searchField ='Value';
  String idempiereModelName ='m_locator';
  debugPrint('findLocatorsListProvider $scannedCode');
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=contains($searchField,'$scannedCode')";
    url = url.replaceAll(' ', '%20');
    debugPrint(url);
    print(url);
    final response = await dio.get(url);
    ref.read(isDialogShowedProvider.notifier).update((state) => false);


    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereLocator>.fromJson(response.data, IdempiereLocator.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final dataList = responseApi.records!;
        // Sort the list by the 'value' property
        dataList.sort((a, b) => (a.value ?? '').compareTo(b.value ?? ''));

        ref.read(resultOfSqlQueryLocatorProvider.notifier).state = dataList;
        if(dataList.isNotEmpty){
          return dataList;
        } else {
          return [IdempiereLocator(id:Memory.NOT_FOUND_ID,value: Messages.NOT_FOUND)];
        }

      } else {
        ref.read(resultOfSqlQueryLocatorProvider.notifier).state = [IdempiereLocator(id:Memory.NOT_FOUND_ID,value: Messages.NOT_FOUND  )];
        return [IdempiereLocator(value: Messages.NOT_FOUND, name: scannedCode,id: Memory.NOT_FOUND_ID)];
      }
    } else {
      throw Exception(
          'Error al obtener la lista de $scannedCode: ${response.statusCode}');
    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }



});

final findDefaultLocatorOfWarehouseByWarehouseNameProvider = FutureProvider.autoDispose<List<IdempiereLocator>>((ref) async {
  final String? scannedCode = ref.watch(filterWarehouseValueForSearchLocatorProvider)?.toUpperCase();
  if(scannedCode==null) return [];

  String idempiereModelName ='m_warehouse';
  String url = "/api/v1/models/$idempiereModelName";

  if(scannedCode!=Memory.COMMAND_TO_GET_ALL_WAREHOUSES){
    String searchField ='Value';
    url = "/api/v1/models/$idempiereModelName?\$filter=contains($searchField,'$scannedCode')";
  }
  url = url.replaceAll(' ', '%20');
  if(url.contains('?')){
    url='$url&showsql';
  } else {
    url='$url?showsql';
  }

  Dio dio = await DioClient.create();
  try {


    final response = await dio.get(url);
    ref.read(isDialogShowedProvider.notifier).update((state) => false);
    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereWarehouse>.fromJson(response.data, IdempiereWarehouse.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final warehouseList = responseApi.records!;
        final List<IdempiereLocator> locatorList = [];
        // came from warehouse list

        for (var warehouse in warehouseList) {
          IdempiereLocator? locator= warehouse.mReserveLocatorID ;
          if(locator!=null){
            locator.mWarehouseID = warehouse;
            locator.mWarehouseID?.identifier = warehouse.name ;
            locator.value = locator.identifier;
            locatorList.add(locator);
          }

        }


        locatorList.sort((a, b) => a.value!.compareTo(b.value!));
        return locatorList;

      } else {
        return [IdempiereLocator(value: Messages.NOT_FOUND, name: scannedCode,id: Memory.NOT_FOUND_ID)];
      }
    } else {
      throw Exception(
          'Error al obtener la lista de $scannedCode: ${response.statusCode}');
    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }

});