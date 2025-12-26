

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand_provider.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../domain/idempiere/product_with_stock.dart';


final scannedCodeForPutAwayMovementProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
});

final productIdForPutAwayMovementProvider = StateProvider.autoDispose<int?>((ref) {
  return null;
});
final putAwayOnHandProgressProvider =
StateProvider.autoDispose<double>((ref) => 0.0);
final findProductForPutAwayMovementProvider =
FutureProvider.autoDispose<ProductWithStock>((ref) async {
  final String? scannedCode =
  ref.watch(scannedCodeForPutAwayMovementProvider)?.toUpperCase();

  ProductWithStock productWithStock =
  ProductWithStock(searched: false, showResultCard: true);

  // reset progress
  ref.read(putAwayOnHandProgressProvider.notifier).state = 0.0;

  if (scannedCode == null || scannedCode == '') return productWithStock;

  productWithStock.searched = true;
  productWithStock.searchString = scannedCode;

  int? aux = int.tryParse(scannedCode);
  String searchField = 'upc';
  if (aux == null) {
    searchField = 'sku';
  }

  final int userWarehouseId = ref.read(authProvider).selectedWarehouse?.id ?? 0;
  final String userWarehouseName =
      ref.read(authProvider).selectedWarehouse?.name ?? '';

  Dio dio = await DioClient.create();
  ref.read(showResultCardProvider.notifier).state = true;

  try {
    // =========================
    // 1) Buscar producto
    // =========================
    String url =
        "/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');
    print(url);

    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi = ResponseApi<IdempiereProduct>.fromJson(
        response.data,
        IdempiereProduct.fromJson,
      );

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        if (productsList.isEmpty) return productWithStock;

        IdempiereProduct product = productsList[0];
        productWithStock.copyWithProduct(product);

        if (productWithStock.hasProduct) {
          // =========================
          // 2) Buscar storage on hand (PAGINADO)
          // =========================
          final String productId = product.id.toString();

          int totalRecords = 0;  // registros totales a extraer
          int totalPages = 0;    // páginas totales
          int recordsSize = 100; // top
          int skipRecords = 0;   // skip actual

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

            // Si luego quieres reactivar filtro por locator, hazlo aquí:
            // if (MemoryProducts.movementAndLines.hasLastLocatorFrom) {
            //   urlStorage =
            //     '$urlStorage%20AND%20M_Locator_ID%20eq%20${MemoryProducts.movementAndLines.lastLocatorFrom!.id!}';
            // }

            print(urlStorage);

            final responseStorage = await dio.get(urlStorage);

            if (responseStorage.statusCode != 200) {
              break;
            }

            final responseApiStorage =
            ResponseApi<IdempiereStorageOnHande>.fromJson(
              responseStorage.data,
              IdempiereStorageOnHande.fromJson,
            );

            // ✅ Variables pedidas
            totalRecords = responseApiStorage.rowCount ?? 0;
            totalPages = responseApiStorage.pageCount ?? 0;
            recordsSize = responseApiStorage.recordsSize ?? recordsSize;
            skipRecords = responseApiStorage.skipRecords ?? skipRecords;

            final pageRecords =
                responseApiStorage.records ?? <IdempiereStorageOnHande>[];

            if (pageRecords.isNotEmpty) {
              allStorage.addAll(pageRecords);
            }

            // ✅ progreso (páginas si existe, si no por items)
            if (ref.mounted) {
              double p = 0.0;
              if (firstPage) {
                firstPage = false;
                // si totalPages todavía no viene, da un empujón
                if (totalPages <= 0 && totalRecords > 0) {
                  p = 0.01;
                }
              }
              if (totalPages > 0) {
                final currentPage = (skipRecords ~/ recordsSize) + 1;
                p = currentPage / totalPages;
              } else if (totalRecords > 0) {
                p = allStorage.length / totalRecords;
              }
              ref.read(putAwayOnHandProgressProvider.notifier).state =
                  p.clamp(0.0, 1.0);
            }

            // fin
            if (totalRecords == 0) break;
            if (allStorage.length >= totalRecords) break;
            if (pageRecords.isEmpty) break;

            // siguiente página
            skipRecords += recordsSize;
          }

          // si hay datos, seguir con tu lógica original
          if (allStorage.isNotEmpty) {
            ref.read(showResultCardProvider.notifier).state = true;

            productWithStock.listStorageOnHande = allStorage;
            ref.read(unsortedStoreOnHandListProvider.notifier).state = allStorage;

            Map<String, IdempiereStorageOnHande> groupedProducts = {};
            int warehouseUser = ref.read(authProvider).selectedWarehouse?.id ?? 0;

            for (var data in allStorage) {
              if (product.id == data.mProductID?.id) {
                String key =
                    '${data.mLocatorID?.value}-${data.mAttributeSetInstanceID?.id}';
                if (groupedProducts.containsKey(key)) {
                  groupedProducts[key]!.qtyOnHand =
                      (groupedProducts[key]!.qtyOnHand ?? 0) + (data.qtyOnHand ?? 0);
                } else {
                  groupedProducts[key] = IdempiereStorageOnHande(
                    mLocatorID: data.mLocatorID,
                    mAttributeSetInstanceID: data.mAttributeSetInstanceID,
                    qtyOnHand: data.qtyOnHand,
                    mProductID: data.mProductID,
                  );
                }
              }
            }

            List<IdempiereStorageOnHande> productsList =
            groupedProducts.values.toList();

            Map<int, List<IdempiereStorageOnHande>> groupedByWarehouse = {};
            for (var p in productsList) {
              int warehouseID = p.mLocatorID?.mWarehouseID?.id ?? 0;
              groupedByWarehouse.putIfAbsent(warehouseID, () => []).add(p);
            }

            groupedByWarehouse.forEach((key, value) {
              value.sort((a, b) =>
                  (b.qtyOnHand ?? 0).compareTo(a.qtyOnHand ?? 0));
            });

            List<int> sortedWarehouseIDs =
            groupedByWarehouse.keys.toList()..sort();
            if (groupedByWarehouse.containsKey(warehouseUser)) {
              sortedWarehouseIDs.remove(warehouseUser);
              sortedWarehouseIDs.insert(0, warehouseUser);
            }

            List<IdempiereStorageOnHande> sortedProductsList = [];
            for (var warehouseID in sortedWarehouseIDs) {
              sortedProductsList.addAll(
                groupedByWarehouse[warehouseID]!
                    .where((x) => (x.qtyOnHand ?? 0) != 0),
              );
            }

            productWithStock.sortedStorageOnHande = sortedProductsList;

            double quantity = 0;
            if (productWithStock.sortedStorageOnHande != null) {
              for (var data in productWithStock.sortedStorageOnHande!) {
                int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;
                if (warehouseID == userWarehouseId) {
                  quantity += data.qtyOnHand ?? 0;
                }
              }
            }

            String qtyTxt = Memory.numberFormatter0Digit.format(quantity);
            ref.read(resultOfSameWarehouseProvider.notifier)
                .update((state) => [qtyTxt, userWarehouseName]);
          }

          // 100%
          if (ref.mounted) {
            ref.read(putAwayOnHandProgressProvider.notifier).state = 1.0;
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
  } finally {
    ref.read(isScanningProvider.notifier).state = false;
    if (ref.mounted) {
      ref.read(putAwayOnHandProgressProvider.notifier).state = 1.0;
    }
  }
});


/*final findProductForPutAwayMovementProvider = FutureProvider.autoDispose<ProductWithStock>((ref) async {
  final String? scannedCode = ref.watch(scannedCodeForPutAwayMovementProvider)?.toUpperCase();
  ProductWithStock productWithStock = ProductWithStock(searched: false,showResultCard: true);

  if(scannedCode==null || scannedCode=='') return productWithStock;
  productWithStock.searched = true;
  productWithStock.searchString = scannedCode;
  int? aux = int.tryParse(scannedCode);
  String searchField ='upc';
  if(aux==null){
    searchField = 'sku';
  }
  final int userWarehouseId = ref.read(authProvider).selectedWarehouse?.id ?? 0;
  final String userWarehouseName = ref.read(authProvider).selectedWarehouse?.name ?? '';
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


        if(productWithStock.hasProduct){
          String productId = product.id.toString();
          int skip=0;
          String url = "/api/v1/models/m_storageonhand?\$expand=M_Locator_ID"
              "&\$filter=QtyOnHand%20neq%200%20AND%20M_Product_ID%20eq%20$productId&\$top=100&\$skip=$skip";
          *//*if(MemoryProducts.movementAndLines.hasLastLocatorFrom){
            url = '$url%20AND%20M_Locator_ID%20eq%20${MemoryProducts.movementAndLines.lastLocatorFrom!.id!}';
          }*//*
          print(url);
          final response = await dio.get(url);
          if (response.statusCode == 200) {

            final responseApi =
            ResponseApi<IdempiereStorageOnHande>.fromJson(response.data, IdempiereStorageOnHande.fromJson);
            int totalRecords = responseApi.rowCount ?? 0; //registros totales que debe ser extraidos
            int totalPages = responseApi.pageCount ?? 0; // veces a ejecutar  para todos los registros
            int recordsSize = responseApi.recordsSize ?? 100; // default = 100 (catidad de registro maximo enviado por cada consulta)
            int skipRecords = responseApi.skipRecords ?? 0; // inicio de posicion de registros a extrae

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

              productWithStock.sortedStorageOnHande = sortedProductsList;
              final ProductWithStock result = productWithStock;
              double quantity = 0;
              if(result.sortedStorageOnHande!=null){
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



















