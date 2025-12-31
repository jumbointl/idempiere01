

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_search_provider.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../domain/idempiere/product_with_stock.dart';
import '../../domain/idempiere/response_async_value.dart';

final scrollToUpProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final scannedCodeForStoredOnHandProvider = StateProvider.autoDispose<String?>((ref) {
  return '';
});


final findProductByUPCOrSKUForStoreOnHandProvider =
FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final String? scannedCode =
  ref.watch(scannedCodeForStoredOnHandProvider)?.toUpperCase();

  // English: Base response object (always returned, even on errors)
  final responseValue = ResponseAsyncValue(
    success: false,
    isInitiated: false,
    data: null,
  );

  // English: Reset progress for each new search
  ref.read(storeOnHandProgressProvider.notifier).state = 0.0;

  if (scannedCode == null || scannedCode.isEmpty || scannedCode=='-1') {
    return responseValue;
  }

  responseValue.isInitiated = true;

  int? aux = int.tryParse(scannedCode);
  String searchField = aux == null ? 'sku' : 'upc';

  Dio dio = await DioClient.create();
  ref.read(showResultCardProvider.notifier).state = true;

  // English: Helper to standardize message formatting
  String withValue(String msg) => '$msg\n${Messages.VALUE} : $scannedCode';

  try {
    // =========================
    // 1) Search product
    // =========================
    String url =
        "/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');

    final response = await dio.get(url);

    if (response.statusCode != 200) {
      responseValue.message = withValue(Messages.NO_DATA_FOUND);
      return responseValue;
    }

    final responseApi = ResponseApi<IdempiereProduct>.fromJson(
      response.data,
      IdempiereProduct.fromJson,
    );

    if (responseApi.records == null || responseApi.records!.isEmpty) {
      responseValue.message = withValue(Messages.NO_DATA_FOUND);
      return responseValue;
    }

    final IdempiereProduct product = responseApi.records!.first;

    final productWithStock = ProductWithStock(
      searched: true,
      showResultCard: true,
    );

    productWithStock.copyWithProduct(product);

    if (!productWithStock.hasProduct) {
      responseValue.message = withValue(Messages.NO_DATA_FOUND);
      return responseValue;
    }

    // =========================
    // 2) Search storage on hand (paginated)
    // =========================
    final String productId = product.id.toString();

    int totalRecords = 0;
    int totalPages = 0;
    int recordsSize = 100;
    int skipRecords = 0;

    bool firstPage = true;

    final List<IdempiereStorageOnHande> allStorage = [];

    while (true) {
      if (!ref.mounted) break;

      String urlStorage =
          "/api/v1/models/m_storageonhand?"
          "\$expand=M_Locator_ID"
          "&\$filter=QtyOnHand%20neq%200%20AND%20M_Product_ID%20eq%20$productId"
          "&\$top=$recordsSize"
          "&\$skip=$skipRecords";

      final responseStorage = await dio.get(urlStorage);

      if (responseStorage.statusCode != 200) break;

      final responseApiStorage =
      ResponseApi<IdempiereStorageOnHande>.fromJson(
        responseStorage.data,
        IdempiereStorageOnHande.fromJson,
      );

      totalRecords = responseApiStorage.rowCount ?? 0;
      totalPages = responseApiStorage.pageCount ?? 0;
      recordsSize = responseApiStorage.recordsSize ?? recordsSize;
      skipRecords = responseApiStorage.skipRecords ?? skipRecords;

      if (firstPage) {
        firstPage = false;
        if (totalPages <= 0 && totalRecords > 0) {
          ref.read(storeOnHandProgressProvider.notifier).state = 0.01;
        }
      }

      final pageRecords =
          responseApiStorage.records ?? <IdempiereStorageOnHande>[];

      if (pageRecords.isNotEmpty) {
        allStorage.addAll(pageRecords);
      }

      // English: Progress update
      if (ref.mounted) {
        double p = 0.0;
        if (totalPages > 0) {
          final currentPage = (skipRecords ~/ recordsSize) + 1;
          p = currentPage / totalPages;
        } else if (totalRecords > 0) {
          p = allStorage.length / totalRecords;
        }
        ref.read(storeOnHandProgressProvider.notifier).state =
            p.clamp(0.0, 1.0);
      }

      if (totalRecords == 0) break;
      if (allStorage.length >= totalRecords) break;
      if (pageRecords.isEmpty) break;

      skipRecords += recordsSize;
    }

    // =========================
    // 3) Group, sort and summarize
    // =========================
    if (allStorage.isNotEmpty) {
      productWithStock.listStorageOnHande = allStorage;
      ref.read(unsortedStoreOnHandListProvider.notifier).state = allStorage;

      final Map<String, IdempiereStorageOnHande> grouped = {};
      final int warehouseUser =
          ref.read(authProvider).selectedWarehouse?.id ?? 0;

      for (var data in allStorage) {
        if (product.id == data.mProductID?.id) {
          final key =
              '${data.mLocatorID?.value}-${data.mAttributeSetInstanceID?.id}';
          grouped.update(
            key,
                (v) => v
              ..qtyOnHand =
                  (v.qtyOnHand ?? 0) + (data.qtyOnHand ?? 0),
            ifAbsent: () => IdempiereStorageOnHande(
              mLocatorID: data.mLocatorID,
              mAttributeSetInstanceID: data.mAttributeSetInstanceID,
              qtyOnHand: data.qtyOnHand,
              mProductID: data.mProductID,
            ),
          );
        }
      }

      List<IdempiereStorageOnHande> productsList = grouped.values.toList();

      Map<int, List<IdempiereStorageOnHande>> groupedByWarehouse = {};
      for (var p in productsList) {
        int warehouseID = p.mLocatorID?.mWarehouseID?.id ?? 0;
        groupedByWarehouse.putIfAbsent(warehouseID, () => []).add(p);
      }

      groupedByWarehouse.forEach(
            (_, value) => value.sort(
              (a, b) => (b.qtyOnHand ?? 0).compareTo(a.qtyOnHand ?? 0),
        ),
      );

      List<int> sortedWarehouseIDs =
      groupedByWarehouse.keys.toList()..sort();
      if (groupedByWarehouse.containsKey(warehouseUser)) {
        sortedWarehouseIDs.remove(warehouseUser);
        sortedWarehouseIDs.insert(0, warehouseUser);
      }

      productWithStock.sortedStorageOnHande = [
        for (var wid in sortedWarehouseIDs)
          ...groupedByWarehouse[wid]!
              .where((x) => (x.qtyOnHand ?? 0) != 0)
      ];

      double quantity = 0;
      for (var data in productWithStock.sortedStorageOnHande!) {
        int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;
        if (warehouseID == warehouseUser) {
          quantity += data.qtyOnHand ?? 0;
        }
      }

      final userWarehouse =
          ref.read(authProvider).selectedWarehouse;

      ref.read(resultOfSameWarehouseProvider.notifier).state = [
        Memory.numberFormatter0Digit.format(quantity),
        userWarehouse?.name ?? '',
      ];
    }

    // English: Success response
    responseValue.success = true;
    responseValue.data = productWithStock;
    responseValue.message = withValue(Messages.OK);

    if (ref.mounted) {
      ref.read(storeOnHandProgressProvider.notifier).state = 1.0;
    }

    return responseValue;
  } on DioException catch (e) {
    // English: No throw, return error payload
    responseValue.success = false;
    responseValue.message = withValue(
      '${Messages.ERROR} : ${e.message ?? ''}',
    );
    return responseValue;
  } catch (e) {
    // English: No throw, return error payload
    responseValue.success = false;
    responseValue.message = withValue(
      '${Messages.ERROR} : ${e.toString()}',
    );
    return responseValue;
  } finally {
    ref.read(isScanningProvider.notifier).state = false;
    if (ref.mounted) {
      ref.read(storeOnHandProgressProvider.notifier).state = 1.0;
    }
  }
});


