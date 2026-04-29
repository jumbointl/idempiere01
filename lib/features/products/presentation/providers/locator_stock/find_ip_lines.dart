import '../../../../../config/http/dio_client.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../../domain/idempiere/locator_ip_line.dart';
import '../../../domain/models/idempiere_query_page_utils.dart';

/// Idempiere REST `in` clause for a chunk of integer ids:
/// `column in (1,2,3)` — when only one id, falls back to `column eq id`.
/// Note: iDempiere REST is case-sensitive — must be lowercase `in`.
String _inClauseInts(String column, Iterable<int> ids) {
  final list = ids.toList();
  if (list.isEmpty) return '';
  if (list.length == 1) return '$column eq ${list.first}';
  return '$column in (${list.join(',')})';
}

/// Maximum number of header ids per follow-up `m_*line` query.
/// Keeps the URL under iDempiere REST's practical length limit.
const int _idsPerLineQuery = 50;

List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
  if (chunkSize <= 0 || list.length <= chunkSize) return <List<T>>[list];
  final out = <List<T>>[];
  for (int i = 0; i < list.length; i += chunkSize) {
    final end = (i + chunkSize > list.length) ? list.length : i + chunkSize;
    out.add(list.sublist(i, end));
  }
  return out;
}

String _formatIdempiereDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return "'${d.year}-${two(d.month)}-${two(d.day)}'";
}

DateTime? _parseIdempiereDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  final s = raw.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s.replaceFirst(' ', 'T'));
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

/// 1) `m_movement` headers in `IP` within date range, scoped by warehouse
///    (matches as `from` or `to`).
/// 2) `m_movementline` whose header is in (1) AND `M_Locator_ID = locator`
///    (origin locator — destination is `M_LocatorTo_ID`)
///    AND `M_Product_ID = product.id`.
Future<List<LocatorIpLine>> findMovementIpLinesForLocatorProduct({
  required IdempiereLocator locator,
  required IdempiereProduct product,
  required DateTime dateFrom,
  required DateTime dateTo,
}) async {
  final int? warehouseId = locator.mWarehouseID?.id;
  final int? productId = product.id;
  if (warehouseId == null || productId == null || locator.id == null) {
    return const <LocatorIpLine>[];
  }

  final dio = await DioClient.create();
  final dFrom = _formatIdempiereDate(dateFrom);
  final dTo = _formatIdempiereDate(dateTo);

  final headers = await fetchAllPages<Map<String, dynamic>>(
    dio: dio,
    baseUrl: "/api/v1/models/m_movement?",
    filterSuffix:
        "\$filter=DocStatus eq 'IP' AND MovementDate ge $dFrom AND MovementDate le $dTo "
        "AND (M_Warehouse_ID eq $warehouseId OR M_WarehouseTo_ID eq $warehouseId)",
    orderByColumn: "MovementDate",
    parser: (json) => json,
  );

  if (headers.isEmpty) return const <LocatorIpLine>[];

  final Map<int, Map<String, dynamic>> headerById = {
    for (final h in headers)
      if (_parseIntField(h['id']) != null)
        _parseIntField(h['id'])!: h,
  };
  if (headerById.isEmpty) return const <LocatorIpLine>[];

  final lines = <Map<String, dynamic>>[];
  for (final chunk in _chunkList(headerById.keys.toList(), _idsPerLineQuery)) {
    final inClause = _inClauseInts('M_Movement_ID', chunk);
    final chunkLines = await fetchAllPages<Map<String, dynamic>>(
      dio: dio,
      baseUrl: "/api/v1/models/m_movementline?",
      filterSuffix:
          "\$filter=$inClause AND M_Locator_ID eq ${locator.id} AND M_Product_ID eq $productId",
      orderByColumn: "M_Movement_ID",
      parser: (json) => json,
    );
    lines.addAll(chunkLines);
  }

  return lines.map((l) {
    final int? movId = _parseIntField(l['M_Movement_ID'] is Map
        ? (l['M_Movement_ID'] as Map)['id']
        : l['M_Movement_ID']);
    final header = movId == null ? null : headerById[movId];
    return LocatorIpLine(
      source: LocatorIpLineSource.mov,
      documentNo: header?['DocumentNo']?.toString() ?? '',
      movementDate: _parseIdempiereDate(header?['MovementDate']),
      qty: _parseDouble(l['MovementQty']),
      description: l['Description']?.toString(),
      lineNo: _parseIntField(l['Line']),
    );
  }).toList();
}

