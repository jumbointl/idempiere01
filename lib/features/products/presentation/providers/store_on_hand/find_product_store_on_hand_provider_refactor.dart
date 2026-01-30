import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../config/http/dio_client.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../../shared/domain/entities/response_api.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/product_with_stock.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../../domain/models/idempiere_query_page_utils.dart';
import '../store_on_hand_for_put_away_movement.dart';
import '../store_on_hand_provider.dart';

Future<ResponseAsyncValue> findProductWithStorageOnHand({
  required Ref ref,
  required String scannedCode,
  required StateProvider<double> progressProvider,
  bool cacheResult = true,
}) async {
  final responseValue = ResponseAsyncValue(
    isInitiated: true,
    success: false,
    data: null,
  );
  Memory.lastSearch = scannedCode;
  final dio = await DioClient.create();
  ref.read(progressProvider.notifier).state = 0.0;

  String withValue(String msg) =>
      '$msg\n${Messages.VALUE} : $scannedCode';

  try {
    // 1) Find product
    final int? aux = int.tryParse(scannedCode);
    final String searchField = aux == null ? 'sku' : 'upc';

    String url =
    "/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'"
        .replaceAll(' ', '%20');

    final productResp = await dio.get(url);
    if (productResp.statusCode != 200) {
      responseValue.message = withValue(Messages.NO_DATA_FOUND);
      return responseValue;
    }

    final productApi = ResponseApi<IdempiereProduct>.fromJson(
      productResp.data,
      IdempiereProduct.fromJson,
    );

    if (productApi.records == null || productApi.records!.isEmpty) {
      responseValue.success = true;
      responseValue.message = withValue(Messages.NO_DATA_FOUND);
      return responseValue;
    }

    final product = productApi.records!.first;

    final productWithStock = ProductWithStock(
      searched: true,
      showResultCard: true,
    )..copyWithProduct(product);

    // 2) Fetch storage
    final meta = PaginationMeta();
    final allStorage = await fetchAllPages<IdempiereStorageOnHande>(
      dio: dio,
      baseUrl: "/api/v1/models/m_storageonhand?\$expand=M_Locator_ID",
      filterSuffix:
      "&\$filter=QtyOnHand neq 0 AND M_Product_ID eq ${product.id}",
      orderByColumn: "M_Locator_ID",
      parser: (json) => IdempiereStorageOnHande.fromJson(json),
      outMeta: meta,
      onProgress: (fetched, total, pages) {
        if (total > 0) {
          ref.read(progressProvider.notifier).state =
              (fetched / total).clamp(0.0, 1.0);
        }
      },
    );

    if (allStorage.isEmpty) {
      responseValue.success = true;
      responseValue.message = withValue(Messages.NO_DATA_FOUND);
      return responseValue;
    }

    // 3) Post-process (agrupación, orden, qty)
    productWithStock.listStorageOnHande = allStorage;
    // =========================
    // 3) Group, sort and summarize
    // =========================
    productWithStock.listStorageOnHande = allStorage;
    ref.read(unsortedStoreOnHandListProvider.notifier).state = allStorage;

    final Map<String, IdempiereStorageOnHande> grouped = {};
    final int warehouseUser =
        ref.read(authProvider).selectedWarehouse?.id ?? 0;

    for (final data in allStorage) {
      if (product.id == data.mProductID?.id) {
        final key =
            '${data.mLocatorID?.value}-${data.mAttributeSetInstanceID?.id}';

        grouped.update(
          key,
              (v) => v
            ..qtyOnHand = (v.qtyOnHand ?? 0) + (data.qtyOnHand ?? 0),
          ifAbsent: () => IdempiereStorageOnHande(
            mLocatorID: data.mLocatorID,
            mAttributeSetInstanceID: data.mAttributeSetInstanceID,
            qtyOnHand: data.qtyOnHand,
            mProductID: data.mProductID,
          ),
        );
      }
    }

    final List<IdempiereStorageOnHande> productsList = grouped.values.toList();

    final Map<int, List<IdempiereStorageOnHande>> groupedByWarehouse = {};
    for (final p in productsList) {
      final int warehouseID = p.mLocatorID?.mWarehouseID?.id ?? 0;
      groupedByWarehouse.putIfAbsent(warehouseID, () => []).add(p);
    }

    groupedByWarehouse.forEach(
          (_, value) =>
          value.sort((a, b) => (b.qtyOnHand ?? 0).compareTo(a.qtyOnHand ?? 0)),
    );

    final List<int> sortedWarehouseIDs =
    groupedByWarehouse.keys.toList()..sort();
    if (groupedByWarehouse.containsKey(warehouseUser)) {
      sortedWarehouseIDs.remove(warehouseUser);
      sortedWarehouseIDs.insert(0, warehouseUser);
    }

    productWithStock.sortedStorageOnHande = [
      for (final wid in sortedWarehouseIDs)
        ...groupedByWarehouse[wid]!.where((x) => (x.qtyOnHand ?? 0) != 0),
    ];

    double quantity = 0;
    for (final data
    in productWithStock.sortedStorageOnHande ?? <IdempiereStorageOnHande>[]) {
      final int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;
      if (warehouseID == warehouseUser) {
        quantity += data.qtyOnHand ?? 0;
      }
    }

    final userWarehouse = ref.read(authProvider).selectedWarehouse;

    ref.read(resultOfSameWarehouseProvider.notifier).state = [
      Memory.numberFormatter0Digit.format(quantity),
      userWarehouse?.name ?? '',
    ];

    responseValue.success = true;
    responseValue.data = productWithStock;
    responseValue.message = withValue(Messages.OK);

    if (cacheResult) {
      ref.read(productStoreOnHandCacheProvider.notifier).state =
          productWithStock;
    }

    return responseValue;
  } catch (e) {
    responseValue.message =
    '${Messages.ERROR}${e.toString()}\n${Messages.VALUE} : $scannedCode';
    return responseValue;
  } finally {
    ref.read(progressProvider.notifier).state = 1.0;
  }
}
