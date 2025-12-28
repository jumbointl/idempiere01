import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/sales_order_and_lines.dart';

import '../../../shared/data/memory.dart';
import '../../../shared/domain/entities/response_api.dart';

/// Resultado de paginación por si quieres exponer metadatos
class PaginationMeta {
  int totalRecords;
  int totalPages;
  final int recordsSize = Memory.IDEMPIERE_DEFAULT_PAGE_SIZE;
  int skipRecords;

  PaginationMeta({
    this.totalRecords = 0,
    this.totalPages = 0,
    this.skipRecords = 0,
  });
}

/// Trae todas las páginas de un endpoint OData-like usando top/skip.
/// - baseUrl: la parte fija hasta "...?$filter=...".
/// - filterSuffix: cualquier extra que quieras agregar (ej: fechas) ya con %20 si corresponde.
/// - parser: fromJson del modelo (ej: MInOut.fromJson)
Future<List<T>> fetchAllPages<T>({
  required Dio dio,
  required String baseUrl,
  required String filterSuffix,
  required String orderByColumn,
  required T Function(Map<String, dynamic>) parser,
  PaginationMeta? outMeta,
}) async {
  final List<T> all = [];

  int recordsSize = Memory.IDEMPIERE_DEFAULT_PAGE_SIZE;
  int skip = 0;
  int totalRecords = 0;
  int totalPages = 0;
  int skipRecords = 0;

  while (true) {

    String url = "$baseUrl&\$orderby=$orderByColumn&\$top=$recordsSize&\$skip=$skip";
    url = "$url $filterSuffix".trim();
    if(skip == 0){
      print(url);
    }

    url = url.replaceAll(' ', '%20');
    if(skip>0) print(url);
    final response = await dio.get(url);
    if (response.statusCode != 200) {
      throw Exception("Error HTTP ${response.statusCode} en paginación");
    }

    final responseApi = ResponseApi<T>.fromJson(response.data, parser);

    totalRecords = responseApi.rowCount ?? totalRecords;
    totalPages   = responseApi.pageCount ?? totalPages;
    recordsSize  = responseApi.recordsSize ?? recordsSize;
    skipRecords  = responseApi.skipRecords ?? skipRecords;

    final records = responseApi.records ?? <T>[];
    if (records.isEmpty) break;

    all.addAll(records);

    // 🔹 avanzar skip con lo que REALMENTE trajiste
    skip += records.length;

    // 🔹 corte seguro
    if (totalRecords > 0 && skip >= totalRecords) {
      break;
    }

    // fallback si backend no envía rowCount
    if (responseApi.rowCount == null && records.length < recordsSize) {
      break;
    }
  }

  if (outMeta != null) {
    outMeta.totalRecords = totalRecords;
    outMeta.totalPages = totalPages;
    outMeta.skipRecords = skipRecords;
  }
  return all;
}


String buildMovementDateFilterSuffix(DateTimeRange<DateTime> dates) {
  String filterEndDate = '';
  String endDate = dates.end.toString().substring(0, 10);
  if (endDate.isNotEmpty) {
    filterEndDate = " AND MovementDate le '$endDate' ";
  }

  String filterStartDate = '';
  String startDate = dates.start.toString().substring(0, 10);
  if (startDate.isNotEmpty) {
    filterStartDate = " AND MovementDate ge '$startDate' ";
  }

  return '$filterStartDate$filterEndDate';
}
Future<List<T>> fetchAllPagesWithProgressValues<T>({
  required Dio dio,
  required String baseUrl,
  required String orderByColumn,
  required String filterSuffix,
  required T Function(Map<String, dynamic>) parser,
  PaginationMeta? outMeta,

  // progress (opcionales)
  Ref? ref,
  StateProvider<double>? progressProvider,
  StateProvider<Color>? progressColorProvider,
  Color loadingColor = Colors.cyan,
  Color doneColor = Colors.green,

  // counts (opcionales)
  StateProvider<int>? totalRecordsProvider,
  StateProvider<int>? extractedRecordsProvider,
  void Function(int extractedSoFar)? onExtractedCount,
}) async {
  final List<T> all = [];
  int recordsSize = Memory.IDEMPIERE_DEFAULT_PAGE_SIZE;
  int skip = 0;

  int totalRecords = 0;
  int totalPages = 0;

  int currentPage = 0;
  bool firstPage = true;

  while (true) {
    if (ref != null && !ref.mounted) break;

    String url = "$baseUrl&\$orderby=$orderByColumn&\$top=$recordsSize&\$skip=$skip";
    url = "$url $filterSuffix".trim();
    print(url);
    url = url.replaceAll(' ', '%20');

    final response = await dio.get(url);
    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}");
    }

    final responseApi = ResponseApi<T>.fromJson(response.data, parser);

    totalRecords = responseApi.rowCount ?? totalRecords;
    totalPages = responseApi.pageCount ?? totalPages;
    recordsSize = responseApi.recordsSize ?? recordsSize;

    // set totalRecords apenas lo sepamos
    if (ref != null && totalRecordsProvider != null && totalRecords > 0) {
      ref
          .read(totalRecordsProvider.notifier)
          .state = totalRecords;
    }

    final records = responseApi.records ?? <T>[];
    if (records.isEmpty) break;
    for (int i = 0; i < records.length; i++) {
      if(records[i]!=null &&  records[i] is SalesOrderAndLines){
        SalesOrderAndLines salesOrderAndLines = records[i] as SalesOrderAndLines;
        print('${i+1} : ${salesOrderAndLines.id ??  'null'}');
      } else {
        print('${i+1} : ${records[i] ??  'null'}');
      }

    }


    all.addAll(records);

    // primera vez: color loading
    if (firstPage) {
      firstPage = false;
      if (ref != null && progressColorProvider != null) {
        ref.read(progressColorProvider.notifier).state = loadingColor;
      }
    }

    currentPage++;

    // extracted count
    if (ref != null && extractedRecordsProvider != null) {
      ref.read(extractedRecordsProvider.notifier).state = all.length;
    }
    onExtractedCount?.call(all.length);

    // progress: preferir páginas si existe pageCount, si no usar extracted/totalRecords
    if (ref != null && progressProvider != null) {
      double p = 0.0;
      if (totalPages > 0) {
        p = currentPage / totalPages;
      } else if (totalRecords > 0) {
        p = all.length / totalRecords;
      }
      ref.read(progressProvider.notifier).state = p.clamp(0.0, 1.0);
    }

    skip += recordsSize;

    if (totalRecords > 0 && skip >= totalRecords) break;
    if (records.length < recordsSize) break;
  }

  // final
  if (ref != null && progressProvider != null) {
    ref.read(progressProvider.notifier).state = 1.0;
  }
  if (ref != null && progressColorProvider != null) {
    ref.read(progressColorProvider.notifier).state = doneColor;
  }

  if (outMeta != null) {
    outMeta.totalRecords = totalRecords;
    outMeta.totalPages   = totalPages;
    outMeta.skipRecords  = skip;
  }

  return all;
}


