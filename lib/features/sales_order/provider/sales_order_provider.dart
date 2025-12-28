

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


/*final findSalesOrderToProcessByDateProvider =
FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  // reset progress
  ref.read(salesOrderProgressProvider.notifier).state = 0.0;

  final DateTimeRange? dates = ref.watch(selectDatesToFindSalesOrderProvider);
  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();
  if (dates == null) return responseAsyncValue;

  responseAsyncValue.isInitiated = true;

  final String docStatus =
  ref.read(selectedDocumentStatusToFindSalesOrderProvider);

  final String endDate = dates.end.toString().substring(0, 10);
  final String startDate = dates.start.toString().substring(0, 10);

  final int warehouse = ref.read(authProvider).selectedWarehouse?.id ?? 0;

  final Dio dio = await DioClient.create();

  // ===========================
  // Progress dinámico por páginas
  // ===========================
  int doneSteps = 0;
  int totalSteps = 1; // evitar división por 0

  void addExpectedSteps(int steps) {
    totalSteps += steps;
    if (totalSteps < 1) totalSteps = 1;
  }

  void bumpProgress() {
    doneSteps++;
    if (ref.mounted) {
      final p = doneSteps / totalSteps;
      ref.read(salesOrderProgressProvider.notifier).state =
          p.clamp(0.0, 1.0);
    }
  }

  try {
    // =========================================================
    // 1) Traer Orders (c_order) CON PAGINACIÓN
    // =========================================================
    final List<SalesOrderAndLines> m = [];

    int totalRecords = 0;
    int totalPages = 0;
    int recordsSize = 100; // default
    int skipRecords = 0;

    bool firstOrdersPage = true;

    while (true) {
      if (!ref.mounted) break;

      String url =
          "/api/v1/models/c_order?"
          "\$filter=DocStatus eq '$docStatus' "
          "AND DateOrdered ge $startDate AND DateOrdered le $endDate "
          "AND (M_Warehouse_ID eq $warehouse)"
          "&\$orderby=DateOrdered"
          "&\$top=$recordsSize"
          "&\$skip=$skipRecords";

      url = url.replaceAll(' ', '%20');

      final response = await dio.get(url);

      if (response.statusCode != 200) {
        responseAsyncValue.success = true;
        responseAsyncValue.data = [
          SalesOrderAndLines(name: Messages.ERROR, id: response.statusCode)
        ];
        ref.read(salesOrderProgressProvider.notifier).state = 1.0;
        return responseAsyncValue;
      }
      ref.read(salesOrderProgressColorProvider.notifier).state = Colors.cyan.shade200;
      responseAsyncValue.success = true;

      final responseApi = ResponseApi<SalesOrderAndLines>.fromJson(
        response.data,
        SalesOrderAndLines.fromJson,
      );

      // ✅ Variables pedidas (orders)
      totalRecords = responseApi.rowCount ?? 0;
      totalPages = responseApi.pageCount ?? 0;
      recordsSize = responseApi.recordsSize ?? recordsSize;
      skipRecords = responseApi.skipRecords ?? skipRecords;

      // sumar “pasos esperados” una sola vez (cuando ya sabemos pageCount)
      if (firstOrdersPage) {
        firstOrdersPage = false;
        // totalPages puede venir 0 cuando totalRecords=0
        addExpectedSteps(totalPages > 0 ? totalPages : 1);
      }

      final pageRecords = responseApi.records ?? <SalesOrderAndLines>[];
      if (pageRecords.isNotEmpty) {
        m.addAll(pageRecords);
      }

      // progreso por página completada
      bumpProgress();

      // condición fin:
      // si no hay más registros o ya cubrimos todos
      if (m.length >= totalRecords || pageRecords.isEmpty) {
        break;
      }

      // avanzar skip: siguiente página
      skipRecords += recordsSize;
    }

    if (m.isEmpty) {
      *//*final noData = [
        SalesOrderAndLines(name: Messages.NO_DATA_FOUND, id: Memory.NOT_FOUND_ID)
      ];*//*
      responseAsyncValue.success = true;
      responseAsyncValue.data = <SalesOrderAndLines>[];
      ref.read(salesOrderProgressProvider.notifier).state = 1.0;
      return responseAsyncValue;
    }

    responseAsyncValue.data = m;

    // =========================================================
    // 2) Index por id + inicializar listas
    // =========================================================
    final Map<int, SalesOrderAndLines> orderById = {};
    final List<int> orderIds = [];

    for (final o in m) {
      final int? id = normalizeId(o.id);
      if (id != null && id > 0) {
        orderById[id] = o;
        orderIds.add(id);
      }
      o.salesOrderLines ??= <IdempiereSalesOrderLine>[];
      o.mInOutsInProgress ??= <MInOut>[];
    }

    if (orderIds.isEmpty) {
      ref.read(salesOrderProgressProvider.notifier).state = 1.0;
      return responseAsyncValue;
    }

    // =========================================================
    // 3) Chunking para IN(...)
    //    OJO: esto NO es paginación, es límite de URL
    // =========================================================
    final int inChunkSize = recordsSize; // ajusta según tu backend
    final chunks = chunkIds(orderIds, inChunkSize);

    // =========================================================
    // 4) Batch OrderLines (c_orderline) CON PAGINACIÓN por chunk
    // =========================================================
    for (final chunk in chunks) {
      if (!ref.mounted) break;

      final inList = chunk.join(',');

      int totalRecords2 = 0;
      int totalPages2 = 0;
      int recordsSize2 = 100;
      int skipRecords2 = 0;

      bool firstPageLines = true;

      while (true) {
        if (!ref.mounted) break;

        String url2 =
            "/api/v1/models/c_orderline?"
            "\$filter=C_Order_ID in ($inList)"
            "&\$top=$recordsSize2"
            "&\$skip=$skipRecords2";
        url2 = url2.replaceAll(' ', '%20');

        try {
          final response2 = await dio.get(url2);
          if (response2.statusCode == 200) {
            final responseApi2 = ResponseApi<IdempiereSalesOrderLine>.fromJson(
              response2.data,
              IdempiereSalesOrderLine.fromJson,
            );

            // ✅ Variables pedidas (lines)
            totalRecords2 = responseApi2.rowCount ?? 0;
            totalPages2 = responseApi2.pageCount ?? 0;
            recordsSize2 = responseApi2.recordsSize ?? recordsSize2;
            skipRecords2 = responseApi2.skipRecords ?? skipRecords2;

            if (firstPageLines) {
              firstPageLines = false;
              addExpectedSteps(totalPages2 > 0 ? totalPages2 : 1);
            }

            final lines = responseApi2.records ?? <IdempiereSalesOrderLine>[];
            for (final line in lines) {
              final int? orderId = normalizeId(line.cOrderID?.id);
              if (orderId == null) continue;
              final order = orderById[orderId];
              if (order != null) {
                order.salesOrderLines!.add(line);
              }
            }

            bumpProgress();

            if (lines.isEmpty) break;
            // fin si ya cubrimos todo
            // (si rowCount viene 0 o cambia raro, el lines.isEmpty nos protege)
            if ((skipRecords2 + recordsSize2) >= totalRecords2) break;

            skipRecords2 += recordsSize2;
          } else {
            // si falla, rompemos paginación del chunk
            bumpProgress();
            break;
          }
        } catch (_) {
          bumpProgress();
          break;
        }
      }
    }
    ref.read(salesOrderProgressColorProvider.notifier).state = Colors.green.shade800;
    // =========================================================
    // 5) Batch MInOut (m_inout) CON PAGINACIÓN por chunk
    // =========================================================
    for (final chunk in chunks) {
      if (!ref.mounted) break;

      final inList = chunk.join(',');

      int totalRecords3 = 0;
      int totalPages3 = 0;
      int recordsSize3 = 100;
      int skipRecords3 = 0;

      bool firstPageInOut = true;

      while (true) {
        if (!ref.mounted) break;

        String url3 =
            "/api/v1/models/m_inout?"
            "\$filter=C_Order_ID in ($inList) "
            "AND (DocStatus eq 'DR' OR DocStatus eq 'IP')"
            "&\$top=$recordsSize3"
            "&\$skip=$skipRecords3";
        url3 = url3.replaceAll(' ', '%20');

        try {
          final response3 = await dio.get(url3);
          if (response3.statusCode == 200) {
            final responseApi3 = ResponseApi<MInOut>.fromJson(
              response3.data,
              MInOut.fromJson,
            );

            // ✅ Variables pedidas (inout)
            totalRecords3 = responseApi3.rowCount ?? 0;
            totalPages3 = responseApi3.pageCount ?? 0;
            recordsSize3 = responseApi3.recordsSize ?? recordsSize3;
            skipRecords3 = responseApi3.skipRecords ?? skipRecords3;

            if (firstPageInOut) {
              firstPageInOut = false;
              addExpectedSteps(totalPages3 > 0 ? totalPages3 : 1);
            }

            final inouts = responseApi3.records ?? <MInOut>[];
            for (final inout in inouts) {
              final int? orderId = normalizeId(inout.cOrderId.id);
              if (orderId == null) continue;

              final order = orderById[orderId];
              if (order != null) {
                order.mInOutsInProgress!.add(inout);
              }
            }

            bumpProgress();

            if (inouts.isEmpty) break;
            if ((skipRecords3 + recordsSize3) >= totalRecords3) break;

            skipRecords3 += recordsSize3;
          } else {
            bumpProgress();
            break;
          }
        } catch (_) {
          bumpProgress();
          break;
        }
      }
    }

    // 100%
    if (ref.mounted) {
      ref.read(salesOrderProgressProvider.notifier).state = 1.0;
    }
    return responseAsyncValue;
  } on DioException {
    responseAsyncValue.success = false;
    responseAsyncValue.message = '${Messages.ERROR} DioException';
    ref.read(salesOrderProgressProvider.notifier).state = 1.0;
    return responseAsyncValue;
  } catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.message = Messages.ERROR + e.toString();
    ref.read(salesOrderProgressProvider.notifier).state = 1.0;
    return responseAsyncValue;
  }
});*/