/// 1) `m_inout` headers in `IP` within date range, `IsSOTrx = Y`, warehouse.
/// 2) `m_inoutline` whose header is in (1) AND `M_Locator_ID = locator`
///    AND `M_Product_ID = product.id`.
Future<List<LocatorIpLine>> findMInOutIpLinesForLocatorProduct({
  required IdempiereLocator locator,
  required IdempiereProduct product,
  required DateTime dateFrom,
  required DateTime dateTo,
}) async {
  final int? warehouseId = locator.mWarehouseID?.id;
  final int? productId = product.id;
  if (warehouseId == null || productId == null || locator.id == null) {
    return const <LocatorIpLine>[];
  }

  final dio = await DioClient.create();
  final dFrom = _formatIdempiereDate(dateFrom);
  final dTo = _formatIdempiereDate(dateTo);

  final headers = await fetchAllPages<Map<String, dynamic>>(
    dio: dio,
    baseUrl: "/api/v1/models/m_inout?",
    filterSuffix:
        "\$filter=DocStatus eq 'IP' AND IsSOTrx eq 'Y' "
        "AND MovementDate ge $dFrom AND MovementDate le $dTo "
        "AND M_Warehouse_ID eq $warehouseId",
    orderByColumn: "MovementDate",
    parser: (json) => json,
  );

  if (headers.isEmpty) return const <LocatorIpLine>[];

  final Map<int, Map<String, dynamic>> headerById = {
    for (final h in headers)
      if (_parseIntField(h['id']) != null)
        _parseIntField(h['id'])!: h,
  };
  if (headerById.isEmpty) return const <LocatorIpLine>[];

  final lines = <Map<String, dynamic>>[];
  for (final chunk in _chunkList(headerById.keys.toList(), _idsPerLineQuery)) {
    final inClause = _inClauseInts('M_InOut_ID', chunk);
    final chunkLines = await fetchAllPages<Map<String, dynamic>>(
      dio: dio,
      baseUrl: "/api/v1/models/m_inoutline?",
      filterSuffix:
          "\$filter=$inClause AND M_Locator_ID eq ${locator.id} AND M_Product_ID eq $productId",
      orderByColumn: "M_InOut_ID",
      parser: (json) => json,
    );
    lines.addAll(chunkLines);
  }

  return lines.map((l) {
    final int? hid = _parseIntField(l['M_InOut_ID'] is Map
        ? (l['M_InOut_ID'] as Map)['id']
        : l['M_InOut_ID']);
    final header = hid == null ? null : headerById[hid];
    return LocatorIpLine(
      source: LocatorIpLineSource.minout,
      documentNo: header?['DocumentNo']?.toString() ?? '',
      movementDate: _parseIdempiereDate(header?['MovementDate']),
      qty: _parseDouble(l['MovementQty']) != 0
          ? _parseDouble(l['MovementQty'])
          : _parseDouble(l['QtyEntered']),
      description: l['Description']?.toString(),
      lineNo: _parseIntField(l['Line']),
    );
  }).toList();
}

/// Run both queries in parallel and return a combined list ordered by date.
Future<List<LocatorIpLine>> findIpLinesForLocatorProduct({
  required IdempiereLocator locator,
  required IdempiereProduct product,
  required DateTime dateFrom,
  required DateTime dateTo,
}) async {
  final results = await Future.wait<List<LocatorIpLine>>([
    findMovementIpLinesForLocatorProduct(
      locator: locator,
      product: product,
      dateFrom: dateFrom,
      dateTo: dateTo,
    ),
    findMInOutIpLinesForLocatorProduct(
      locator: locator,
      product: product,
      dateFrom: dateFrom,
      dateTo: dateTo,
    ),
  ]);

  final combined = <LocatorIpLine>[...results[0], ...results[1]];
  combined.sort((a, b) {
    final ad = a.movementDate;
    final bd = b.movementDate;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return bd.compareTo(ad);
  });
  return combined;
}