/*final findProductByUPCOrSKUForStoreOnHandProvider = FutureProvider.autoDispose<ProductWithStock>((ref) async {
  final String? scannedCode = ref.watch(scannedCodeForStoredOnHandProvider)?.toUpperCase();

  ProductWithStock productWithStock = ProductWithStock(searched: false,showResultCard: true);

  if(scannedCode==null || scannedCode=='') return productWithStock;
  productWithStock.searched = true;
  productWithStock.searchString = scannedCode;
  int? aux = int.tryParse(scannedCode);
  String searchField ='upc';
  if(aux==null){
    searchField = 'sku';
  }
  Dio dio = await DioClient.create();
  ref.read(showResultCardProvider.notifier).state = true;
  try {
    String url =
        "/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereProduct>.fromJson(response.data, IdempiereProduct.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        if(productsList.isEmpty){
          return productWithStock;
        }
        IdempiereProduct product = productsList[0];
        productWithStock.copyWithProduct(product);
        int skip=100;

        if(productWithStock.hasProduct){
          String productId = product.id.toString();
          String url = "/api/v1/models/m_storageonhand?\$expand=M_Locator_ID&\$IsActive=true"
              "&\$filter=QtyOnHand%20neq%200%20AND%20M_Product_ID%20eq%20$productId&\$top=100&\$skip=$skip";

          print(url);
          final response = await dio.get(url);
          if (response.statusCode == 200) {

            final responseApi =
            ResponseApi<IdempiereStorageOnHande>.fromJson(response.data, IdempiereStorageOnHande.fromJson);
            //print(response.data);
            int totalRecords = responseApi.rowCount ?? 0; //registros totales que debe ser extraidos
            int totalPages = responseApi.pageCount ?? 0; // veces a ejecutar  para todos los registros
            int recordsSize = responseApi.recordsSize ?? 100; // default = 100 (catidad de registro maximo enviado por cada consulta)
            int skipRecords = responseApi.skipRecords ?? 0; // inicio de posicion de registros a extrae

            print(responseApi.records?.length ?? 'null');
            if (responseApi.records != null && responseApi.records!.isNotEmpty) {
              ref.watch(showResultCardProvider.notifier).update((state) =>true);

              final productsListRaw = responseApi.records!;
              productWithStock.listStorageOnHande = productsListRaw;

              ref.watch(unsortedStoreOnHandListProvider.notifier).state = productsListRaw;
              Map<String, IdempiereStorageOnHande> groupedProducts = {};
              int warehouseUser = ref.read(authProvider).selectedWarehouse?.id ?? 0;

              for (var data in productsListRaw) {

                if (product.id == data.mProductID?.id) {
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
              final userWarehouse = ref.read(authProvider).selectedWarehouse;
              productWithStock.sortedStorageOnHande = sortedProductsList;
              final ProductWithStock result = productWithStock;
              int userWarehouseId = userWarehouse?.id ?? 0;
              String userWarehouseName = userWarehouse?.name ?? '';
              double quantity = 0;
              if(result.hasListStorageOnHande){
                for (var data in result.sortedStorageOnHande!) {
                  int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;

                  if (warehouseID == userWarehouseId) {
                    quantity += data.qtyOnHand ?? 0;
                  }
                }
              }
              String aux = Memory.numberFormatter0Digit.format(quantity);
              ref.read(resultOfSameWarehouseProvider.notifier).update((state) =>  [aux,userWarehouseName]);
            }
          }
        }
      }
    }
    return productWithStock;
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }  finally {
    ref.read(isScanningProvider.notifier).state = false;
  }

});*/


