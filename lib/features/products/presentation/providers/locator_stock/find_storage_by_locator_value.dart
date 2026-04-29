import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../config/http/dio_client.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../../shared/domain/entities/response_api.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/locator_product_stock.dart';
import '../../../domain/idempiere/locator_with_product_stocks.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../../domain/models/idempiere_query_page_utils.dart';

/// Resolve a locator by its `Value`, then list every product on-hand in it.
///
/// 1. `GET /api/v1/models/m_locator?$filter=Value eq '<scannedCode>'`
/// 2. `GET /api/v1/models/m_storageonhand?$expand=M_Locator_ID,M_Product_ID
///        &$filter=QtyOnHand neq 0 and M_Locator_ID eq <id>&$orderby=UPC` (paged)
/// 3. Group rows client-side by `M_Product_ID` summing `QtyOnHand` to produce
///    one [LocatorProductStock] per product.
Future<ResponseAsyncValue> findStorageByLocatorValue({
  required Ref ref,
  required String scannedCode,
  required StateProvider<double> progressProvider,
  int? productIdFilter,
}) async {
  final responseValue = ResponseAsyncValue(
    isInitiated: true,
    success: false,
    data: null,
  );
  Memory.lastSearch = scannedCode;
  Memory.lastSearchLocator = scannedCode;
  final dio = await DioClient.create();
  ref.read(progressProvider.notifier).state = 0.0;

  String withValue(String msg) => '$msg\n${Messages.VALUE} : $scannedCode';

  try {
    final locUrl =
        "/api/v1/models/m_locator?\$filter=Value eq '$scannedCode'"
            .replaceAll(' ', '%20');

    final locResp = await dio.get(locUrl);
    if (locResp.statusCode != 200) {
      responseValue.message =
          withValue('${Messages.ERROR} ${Messages.STOCK}');
      return responseValue;
    }

    final locApi = ResponseApi<IdempiereLocator>.fromJson(
      locResp.data,
      IdempiereLocator.fromJson,
    );

    if (locApi.records == null || locApi.records!.isEmpty) {
      responseValue.success = true;
      responseValue.message =
          withValue('${Messages.NO_RECORDS_FOUND} : $scannedCode');
      return responseValue;
    }

    final locator = locApi.records!.first;

    final meta = PaginationMeta();
    final productClause = productIdFilter != null
        ? " AND M_Product_ID eq $productIdFilter"
        : '';
    final allStorage = await fetchAllPages<IdempiereStorageOnHande>(
      dio: dio,
      baseUrl:
          "/api/v1/models/m_storageonhand?\$expand=M_Locator_ID,M_Product_ID",
      filterSuffix:
          "&\$filter=QtyOnHand neq 0 AND M_Locator_ID eq ${locator.id}$productClause",
      orderByColumn: "M_Product_ID",
      parser: (json) => IdempiereStorageOnHande.fromJson(json),
      outMeta: meta,
      onProgress: (fetched, total, pages) {
        if (total > 0) {
          ref.read(progressProvider.notifier).state =
              (fetched / total).clamp(0.0, 1.0);
        }
      },
    );

    final Map<int, List<IdempiereStorageOnHande>> byProduct = {};
    for (final row in allStorage) {
      final int? pid = row.mProductID?.id;
      if (pid == null) continue;
      byProduct.putIfAbsent(pid, () => <IdempiereStorageOnHande>[]).add(row);
    }

    final List<LocatorProductStock> products = byProduct.entries
        .where((e) => e.value.isNotEmpty && e.value.first.mProductID != null)
        .map((e) {
      final rows = e.value;
      final double total = rows.fold<double>(
        0,
        (acc, r) => acc + (r.qtyOnHand ?? 0),
      );
      return LocatorProductStock(
        product: rows.first.mProductID!,
        totalShow: total,
        rawLines: rows,
      );
    }).toList()
      ..sort((a, b) =>
          (a.product.uPC ?? '').compareTo(b.product.uPC ?? ''));

    responseValue.success = true;
    responseValue.data = LocatorWithProductStocks(
      locator: locator,
      products: products,
    );
    responseValue.message = withValue(Messages.OK);
    return responseValue;
  } catch (e) {
    responseValue.message =
        '${Messages.ERROR}${e.toString()}\n${Messages.VALUE} : $scannedCode';
    return responseValue;
  } finally {
    ref.read(progressProvider.notifier).state = 1.0;
  }
}
