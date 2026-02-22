

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/auth/presentation/providers/auth_provider.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_business_partner.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_sales_order_line.dart';

import '../../../config/http/dio_client.dart';
import '../../../config/theme/app_theme.dart';
import '../../m_inout/domain/entities/m_in_out.dart';
import '../../products/common/time_utils.dart';
import '../../products/common/widget/date_range_filter_row_panel.dart';
import '../../products/domain/idempiere/response_async_value.dart';
import '../../products/domain/idempiere/sales_order_and_lines.dart';
import '../../products/domain/models/idempiere_query_page_utils.dart';
import '../../shared/data/memory.dart';
import '../../shared/data/messages.dart';

final selectedSalesOrderDatesProvider = StateProvider<DateTimeRange>((ref) {
  return DateTimeRange(start: initialBusinessDate(), end: DateTime.now());
});
final selectedSalesOrderWorkingStateProvider  = StateProvider<String>((ref) {
  return DateRangeFilterRowPanel.TO_DO;
});

final selectDatesToFindSalesOrderProvider  = StateProvider.autoDispose<DateTimeRange?>((ref) {
  return null;
});

final selectedDocumentStatusToFindSalesOrderProvider  = StateProvider.autoDispose<String>((ref) {
  return 'CO';
});

final salesOrderTotalRecordsProvider = StateProvider<int>((ref) => 0);
final salesOrderExtractedRecordsProvider = StateProvider<int>((ref) => 0);
final salesOrderProgressColorProvider =
StateProvider.autoDispose<Color>((ref) => themeColorPrimary);


final salesOrderProgressProvider =
StateProvider.autoDispose<double>((ref) => 0.0);

String get allString =>'ALL';
final salesOrderBusinessPartnerProvider =
StateProvider.autoDispose<IdempiereBusinessPartner>((ref) => IdempiereBusinessPartner(
  name: allString,
  id: Memory.INITIAL_STATE_ID,
));



