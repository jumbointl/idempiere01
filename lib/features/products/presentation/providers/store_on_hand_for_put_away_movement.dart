

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand/find_product_store_on_hand_provider_refactor.dart';

import '../../domain/idempiere/product_with_stock.dart';





final putAwayOnHandProgressProvider =
StateProvider.autoDispose<double>((ref) => 0.0);

final productStoreOnHandCacheProvider =
StateProvider<ProductWithStock?>((ref) => null);




/*
final findProductForPutAwayMovementProvider =
FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final int count = ref.watch(fireSearchForStoredOnHandCounterProvider);

  if (count == 0) {
    return ResponseAsyncValue(
      isInitiated: false,
      success: false,
      data: null,
      message: null,
    );
  }
  final String? scannedCode =
  ref.read(scannedCodeForPutAwayMovementProvider)?.toUpperCase();

  // English: Initial / waiting state (not initiated)
  if (scannedCode == null || scannedCode.isEmpty) {
    return ResponseAsyncValue(
      isInitiated: false,
      success: false,
      data: null,
      message: null,
    );
  }
  // English: Reset progress for each new request
  ref.read(putAwayOnHandProgressProvider.notifier).state = 0.0;
  final int userWarehouseId = ref.read(authProvider).selectedWarehouse?.id ?? 0;
  final String userWarehouseName =
      ref.read(authProvider).selectedWarehouse?.name ?? '';

  // English: Prepare domain object (will be returned as data when success)
  ProductWithStock productWithStock =
  ProductWithStock(searched: true, showResultCard: true)
    ..searchString = scannedCode;

  final int? aux = int.tryParse(scannedCode);
  final String searchField = (aux == null) ? 'sku' : 'upc';

  final dio = await DioClient.create();
  ref.read(showResultCardProvider.notifier).state = true;

  try {
    // =========================
    // 1) Find product
    // =========================
    String url = "/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');

    final response = await dio.get(url);

    if (response.statusCode != 200) {
      return ResponseAsyncValue(
        isInitiated: true,
        success: false,
        data: null,
        message: 'HTTP ${response.statusCode} : ${Messages.VALUE} : $scannedCode',
      );
    }

    final responseApi = ResponseApi<IdempiereProduct>.fromJson(
      response.data,
      IdempiereProduct.fromJson,
    );

    final productsList = responseApi.records ?? <IdempiereProduct>[];
    if (productsList.isEmpty) {
      // English: Initiated but nothing found
      return ResponseAsyncValue(
        isInitiated: true,
        success: true,
        data: null,
        message: '${Messages.NO_DATA_FOUND} : ${Messages.VALUE} : $scannedCode',
      );
    }

    final IdempiereProduct product = productsList.first;
    productWithStock.copyWithProduct(product);

    if (!productWithStock.hasProduct) {
      return ResponseAsyncValue(
        isInitiated: true,
        success: true,
        data: null,
        message: '${Messages.NO_DATA_FOUND} : ${Messages.VALUE} : $scannedCode',
      );
    }

    // =========================
    // 2) Storage on hand (PAGINATED)
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

      if (responseStorage.statusCode != 200) {
        break;
      }

      final responseApiStorage = ResponseApi<IdempiereStorageOnHande>.fromJson(
        responseStorage.data,
        IdempiereStorageOnHande.fromJson,
      );

      totalRecords = responseApiStorage.rowCount ?? 0;
      totalPages = responseApiStorage.pageCount ?? 0;
      recordsSize = responseApiStorage.recordsSize ?? recordsSize;
      skipRecords = responseApiStorage.skipRecords ?? skipRecords;

      final pageRecords =
          responseApiStorage.records ?? <IdempiereStorageOnHande>[];

      if (pageRecords.isNotEmpty) {
        allStorage.addAll(pageRecords);
      }

      // English: Update progress (prefer pages, fallback to items)
      if (ref.mounted) {
        double p = 0.0;

        if (firstPage) {
          firstPage = false;
          if (totalPages <= 0 && totalRecords > 0) p = 0.01;
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

      // English: Stop conditions
      if (totalRecords == 0) break;
      if (allStorage.length >= totalRecords) break;
      if (pageRecords.isEmpty) break;

      // English: Next page
      skipRecords += recordsSize;
    }

    // =========================
    // 3) Post-process storage list (your existing logic)
    // =========================
    if (allStorage.isNotEmpty) {
      ref.read(showResultCardProvider.notifier).state = true;

      productWithStock.listStorageOnHande = allStorage;
      ref.read(unsortedStoreOnHandListProvider.notifier).state = allStorage;

      final Map<String, IdempiereStorageOnHande> groupedProducts = {};

      for (final data in allStorage) {
        if (product.id == data.mProductID?.id) {
          final key =
              '${data.mLocatorID?.value}-${data.mAttributeSetInstanceID?.id}';

          if (groupedProducts.containsKey(key)) {
            groupedProducts[key]!.qtyOnHand =
                (groupedProducts[key]!.qtyOnHand ?? 0) +
                    (data.qtyOnHand ?? 0);
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

      final productsList = groupedProducts.values.toList();

      final Map<int, List<IdempiereStorageOnHande>> groupedByWarehouse = {};
      for (final p in productsList) {
        final warehouseID = p.mLocatorID?.mWarehouseID?.id ?? 0;
        groupedByWarehouse.putIfAbsent(warehouseID, () => []).add(p);
      }

      groupedByWarehouse.forEach((_, value) {
        value.sort((a, b) => (b.qtyOnHand ?? 0).compareTo(a.qtyOnHand ?? 0));
      });

      final sortedWarehouseIDs = groupedByWarehouse.keys.toList()..sort();
      if (groupedByWarehouse.containsKey(userWarehouseId)) {
        sortedWarehouseIDs.remove(userWarehouseId);
        sortedWarehouseIDs.insert(0, userWarehouseId);
      }

      final List<IdempiereStorageOnHande> sortedProductsList = [];
      for (final warehouseID in sortedWarehouseIDs) {
        sortedProductsList.addAll(
          groupedByWarehouse[warehouseID]!.where((x) => (x.qtyOnHand ?? 0) != 0),
        );
      }

      productWithStock.sortedStorageOnHande = sortedProductsList;

      // English: Same-warehouse summary qty
      double quantity = 0;
      for (final data in productWithStock.sortedStorageOnHande ?? <IdempiereStorageOnHande>[]) {
        final warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;
        if (warehouseID == userWarehouseId) {
          quantity += data.qtyOnHand ?? 0;
        }
      }

      final qtyTxt = Memory.numberFormatter0Digit.format(quantity);
      ref
          .read(resultOfSameWarehouseProvider.notifier)
          .update((state) => [qtyTxt, userWarehouseName]);
    }

    // English: Finish progress
    if (ref.mounted) {
      ref.read(putAwayOnHandProgressProvider.notifier).state = 1.0;
    }
    ref.read(productStoreOnHandCacheProvider.notifier).state = productWithStock;

    // ✅ Success with data
    return ResponseAsyncValue(
      isInitiated: true,
      success: true,
      data: productWithStock,
      message: null,
    );
  } on DioException catch (e) {
    return ResponseAsyncValue(
      isInitiated: true,
      success: false,
      data: null,
      message: '${Messages.VALUE} : $scannedCode :${mapDioErrorToMessage(e)}',
    );
  } catch (e) {
    return ResponseAsyncValue(
      isInitiated: true,
      success: false,
      data: null,
      message: '${Messages.VALUE} : $scannedCode :${e.toString()}',
    );
  } finally {
    ref.read(isScanningProvider.notifier).state = false;
    if (ref.mounted) {
      ref.read(putAwayOnHandProgressProvider.notifier).state = 1.0;
    }
  }
});
 */



