/*final findSalesOrderToProcessByDateProvider = FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final DateTimeRange? dates = ref.watch(selectDatesToFindSalesOrderProvider);
  print('----------------------------------findSalesOrderToProcessByDateProvider');
  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();
  if(dates == null) return responseAsyncValue;

  responseAsyncValue.isInitiated = true;
  String docStatus = ref.read(selectedDocumentStatusToFindSalesOrderProvider) ;
  String endDate = dates.end.toString().substring(0,10);
  String startDate = dates.start.toString().substring(0,10);
  int warehouse = ref.read(authProvider).selectedWarehouse?.id ?? 0;
  String idempiereModelName ='c_order';
  Dio dio = await DioClient.create();
  try {
    String url =  "/api/v1/models/$idempiereModelName";
    url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' "
        "AND DateOrdered ge $startDate AND DateOrdered le $endDate AND (M_Warehouse_ID eq $warehouse)&\$orderby=DateOrdered";
    //print(url);
    url = url.replaceAll(' ', '%20');
    //print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      responseAsyncValue.success = true;
      final responseApi =
      ResponseApi<SalesOrderAndLines>.fromJson(response.data, SalesOrderAndLines.fromJson);
      late List<SalesOrderAndLines> m;
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        m = responseApi.records!;
        responseAsyncValue.data = m ;
        print('c_order 200 length ${m.length}');
        final int totalTrabajo = m.length;
        int count = 0;
        for (var element in m) {
          if (!ref.mounted) break;
          idempiereModelName ='c_orderline';
          int id = element.id ?? -1;
          url = "/api/v1/models/$idempiereModelName?\$filter=C_Order_ID eq $id";
          //print(url);
          url = url.replaceAll(' ', '%20');
          //print(url);
          final response2 = await dio.get(url);
          if (response2.statusCode == 200) {
            final responseApi2 =
            ResponseApi<IdempiereSalesOrderLine>.fromJson(response2.data, IdempiereSalesOrderLine.fromJson);

            late List<IdempiereSalesOrderLine> l;
            if (responseApi2.records != null && responseApi2.records!.isNotEmpty) {
              print('c_order_line 200 order ${element.id}');
               l = responseApi2.records!;
               element.salesOrderLines = l;
            }
            element.salesOrderLines = l;
          }
          count++;
          ref.read(salesOrderProgressProvider.notifier).state =
              count / totalTrabajo;
        }




      } else {
        m = [SalesOrderAndLines(name: Messages.NO_DATA_FOUND, id: Memory.NOT_FOUND_ID)];
      }
      responseAsyncValue.data = m;
      ref.read(salesOrderProgressProvider.notifier).state = 1.0;
      return responseAsyncValue;


    } else {
      responseAsyncValue.success = true;
      List<SalesOrderAndLines>  m = [SalesOrderAndLines(name: Messages.ERROR, id: response.statusCode)];
      responseAsyncValue.data = m;
      ref.read(salesOrderProgressProvider.notifier).state = 1.0;
      return responseAsyncValue;
    }

  } on DioException {
    responseAsyncValue.success = false;
    responseAsyncValue.message = '${Messages.ERROR} DioException';
    ref.read(salesOrderProgressProvider.notifier).state = 1.0;
    return  responseAsyncValue;

  } catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.message = Messages.ERROR +e.toString();
    ref.read(salesOrderProgressProvider.notifier).state = 1.0;
    return  responseAsyncValue;
  }

});*/

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
  createShippingConfirm,
  createPickConfirm,
  completeShipment,
  cancelOrder,
}
String actionLabel(SalesOrderAction action) {
  switch (action) {
    case SalesOrderAction.createShipping:
      return Messages.CREATE_SHIPPING;
    case SalesOrderAction.createShippingConfirm:
      return Messages.CREATE_SHIPPING_CONFIRM;
    case SalesOrderAction.createPickConfirm:
      return Messages.CREATE_PICK_CONFIRM;
    case SalesOrderAction.cancelOrder:
      return Messages.CANCEL_ORDER;
    case SalesOrderAction.completeShipment:
      return Messages.COMPLETE_SHIPMENT;

  }
}