int? normalizeId(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

List<List<int>> chunkIds(List<int> ids, int chunkSize) {
  final List<List<int>> chunks = [];
  for (int i = 0; i < ids.length; i += chunkSize) {
    final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
    chunks.add(ids.sublist(i, end));
  }
  return chunks;
}
const int progressSteps = 20;
double progressFromCounts({
  required int extracted,
  required int total,
}) {
  if (total <= 0) return 0.0;

  final ratio = extracted / total;        // 0..1 real
  final stepped =
      (ratio * progressSteps).floor() / progressSteps;

  return stepped.clamp(0.0, 1.0);
}

void updateProgressFromCounters(Ref ref) {
  final total = ref.read(salesOrderTotalRecordsProvider);
  final extracted = ref.read(salesOrderExtractedRecordsProvider);

  final p = progressFromCounts(
    extracted: extracted,
    total: total,
  );

  ref.read(salesOrderProgressProvider.notifier).state = p;
}

final findSalesOrderToProcessByDateProvider =
FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  // ================= RESET =================
  ref.read(salesOrderProgressProvider.notifier).state = 0.0;
  ref.read(salesOrderTotalRecordsProvider.notifier).state = 0;
  ref.read(salesOrderExtractedRecordsProvider.notifier).state = 0;

  final DateTimeRange? dates =
  ref.watch(selectDatesToFindSalesOrderProvider);

  final response = ResponseAsyncValue();
  if (dates == null) return response;

  response.isInitiated = true;

  final dio = await DioClient.create();
  final docStatus =
  ref.read(selectedDocumentStatusToFindSalesOrderProvider);

  final startDate = dates.start.toString().substring(0, 10);
  final endDate   = dates.end.toString().substring(0, 10);
  final warehouse = ref.read(authProvider).selectedWarehouse?.id ?? 0;

  try {
    // =========================================================
    // 1) SALES ORDERS
    // =========================================================
    final orders = await fetchAllPages<SalesOrderAndLines>(
      dio: dio,
      baseUrl:
      "/api/v1/models/c_order?\$filter="
          "DocStatus eq '$docStatus' "
          "AND DateOrdered ge '$startDate' "
          "AND DateOrdered le '$endDate' "
          "AND (M_Warehouse_ID eq $warehouse)",
      filterSuffix: "",
      parser: SalesOrderAndLines.fromJson,
      orderByColumn: 'C_Order_ID',
    );

    // ---- sin resultados ----
    if (orders.isEmpty) {
      response.success = true;
      response.data = <SalesOrderAndLines>[];

      // mostrar avance mínimo (5%)
      ref.read(salesOrderProgressProvider.notifier).state = 0.05;

      return response;
    }
    // inicializar contenedores
    for (final o in orders) {
      o.salesOrderLines ??= <IdempiereSalesOrderLine>[];
      o.mInOutsInProgress ??= <MInOut>[];
    }

    response.data = orders;
    response.success = true;

    // =========================================================
    // 2) PREPARAR BLOQUES (10 BLOQUES FIJOS)
    // =========================================================
    final orderIds = orders
        .map((e) => normalizeId(e.id))
        .whereType<int>()
        .toList();

    /*final int blockSize =
    (orderIds.length / 10).ceil().clamp(1, orderIds.length);*/
    final int blockSize = 10;
    final blocks = chunkIds(orderIds, blockSize);
    // =========================================================
    // 3) TOTAL GLOBAL (ORDERS + LINES + INOUTS)
    // =========================================================
    int totalRecords = orders.length;
    int extractedRecords = 0;

    ref.read(salesOrderTotalRecordsProvider.notifier).state = totalRecords;
    ref.read(salesOrderExtractedRecordsProvider.notifier).state =
        extractedRecords;

    updateProgressFromCounters(ref);

    final orderById = {
      for (final o in orders)
        if (normalizeId(o.id) != null) normalizeId(o.id)!: o
    };

    // =========================================================
    // 4) POR BLOQUE: LINES + INOUT
    // =========================================================
    for (final block in blocks) {
    //for (final block in orders) {
      if (!ref.mounted) break;
      for (final oid in block) {
        orderById[oid]?.salesOrderLines = <IdempiereSalesOrderLine>[];
        orderById[oid]?.mInOutsInProgress = <MInOut>[];
      }
      final inList = block.join(',');
      //final inList = block.id ?? 0;

      // ---------- ORDER LINES ----------
      final lines = await fetchAllPages<IdempiereSalesOrderLine>(
        dio: dio,
        baseUrl:
        "/api/v1/models/c_orderline?\$filter="
            "C_Order_ID in ($inList)",
        filterSuffix: "",
        parser: IdempiereSalesOrderLine.fromJson,
        orderByColumn: 'C_OrderLine_ID',
      );
      //block.salesOrderLines = lines ;
      for (final l in lines) {
        final oid = normalizeId(l.cOrderID?.id);
        if (oid != null) {
          orderById[oid]?.salesOrderLines?.add(l);
        }
      }

      // ---------- M_INOUT ----------
      final inouts = await fetchAllPages<MInOut>(
        dio: dio,
        baseUrl:
        "/api/v1/models/m_inout?\$filter="
            "C_Order_ID in ($inList) "
            "AND (DocStatus eq 'DR' OR DocStatus eq 'IP')",
        filterSuffix: "",
        parser: MInOut.fromJson,
        orderByColumn: 'M_InOut_ID',
      );
      //block.mInOutsInProgress = inouts ;
      for (final m in inouts) {
        final oid = normalizeId(m.cOrderId.id);
        if (oid != null) {
          orderById[oid]?.mInOutsInProgress?.add(m);
        }
      }

      extractedRecords += block.length;
      //extractedRecords += 1;
      ref.read(salesOrderExtractedRecordsProvider.notifier).state =
          extractedRecords;
      updateProgressFromCounters(ref);
    }

    // =========================================================
    // 5) FINAL
    // =========================================================
    ref.read(salesOrderProgressProvider.notifier).state = 1.0;
    return response;
  } catch (e) {
    response.success = false;
    response.message = Messages.ERROR + e.toString();
    ref.read(salesOrderProgressProvider.notifier).state = 1.0;
    return response;
  }
});

Future<void> runWithConcurrencyLimit<T>({
  required List<T> items,
  required int limit,
  required Future<void> Function(T item) task,
}) async {
  if (items.isEmpty) return;
  if (limit <= 0) limit = 1;

  int index = 0;

  Future<void> worker() async {
    while (true) {
      final int currentIndex = index;
      if (currentIndex >= items.length) return;
      index = currentIndex + 1;

      await task(items[currentIndex]);
    }
  }

  final int workersCount = items.length < limit ? items.length : limit;
  final workers = List.generate(workersCount, (_) => worker());

  await Future.wait(workers);
}


final selectedSalesOrdersProvider =
StateProvider<List<SalesOrderAndLines>>((ref) => []);


enum SalesOrderAction {
  createShipping,
}
String actionLabel(SalesOrderAction action) {
  switch (action) {
    case SalesOrderAction.createShipping:
      return Messages.CREATE_SHIPPING;

  }
}
