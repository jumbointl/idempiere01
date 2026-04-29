import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../config/http/dio_client.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/idempiere/movement_minout_check.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../../domain/models/idempiere_query_page_utils.dart';

const int _idsPerInQuery = 50;

String _inClauseInts(String column, Iterable<int> ids) {
  final list = ids.toList();
  if (list.isEmpty) return '';
  if (list.length == 1) return '$column eq ${list.first}';
  return '$column in (${list.join(',')})';
}

List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
  if (chunkSize <= 0 || list.length <= chunkSize) return <List<T>>[list];
  final out = <List<T>>[];
  for (int i = 0; i < list.length; i += chunkSize) {
    final end = (i + chunkSize > list.length) ? list.length : i + chunkSize;
    out.add(list.sublist(i, end));
  }
  return out;
}

double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int? _parseIntField(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

/// Resolve a document by `DocumentNo` and produce a per-locator stock check.
///
/// Steps:
/// 1. Fetch header.
///    - Movement: `m_movement?$filter=DocumentNo eq '<doc>'`
///    - MInOut:   `m_inout?$filter=DocumentNo eq '<doc>' and IsSOTrx eq 'Y'`
/// 2. Fetch lines (paginated) with `$expand=M_Product_ID,M_Locator_ID`.
/// 3. Group lines by `M_Locator_ID`. Lines with no locator go to
///    [MovementMInOutCheckPayload.linesWithoutLocator].
/// 4. For each unique locator, fetch `m_storageonhand` filtered by
///    `M_Locator_ID in (...) and M_Product_ID in (...)`, chunked at 50 ids
///    on each side to keep URLs short.
/// 5. Build [MovementMInOutCheckLocatorGroup]s with required vs available
///    aggregated by `M_Product_ID`.
Future<ResponseAsyncValue> findMovementMInOutByDocNo({
  required Ref ref,
  required String scannedCode,
  required MovementMInOutCheckSource source,
  required StateProvider<double> progressProvider,
}) async {
  final responseValue = ResponseAsyncValue(
    isInitiated: true,
    success: false,
    data: null,
  );
  Memory.lastSearch = scannedCode;
  final dio = await DioClient.create();
  ref.read(progressProvider.notifier).state = 0.0;

  String withValue(String msg) => '$msg\n${Messages.VALUE} : $scannedCode';

  try {
    // 1) Header lookup
    final String headerModel =
        source == MovementMInOutCheckSource.movement ? 'm_movement' : 'm_inout';

    final String headerFilter = source == MovementMInOutCheckSource.movement
        ? "DocumentNo eq '$scannedCode'"
        : "DocumentNo eq '$scannedCode' AND IsSOTrx eq 'Y'";

    final headerUrl =
        "/api/v1/models/$headerModel?\$filter=$headerFilter".replaceAll(' ', '%20');

    final headerResp = await dio.get(headerUrl);
    if (headerResp.statusCode != 200) {
      responseValue.message = withValue('${Messages.ERROR} ${Messages.STOCK}');
      return responseValue;
    }

    final List<dynamic> rawRecords =
        (headerResp.data?['records'] as List<dynamic>?) ?? <dynamic>[];
    if (rawRecords.isEmpty) {
      responseValue.success = true;
      responseValue.message =
          withValue('${Messages.NO_RECORDS_FOUND} : $scannedCode');
      return responseValue;
    }

    final headerJson = rawRecords.first as Map<String, dynamic>;
    final int? headerId = _parseIntField(headerJson['id']);
    if (headerId == null) {
      responseValue.message = withValue('${Messages.ERROR} : header id null');
      return responseValue;
    }

    // 2) Lines lookup
    final String lineModel = source == MovementMInOutCheckSource.movement
        ? 'm_movementline'
        : 'm_inoutline';
    final String lineFkColumn = source == MovementMInOutCheckSource.movement
        ? 'M_Movement_ID'
        : 'M_InOut_ID';
    // Order by `Line` first (the human-visible line number) and break
    // ties by the immutable line id so two lines sharing a `Line` never
    // shuffle between fetches.
    final String lineOrderBy = source == MovementMInOutCheckSource.movement
        ? 'Line,M_MovementLine_ID'
        : 'Line,M_InOutLine_ID';

    final lines = await fetchAllPages<Map<String, dynamic>>(
      dio: dio,
      baseUrl: "/api/v1/models/$lineModel?\$expand=M_Product_ID,M_Locator_ID",
      filterSuffix: "&\$filter=$lineFkColumn eq $headerId",
      orderByColumn: lineOrderBy,
      parser: (json) => json,
    );

    if (lines.isEmpty) {
      responseValue.success = true;
      responseValue.data = MovementMInOutCheckPayload(
        source: source,
        documentNo: scannedCode,
        headerId: headerId,
        locatorGroups: const <MovementMInOutCheckLocatorGroup>[],
        linesWithoutLocator: const <MovementMInOutCheckLine>[],
      );
      responseValue.message = withValue(Messages.NO_DATA_FOUND);
      return responseValue;
    }

    // 3) Parse each line and group by locator id
    final Map<int, List<MovementMInOutCheckLine>> linesByLocator = {};
    final List<MovementMInOutCheckLine> linesWithoutLocator = [];
    final Map<int, IdempiereLocator> locatorById = {};
    final Set<int> productIds = <int>{};

    for (final raw in lines) {
      final productMap = raw['M_Product_ID'];
      if (productMap is! Map) continue;
      final product =
          IdempiereProduct.fromJson(Map<String, dynamic>.from(productMap));
      if (product.id == null) continue;
      productIds.add(product.id!);

      final locatorMap = raw['M_Locator_ID'];
      IdempiereLocator? locator;
      if (locatorMap is Map) {
        locator = IdempiereLocator.fromJson(
            Map<String, dynamic>.from(locatorMap));
        if (locator.id != null) locatorById[locator.id!] = locator;
      }

      final line = MovementMInOutCheckLine(
        product: product,
        locator: locator,
        qtyToMove: _parseDouble(raw['MovementQty']),
        lineNo: _parseIntField(raw['Line']),
        documentLineId: _parseIntField(raw['id']),
      );

      if (locator?.id != null) {
        linesByLocator
            .putIfAbsent(locator!.id!, () => <MovementMInOutCheckLine>[])
            .add(line);
      } else {
        linesWithoutLocator.add(line);
      }
    }

    // 4) Fetch storage for (locators, products), chunked on both sides
    final storageRows = <IdempiereStorageOnHande>[];
    final locatorIds = linesByLocator.keys.toList();
    final productIdList = productIds.toList();

    if (locatorIds.isNotEmpty && productIdList.isNotEmpty) {
      for (final locChunk in _chunkList(locatorIds, _idsPerInQuery)) {
        for (final prodChunk in _chunkList(productIdList, _idsPerInQuery)) {
          final locClause = _inClauseInts('M_Locator_ID', locChunk);
          final prodClause = _inClauseInts('M_Product_ID', prodChunk);
          final rows = await fetchAllPages<IdempiereStorageOnHande>(
            dio: dio,
            baseUrl:
                "/api/v1/models/m_storageonhand?\$expand=M_Locator_ID,M_Product_ID",
            filterSuffix:
                "&\$filter=QtyOnHand neq 0 AND $locClause AND $prodClause",
            orderByColumn: "M_Locator_ID",
            parser: (json) => IdempiereStorageOnHande.fromJson(json),
          );
          storageRows.addAll(rows);
        }
      }
    }

    // 5) Aggregate available qty by (locator, product)
    final Map<int, Map<int, double>> availableByLocAndProd = {};
    for (final row in storageRows) {
      final lid = row.mLocatorID?.id;
      final pid = row.mProductID?.id;
      if (lid == null || pid == null) continue;
      final inner =
          availableByLocAndProd.putIfAbsent(lid, () => <int, double>{});
      inner[pid] = (inner[pid] ?? 0) + (row.qtyOnHand ?? 0);
    }

    // 6) Build groups, ordered by locator value/name for a stable list
    final groups = <MovementMInOutCheckLocatorGroup>[];
    for (final entry in linesByLocator.entries) {
      final locator = locatorById[entry.key];
      if (locator == null) continue;

      final required = <int, double>{};
      for (final ln in entry.value) {
        final pid = ln.product.id;
        if (pid == null) continue;
        required[pid] = (required[pid] ?? 0) + ln.qtyToMove;
      }

      groups.add(
        MovementMInOutCheckLocatorGroup(
          locator: locator,
          linesAssigned: entry.value,
          totalRequiredByProduct: required,
          totalAvailableByProduct:
              availableByLocAndProd[entry.key] ?? <int, double>{},
        ),
      );
    }
    groups.sort((a, b) =>
        (a.locator.value ?? '').compareTo(b.locator.value ?? ''));

    responseValue.success = true;
    responseValue.data = MovementMInOutCheckPayload(
      source: source,
      documentNo: scannedCode,
      headerId: headerId,
      locatorGroups: groups,
      linesWithoutLocator: linesWithoutLocator,
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
