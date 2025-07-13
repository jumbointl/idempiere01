

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../../domain/idempiere/idempiere_storage_on_hande.dart';


final scannedCodeForStoredOnHandProvider = StateProvider.autoDispose<String?>((ref) {
  return '';
});

final findProductByUPCOrSKUForStoreOnHandProvider = FutureProvider.autoDispose<List<IdempiereProduct>>((ref) async {
  final String? scannedCode = ref.watch(scannedCodeForStoredOnHandProvider)?.toUpperCase();
  if(scannedCode==null || scannedCode=='') return [IdempiereProduct(id:0)];
  int? aux = int.tryParse(scannedCode);
  String searchField ='upc';
  if(aux==null){
    searchField = 'sku';
  }
  if(ref.watch(searchByMOLIConfigurableSKUProvider)){
    searchField = 'MOLI_ConfigurableSKU';
  }
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');

    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereProduct>.fromJson(response.data, IdempiereProduct.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        if(productsList.length==1){
          ref.watch(productIdProvider.notifier).state = productsList[0].id!;
        } else {
          ref.watch(productIdProvider.notifier).state = 0;
        }


        return productsList;

      } else {
        ref.watch(productIdProvider.notifier).state = 0;
        return [IdempiereProduct(name: Messages.NOT_FOUND, uPC: scannedCode,id: 0)];
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

final findProductsByMOLIConfigurableSKUProvider = FutureProvider.autoDispose<List<IdempiereProduct>>((ref) async {
  final scannedCode = ref.watch(scannedSKUCodeProvider);
  if(scannedCode==null || scannedCode=='') return [];

  String searchField ='MOLI_ConfigurableSKU';

  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereProduct>.fromJson(response.data, IdempiereProduct.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        return productsList;

      } else {
        return [IdempiereProduct(name: 'no encontrado', sKU: scannedCode,id: 0)];
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


final findProductsStoreOnHandProvider = FutureProvider.autoDispose<List<IdempiereStorageOnHande>>((ref) async {

  final productId = ref.watch(productIdProvider);
  //final product = ref.watch(futureProvider).value;
  //int productId = product?.id ?? 0;
  if(productId== 0){

    return [];
  }

  Dio dio = await DioClient.create();
  try {
    String url = "/api/v1/models/m_storageonhand?\$expand=M_Locator_ID&\$IsActive=true"
        "&\$filter=QtyOnHand%20neq%200%20AND%20M_Product_ID%20eq%20$productId";
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereStorageOnHande>.fromJson(response.data, IdempiereStorageOnHande.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsListRaw = responseApi.records!;
        ref.watch(unsortedStoreOnHandListProvider.notifier).state = productsListRaw;
        Map<String, IdempiereStorageOnHande> groupedProducts = {};
        int warehouseUser = ref.read(authProvider).selectedWarehouse?.id ?? 0;

        for (var data in productsListRaw) {

          if (productId == data.mProductID?.id) {
            String key = '${data.mLocatorID?.value}-${data.mAttributeSetInstanceID?.id}';
            if (groupedProducts.containsKey(key)) {
              // If the group already exists, sum the qtyOnHand
              groupedProducts[key]!.qtyOnHand = (groupedProducts[key]!.qtyOnHand ?? 0) + (data.qtyOnHand ?? 0);
            } else {
              // Otherwise, add the new group
              groupedProducts[key] = IdempiereStorageOnHande(
                mLocatorID: data.mLocatorID,
                mAttributeSetInstanceID: data.mAttributeSetInstanceID,
                qtyOnHand: data.qtyOnHand,
                mProductID: data.mProductID,
                // Copy other necessary fields
              );
            }
          }
        }

        List<IdempiereStorageOnHande> productsList = groupedProducts.values.toList();

        // Group products by warehouse
        Map<int, List<IdempiereStorageOnHande>> groupedByWarehouse = {};
        for (var product in productsList) {
          int warehouseID = product.mLocatorID?.mWarehouseID?.id ?? 0;

          groupedByWarehouse.putIfAbsent(warehouseID, () => []).add(product);
        }

        // Sort products within each group by qtyOnHand in descending order
        groupedByWarehouse.forEach((key, value) {
          value.sort((a, b) => b.qtyOnHand!.compareTo(a.qtyOnHand!));
        });

        // Put the user's warehouse first, then sort the rest by warehouse ID
        List<int> sortedWarehouseIDs = groupedByWarehouse.keys.toList()..sort();
        if (groupedByWarehouse.containsKey(warehouseUser)) {
          sortedWarehouseIDs.remove(warehouseUser);
          sortedWarehouseIDs.insert(0, warehouseUser);
        }

        // Flatten the grouped and sorted products into a single list
        List<IdempiereStorageOnHande> sortedProductsList = [];
        for (var warehouseID in sortedWarehouseIDs) {
          sortedProductsList.addAll(groupedByWarehouse[warehouseID]!.where((product) => product.qtyOnHand != 0));
        }
        return sortedProductsList;
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




final resultOfSameWarehouseProvider = StateProvider.autoDispose<List<String>>((ref) {
  return [];
});

final unsortedStoreOnHandListProvider = StateProvider.autoDispose<List<IdempiereStorageOnHande>>((ref) {
  return [];
});


final showResultCardProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final searchByMOLIConfigurableSKUProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});


final scannedLocatorToProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});


final scannerInputField = StateProvider.autoDispose<int>((ref) {
  return 1;
});

final scannedSKUCodeProvider = StateProvider.autoDispose<String?>((ref) {
  return '';
});


final usePhoneCameraToScanStoreOnHandeProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final quantityToMoveProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});


