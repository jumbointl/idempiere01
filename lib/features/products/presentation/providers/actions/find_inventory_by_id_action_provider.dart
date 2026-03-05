import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../config/http/dio_client.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../../shared/domain/entities/response_api.dart';
import '../../../domain/idempiere/idempiere_inventory.dart';
import '../../../domain/idempiere/idempiere_inventory_line.dart';
import '../../../domain/idempiere/inventory_and_lines.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../../domain/models/idempiere_query_page_utils.dart';
import '../../screens/store_on_hand/memory_products.dart';
import '../common_provider.dart';

final fireFindInventoryByIdProvider = StateProvider<int>((ref) {
  return 0;
});

final newScannedInventoryIdForSearchProvider = StateProvider<String>((ref) {
  return '';
});

final inventoryAndLinesProvider = StateProvider<InventoryAndLines>((ref) {
  return InventoryAndLines();
});

final newFindInventoryByIdOrDocumentNOProvider =
FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();
  final int count = ref.watch(fireFindInventoryByIdProvider);

  if (count == 0) {
    MemoryProducts.inventoryAndLines?.clearData();
    responseAsyncValue.data = MemoryProducts.inventoryAndLines;
    return responseAsyncValue;
  }

  final String scannedCode =
  ref.read(newScannedInventoryIdForSearchProvider).toUpperCase();

  if (scannedCode.isEmpty) {
    MemoryProducts.inventoryAndLines?.clearData();
    responseAsyncValue.data = MemoryProducts.inventoryAndLines;
    return responseAsyncValue;
  }

  responseAsyncValue.isInitiated = true;

  const String idempiereModelName = 'm_inventory';
  final Dio dio = await DioClient.create();

  try {
    String url = "/api/v1/models/$idempiereModelName";
    final int? aux = int.tryParse(scannedCode);

    if (aux == null || scannedCode.startsWith('0')) {
      url = "/api/v1/models/$idempiereModelName?\$filter=DocumentNo eq '$scannedCode'";
    } else {
      url = "/api/v1/models/$idempiereModelName?\$filter=M_Inventory_ID eq $scannedCode";
    }
    debugPrint('url: $url');

    url = url.replaceAll(' ', '%20');
    debugPrint('url: $url');

    final response = await dio.get(url);

    if (response.statusCode == 200) {
      responseAsyncValue.success = true;

      final responseApi = ResponseApi<IdempiereInventory>.fromJson(
        response.data,
        IdempiereInventory.fromJson,
      );

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final inventory = responseApi.records!.first;

        if (inventory.id == null ||
            inventory.id == Memory.INITIAL_STATE_ID ||
            inventory.id! <= 0) {
          responseAsyncValue.data = null;
          return responseAsyncValue;
        }

        MemoryProducts.inventoryAndLines ??= InventoryAndLines();
        MemoryProducts.inventoryAndLines!.clearData();
        MemoryProducts.inventoryAndLines!.cloneInventory(inventory);
        const String searchField = 'M_Inventory_ID';
        const String inventoryLineModelName = 'm_inventoryline';

        final meta = PaginationMeta();
        final dataList = await fetchAllPages<IdempiereInventoryLine>(
          dio: dio,
          baseUrl: "/api/v1/models/$inventoryLineModelName?\$expand=M_Product_ID",
          filterSuffix: "&\$filter=$searchField eq ${inventory.id!}",
          orderByColumn: "Line",
          parser: (json) => IdempiereInventoryLine.fromJson(json),
          outMeta: meta,
        );

        MemoryProducts.inventoryAndLines?.inventoryLines = dataList;
      }
      ref.read(inventoryAndLinesProvider.notifier).state = MemoryProducts.inventoryAndLines!;
      ref.read(showBottomBarProvider.notifier).state = MemoryProducts.inventoryAndLines!.canCompleteInventory;
      responseAsyncValue.data = MemoryProducts.inventoryAndLines;
    } else {
      responseAsyncValue.success = false;
      responseAsyncValue.message =
      '${Messages.VALUE} : $scannedCode : ${response.statusCode} ${response.statusMessage ?? ''}';
      responseAsyncValue.data = null;
    }

    //ref.invalidate(inventoryAndLinesProvider);
    return responseAsyncValue;
  } on DioException {
    responseAsyncValue.success = false;
    responseAsyncValue.message =
    '${Messages.VALUE} : $scannedCode : ${Messages.ERROR} DioException';
    responseAsyncValue.data = null;
    ref.invalidate(inventoryAndLinesProvider);
    return responseAsyncValue;
  } catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.message =
    '${Messages.VALUE} : $scannedCode : ${Messages.ERROR}${e.toString()}';
    responseAsyncValue.data = null;
    ref.invalidate(inventoryAndLinesProvider);
    return responseAsyncValue;
  }
});

