

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../../domain/idempiere/idempiere_storage_on_hande.dart';
import 'idempiere_products_notifier.dart';

final futureProvider = FutureProvider.autoDispose<IdempiereProduct>((ref) async {
  final scannedCode = ref.watch(scannedCodeProvider);
  if(scannedCode=='') return IdempiereProduct(id:0);
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/m_product?\$filter=upc eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');

    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereProduct>.fromJson(response.data, IdempiereProduct.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        ref.watch(productIdProvider.notifier).state = productsList[0].id!;
        return productsList[0];

      } else {
        return IdempiereProduct(name: 'no encontrado', uPC: scannedCode,id: 0);
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

final futureProductsStoredProvider = FutureProvider.autoDispose<List<IdempiereStorageOnHande>>((ref) async {

  final productId = ref.watch(productIdProvider);
  //final product = ref.watch(futureProvider).value;
  //int productId = product?.id ?? 0;
  if(productId== 0){
    return [];
  }
  Dio dio = await DioClient.create();
  try {
    String url = "/api/v1/models/M_StorageOnHand?\$filter=M_Product_Id eq $productId";
    String urlLocator = "/api/v1/models/m_locator?\$filter=m_locator_id eq ";
    urlLocator = urlLocator.replaceAll(' ','%20');
    //String url = "/api/v1/models/rv_storage_per_product?\$filter=M_Product_Id eq $productId";


    url = url.replaceAll(' ', '%20');
    print('----------------------------------------------url: $url');
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereStorageOnHande>.fromJson(response.data, IdempiereStorageOnHande.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        List locatorQueries =[];
        for (var product in productsList) {
          String id = product.mLocatorID?.id.toString() ?? '';
          if(id!=''){
            String id2 = id.replaceAll(' ', '%20');
            locatorQueries.add('$urlLocator$id2');
          } else {
            locatorQueries.add(id);
          }
        }

        for (int i = 0; i < locatorQueries.length; i++) {
          print('----------------------------------------------url: ${locatorQueries[i]}');

          if(locatorQueries[i]!='') {
            final responseLocator = await dio.get(locatorQueries[i]);
            if (responseLocator.statusCode == 200) {
              final responseLocatorApi =
              ResponseApi<IdempiereLocator>.fromJson(
                  response.data, IdempiereLocator.fromJson);
              final locatorsList = responseLocatorApi.records!;
              if (locatorsList.isNotEmpty) {
                IdempiereLocator locator = locatorsList[0];
                productsList[i].warehouse = locator.mWarehouseID;
                print(
                    '--------------locator: ${locator.identifier} warehouse ${locator
                        .mWarehouseID?.identifier}');
              }
            }
          }
        }




        return productsList;
      } else {
        return [];
      }
    } else {
      throw Exception(
          'Error al obtener la lista de $productId: ${response.statusCode}');
    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }

});


final scanStateNotifierProvider = StateNotifierProvider.autoDispose<IdempiereScanNotifier, List<IdempiereProduct>>((ref) {
  return IdempiereScanNotifier(ref);

});
final scannedCodeProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
final scannedCodeTimesProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final productIdProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});