final storeOnHandProgressProvider =
StateProvider.autoDispose<double>((ref) => 0.0);
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
  } finally {
    ref.read(isScanningProvider.notifier).state = false;
  }

});


final findProductsStoreOnHandProvider = FutureProvider.autoDispose<List<IdempiereStorageOnHande>>((ref) async {

  final productId = ref.watch(productIdProvider);
  //final productId = 0 ;
  print('------------h---------findProductsStoreOnHandProvider---$productId');
  if(productId<= 0){

    return [];
  }

  Dio dio = await DioClient.create();
  try {
    String url = "/api/v1/models/m_storageonhand?\$expand=M_Locator_ID&\$IsActive=true"
        "&\$filter=QtyOnHand%20neq%200%20AND%20M_Product_ID%20eq%20$productId";
    print(url);
    final response = await dio.get(url);
    print(response.statusCode);


    if (response.statusCode == 200) {

      final responseApi =
      ResponseApi<IdempiereStorageOnHande>.fromJson(response.data, IdempiereStorageOnHande.fromJson);
      //print(response.data);
      print(responseApi.records?.length ?? 'null');
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        ref.watch(showResultCardProvider.notifier).update((state) =>true);

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




final resultOfSameWarehouseProvider = StateProvider<List<String>>((ref) {
  return [];
});

final unsortedStoreOnHandListProvider = StateProvider<List<IdempiereStorageOnHande>>((ref) {
  return [];
});


final showResultCardProvider = StateProvider.autoDispose<bool>((ref) {
  return true;
});

final searchByMOLIConfigurableSKUProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
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




final findProductsStoreOnHandProvider2 = FutureProvider.autoDispose<List<IdempiereStorageOnHande>>((ref) async {
  //from ProductHomeScreen (copy from) ProductSearchScreen
  final productId = ref.watch(productForUpcUpdateProvider.notifier).state.id ?? 0;
  //final productId = ref.watch(productIdProvider2);
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
final findProductsStoreOnHandProvider3 = FutureProvider.autoDispose<List<IdempiereStorageOnHande>>((ref) async {

  final productId = ref.watch(productIdProvider2);
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

