import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/persitent_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_locator.dart';
import '../../domain/idempiere/idempiere_warehouse.dart';


final scannedBarcodeForLineProvider = StateProvider<String?>((ref) => null);

final isScanningLocatorToForLineProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final isLocatorScreenShowedForLineProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final scannedLocatorToForLineProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final scannedLocatorFromForLineProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final scannedLocatorsListForLineProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});


final userWarehouseIdForSearchLocatorForLineProvider = StateProvider.autoDispose<int>((ref) {
  return Memory.sqlUsersData.mWarehouseID?.id ?? 0;
});

final filterWarehouseValueForSearchLocatorForLineProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
});

final resultOfSqlQueryLocatorForLineProvider = StateProvider.autoDispose<List<IdempiereLocator>>((ref){
  return [];
});


final selectedLocatorToForLineProvider = StateProvider.autoDispose<IdempiereLocator>((ref) {
  final value = ref.watch(persistentLocatorToProvider);
  return value;
});
final selectedLocatorToForLineProvider2 = StateProvider.autoDispose<IdempiereLocator>((ref) {
  final value = ref.watch(persistentLocatorToProvider);
  return value;
});




/*final findLocatorForLineProvider = FutureProvider.autoDispose.family<IdempiereLocator, String>((ref, scannedCode) async {
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
});*/



final findLocatorToForLineProvider = FutureProvider<IdempiereLocator>((ref) async {
  final String scannedCode = ref.watch(scannedLocatorToForLineProvider).toUpperCase().trim();
  if(scannedCode=='') {
    ref.read(isScanningForLineProvider.notifier).state =false;
    ref.read(isScanningLocatorToForLineProvider.notifier).state =false;
    return IdempiereLocator(id:Memory.INITIAL_STATE_ID,value: Messages.FIND);
  }

  String searchField ='Value';
  String idempiereModelName ='m_locator';
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereLocator>.fromJson(response.data, IdempiereLocator.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        ref.read(persistentLocatorToProvider.notifier).state = productsList[0];
        ref.read(isScanningForLineProvider.notifier).state =false;

        ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
        return productsList[0];
      } else {
        ref.read(isScanningProvider.notifier).state =false;
        ref.read(persistentLocatorToProvider.notifier).state = IdempiereLocator(id:Memory.NOT_FOUND_ID,value: '${Messages.NOT_FOUND} $scannedCode'  );
        ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
        return IdempiereLocator(value: Messages.NOT_FOUND, name: scannedCode,id: Memory.NOT_FOUND_ID);

      }
    } else {
      ref.read(isScanningProvider.notifier).state =false;
      ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
      ref.read(persistentLocatorToProvider.notifier).state =
          IdempiereLocator(id:Memory.ERROR_ID,
          value: '${Messages.ERROR} $scannedCode');
      return IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);

    }
  } on DioException {
    final authDataNotifier = ref.read(authProvider.notifier);
    ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
    ref.read(isScanningProvider.notifier).state =false;
    ref.read(persistentLocatorToProvider.notifier).state =
        IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);
    return IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);
    //throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    //throw Exception(e.toString());
    ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
    ref.read(isScanningProvider.notifier).state =false;
    ref.read(persistentLocatorToProvider.notifier).state =IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);
    return IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);
  }

});


final findLocatorToForBarcodeScreenForLineProvider = FutureProvider<IdempiereLocator>((ref) async {
  final String scannedCode = ref.watch(scannedBarcodeForLineProvider) ?? '';
  if(scannedCode=='') {
    ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
    return IdempiereLocator(id:Memory.INITIAL_STATE_ID,value: Messages.FIND);
  }

  String searchField ='Value';
  String idempiereModelName ='m_locator';
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereLocator>.fromJson(response.data, IdempiereLocator.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        ref.read(persistentLocatorToProvider.notifier).state = productsList[0];
        ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
        return productsList[0];
      } else {
        ref.read(persistentLocatorToProvider.notifier).state = IdempiereLocator(value: '${Messages.NOT_FOUND} $scannedCode',
            name: scannedCode,id: Memory.NOT_FOUND_ID);
        ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
        return IdempiereLocator(value: '${Messages.NOT_FOUND} $scannedCode',
            name: scannedCode,id: Memory.NOT_FOUND_ID);

      }
    } else {
      ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
      ref.read(persistentLocatorToProvider.notifier).state = IdempiereLocator(
          id:Memory.ERROR_ID,value: '${Messages.ERROR} $scannedCode');
      return  IdempiereLocator(
          id:Memory.ERROR_ID,value: '${Messages.ERROR} $scannedCode');

    }
  } on DioException {
    final authDataNotifier = ref.read(authProvider.notifier);
    ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
    ref.read(persistentLocatorToProvider.notifier).state = IdempiereLocator(id:Memory.ERROR_ID,
        value: '${Messages.ERROR} : $scannedCode');
    return IdempiereLocator(id:Memory.ERROR_ID,
        value: '${Messages.ERROR} : $scannedCode');
    //throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    //throw Exception(e.toString());
    ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
    return IdempiereLocator(id:Memory.ERROR_ID,value: '${Memory.NOT_FOUND_ID}: $scannedCode');
  }

});

final findLocatorFromForLineProvider = FutureProvider.autoDispose<IdempiereLocator>((ref) async {

  final String scannedCode = ref.watch(scannedLocatorFromForLineProvider).toUpperCase();
  if(scannedCode=='') return IdempiereLocator(id:Memory.INITIAL_STATE_ID,value: Messages.FIND);

  String searchField ='Value';
  String idempiereModelName ='m_locator';

  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereLocator>.fromJson(response.data, IdempiereLocator.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        if(productsList.length==1){
          if(ref.watch(persistentLocatorToProvider.notifier).state.id != null &&
          ref.watch(persistentLocatorToProvider.notifier).state.id!>0
              && ref.watch(persistentLocatorToProvider.notifier).state.id!=productsList[0].id){
          }


        }
        return productsList[0];

      } else {
        return IdempiereLocator(value: Messages.NOT_FOUND, name: scannedCode,id: Memory.NOT_FOUND_ID);
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
final findLocatorsListForLineProvider = FutureProvider.autoDispose<List<IdempiereLocator>>((ref) async {
  final String scannedCode = ref.watch(scannedLocatorsListForLineProvider).toUpperCase();
  if(scannedCode=='') return [];

  String searchField ='Value';
  String idempiereModelName ='m_locator';

  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=contains($searchField,'$scannedCode')";
    url = url.replaceAll(' ', '%20');
    final response = await dio.get(url);
    ref.read(isDialogShowedProvider.notifier).update((state) => false);


    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereLocator>.fromJson(response.data, IdempiereLocator.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final dataList = responseApi.records!;
        // Sort the list by the 'value' property
        dataList.sort((a, b) => (a.value ?? '').compareTo(b.value ?? ''));

        ref.watch(resultOfSqlQueryLocatorForLineProvider.notifier).state = dataList;
        if(dataList.isNotEmpty){
          return dataList;
        } else {
          return [IdempiereLocator(id:Memory.NOT_FOUND_ID,value: Messages.NOT_FOUND)];
        }

      } else {
        ref.watch(resultOfSqlQueryLocatorForLineProvider.notifier).state = [IdempiereLocator(id:Memory.NOT_FOUND_ID,value: Messages.NOT_FOUND  )];
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

final findDefaultLocatorOfWarehouseByWarehouseNameForLineProvider = FutureProvider.autoDispose<List<IdempiereLocator>>((ref) async {
  final String? scannedCode = ref.watch(filterWarehouseValueForSearchLocatorForLineProvider)?.toUpperCase();
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