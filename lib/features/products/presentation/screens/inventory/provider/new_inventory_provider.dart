import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_inventory.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_inventory_line.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/inventory_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_inventory.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_inventory.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../../../../../../config/http/dio_client.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../../shared/domain/entities/response_api.dart';
import '../../../../domain/idempiere/delete_request.dart';
import '../../../../domain/idempiere/idempiere_response_message.dart';
import '../../../../domain/idempiere/response_async_value.dart';
import '../../../../domain/sql/common_sql_data.dart';
import '../../../../domain/sql/sql_data_inventory_line.dart';
import '../../store_on_hand/memory_products.dart';

final inventoryAndLinesProvider = StateProvider<InventoryAndLines>((ref) {
  return InventoryAndLines(id: Memory.INITIAL_STATE_ID);
});

final fireCreateInventoryProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final inventoryAndLinesCreateProvider =
StateProvider.autoDispose<PutAwayInventory?>((ref) {
  return null;
});

class InventoryCreateAction {
  final Ref ref;

  InventoryCreateAction(this.ref);

  Future<void> setAndFire(PutAwayInventory value) async {
    ref.read(inventoryAndLinesCreateProvider.notifier).state = value;
    final count = ref.read(fireCreateInventoryProvider);
    ref.read(fireCreateInventoryProvider.notifier).state = count + 1;
  }
}

final createInventoryAndLinesActionProvider = Provider<InventoryCreateAction>((ref) {
  return InventoryCreateAction(ref);
});

final newInventoryProvider =
FutureProvider.autoDispose<InventoryAndLines?>((ref) async {
  final count = ref.watch(fireCreateInventoryProvider);
  if (count == 0) return null;

  final PutAwayInventory? data =
  ref.read(inventoryAndLinesCreateProvider);
  if (data ==null) return null;
  final newInventory = data.inventoryToCreate ;

  if (newInventory == null) return null;
  if (data.inventoryLineToCreate == null) return null;

  final dio = await DioClient.create();
  final result = InventoryAndLines(user: Memory.sqlUsersData);

  try {
    final String url = SqlDataInventory(
      id: newInventory.id,
      uid: newInventory.uid,
      aDClientID: newInventory.aDClientID,
      aDOrgID: newInventory.aDOrgID,
      isActive: newInventory.isActive,
      created: newInventory.created,
      createdBy: newInventory.createdBy,
      updated: newInventory.updated,
      updatedBy: newInventory.updatedBy,
      documentNo: newInventory.documentNo,
      description: newInventory.description,
      movementDate: newInventory.movementDate,
      processed: newInventory.processed,
      processing: newInventory.processing,
      mWarehouseID: newInventory.mWarehouseID,
      approvalAmt: newInventory.approvalAmt,
      docStatus: newInventory.docStatus,
      isApproved: newInventory.isApproved,
      cDocTypeID: newInventory.cDocTypeID,
      processedOn: newInventory.processedOn,
      costingMethod: newInventory.costingMethod,
      cCurrencyID: newInventory.cCurrencyID,
      cConversionTypeID: newInventory.cConversionTypeID,
    ).getInsertUrl();

    final payload = SqlDataInventory(
      id: newInventory.id,
      uid: newInventory.uid,
      aDClientID: newInventory.aDClientID,
      aDOrgID: newInventory.aDOrgID,
      isActive: newInventory.isActive,
      created: newInventory.created,
      createdBy: newInventory.createdBy,
      updated: newInventory.updated,
      updatedBy: newInventory.updatedBy,
      documentNo: newInventory.documentNo,
      description: newInventory.description,
      movementDate: newInventory.movementDate,
      processed: newInventory.processed,
      processing: newInventory.processing,
      mWarehouseID: newInventory.mWarehouseID,
      approvalAmt: newInventory.approvalAmt,
      docStatus: newInventory.docStatus,
      isApproved: newInventory.isApproved,
      cDocTypeID: newInventory.cDocTypeID,
      processedOn: newInventory.processedOn,
      costingMethod: newInventory.costingMethod,
      cCurrencyID: newInventory.cCurrencyID,
      cConversionTypeID: newInventory.cConversionTypeID,
    ).getInsertJson(description: newInventory.description);

    final response = await dio.post(url, data: payload);

    if (response.statusCode == 201) {
      final createdInventory = IdempiereInventory.fromJson(response.data);

      if (createdInventory.id != null && createdInventory.id! > 0) {
        result.cloneInventory(createdInventory);

        data.inventoryLineToCreate!.mInventoryID = createdInventory;

        final String lineUrl = data.inventoryLineToCreate!.getInsertUrl();
        final Map<String, dynamic> linePayload =
        data.inventoryLineToCreate!.getInsertJson();

        final responseLine = await dio.post(lineUrl, data: linePayload);

        if (responseLine.statusCode == 201) {
          final createdLine = IdempiereInventoryLine.fromJson(responseLine.data);
          result.inventoryLines = [createdLine];
        }

        return result;
      }
    }

    return result;
  } on DioException {
    return result;
  } catch (_) {
    return result;
  }
});


final inventoryIdForConfirmProvider = StateProvider.autoDispose<int?>((ref) {
  return null;
});

final confirmInventoryProvider =
FutureProvider.autoDispose<InventoryAndLines?>((ref) async {
  final id = ref.watch(inventoryIdForConfirmProvider) ?? -1;
  if (id <= 0) return null;

  final dio = await DioClient.create();

  try {
    SqlDataInventory inventory = SqlDataInventory(id: id);
    Memory.sqlUsersData.copyToSqlData(inventory);

    final url = inventory.getUpdateUrl();
    final response = await dio.put(
      url,
      data: inventory.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS),
    );

    if (response.statusCode == 200) {
      inventory = SqlDataInventory.fromJson(response.data);

      final inventoryAndLines = ref.read(inventoryAndLinesProvider);
      inventoryAndLines.cloneInventory(inventory);

      ref.read(inventoryAndLinesProvider.notifier).state = inventoryAndLines;
      MemoryProducts.inventoryAndLines = inventoryAndLines;

      return inventoryAndLines;
    }

    return InventoryAndLines(
      id: Memory.ERROR_ID,
      name: '${Messages.ERROR}${response.statusCode} : ${response.statusMessage}',
    );
  } on DioException catch (e) {
    final title = e.response?.data['title'] ?? '';
    final status = e.response?.data['status'] ?? '';
    final detail = e.response?.data['detail'] ?? '';

    String message = 'Title : $title\nStatus : $status\nDetail : $detail';
    if (title == '' && detail == '') {
      message = e.toString();
    }

    return InventoryAndLines(
      id: Memory.ERROR_ID,
      name: '${Messages.ERROR} : $message',
    );
  } catch (e) {
    return InventoryAndLines(
      id: Memory.ERROR_ID,
      name: '${Messages.ERROR} ${e.toString()}',
    );
  }
});

final inventoryIdForCancelProvider = StateProvider.autoDispose<int?>((ref) {
  return null;
});

final cancelInventoryProvider =
FutureProvider.autoDispose<InventoryAndLines?>((ref) async {
  final id = ref.watch(inventoryIdForCancelProvider) ?? -1;
  if (id <= 0) return null;

  final dio = await DioClient.create();

  try {
    SqlDataInventory inventory = SqlDataInventory(id: id);
    Memory.sqlUsersData.copyToSqlData(inventory);

    final url = inventory.getUpdateUrl();
    final response = await dio.put(
      url,
      data: inventory.getUpdateDocStatusJson(CommonSqlData.DOC_DELETE_STATUS),
    );

    if (response.statusCode == 200) {
      inventory = SqlDataInventory.fromJson(response.data);

      final inventoryAndLines = ref.read(inventoryAndLinesProvider);
      inventoryAndLines.cloneInventory(inventory);

      ref.read(inventoryAndLinesProvider.notifier).state = inventoryAndLines;
      MemoryProducts.inventoryAndLines = inventoryAndLines;

      return inventoryAndLines;
    }

    return InventoryAndLines(
      id: Memory.ERROR_ID,
      name: '${Messages.ERROR}${response.statusCode} : ${response.statusMessage}',
    );
  } on DioException catch (e) {
    final title = e.response?.data['title'] ?? '';
    final status = e.response?.data['status'] ?? '';
    final detail = e.response?.data['detail'] ?? '';

    String message = 'Title : $title\nStatus : $status\nDetail : $detail';
    if (title == '' && detail == '') {
      message = e.toString();
    }

    return InventoryAndLines(
      id: Memory.ERROR_ID,
      name: '${Messages.ERROR} : $message',
    );
  } catch (e) {
    return InventoryAndLines(
      id: Memory.ERROR_ID,
      name: '${Messages.ERROR} ${e.toString()}',
    );
  }
});

final inventorySearchProgressProvider =
StateProvider.autoDispose<double>((ref) => 0.0);

final inventoryNotCompletedToFindByDateProvider =
StateProvider.autoDispose<InventoryAndLines?>((ref) {
  return null;
});

final findInventoryNotCompletedByDateProvider =
FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final InventoryAndLines? inventory =
  ref.watch(inventoryNotCompletedToFindByDateProvider);

  // Reset progress
  ref.read(inventorySearchProgressProvider.notifier).state = 0.0;

  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();
  if (inventory == null || inventory.filterMovementDateStartAt == null) {
    return responseAsyncValue;
  }

  responseAsyncValue.isInitiated = true;

  final String docStatus = inventory.filterDocumentStatus?.id ?? 'DR';
  final String date = inventory.filterMovementDateStartAt!;

  String endDateClause = '';
  if (inventory.filterMovementDateEndAt != null) {
    endDateClause = "AND MovementDate le '${inventory.filterMovementDateEndAt!}' ";
  }

  const String idempiereModelName = 'm_inventory';
  final Dio dio = await DioClient.create();

  try {
    // English: Build baseUrl without pagination parameters
    int warehouseDefault = Memory.sqlUsersData.mWarehouseID?.id ?? -1;

    String baseUrl = "/api/v1/models/$idempiereModelName";

    if (inventory.mWarehouseID == null) {
      baseUrl =
      "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' "
          "AND MovementDate ge '$date' "
          "$endDateClause"
          "AND M_Warehouse_ID eq $warehouseDefault "
          "&\$orderby=MovementDate desc";
    } else {
      final int warehouse = inventory.mWarehouseID!.id ?? -1;
      baseUrl =
      "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' "
          "AND MovementDate ge '$date' "
          "$endDateClause"
          "AND M_Warehouse_ID eq $warehouse "
          "&\$orderby=MovementDate desc";
    }

    // English: Pagination
    final List<IdempiereInventory> all = [];

    int totalRecords = 0;
    int totalPages = 0;
    int recordsSize = 100;
    int skipRecords = 0;

    bool firstPage = true;

    while (true) {
      if (!ref.mounted) break;

      final String url =
      "$baseUrl&\$top=$recordsSize&\$skip=$skipRecords"
          .replaceAll(' ', '%20');

      final response = await dio.get(url);

      if (response.statusCode != 200) {
        responseAsyncValue.success = true;
        responseAsyncValue.data = [
          IdempiereInventory(
            name: Messages.ERROR,
            id: response.statusCode,
          ),
        ];
        ref.read(inventorySearchProgressProvider.notifier).state = 1.0;
        return responseAsyncValue;
      }

      responseAsyncValue.success = true;

      final responseApi = ResponseApi<IdempiereInventory>.fromJson(
        response.data,
        IdempiereInventory.fromJson,
      );

      totalRecords = responseApi.rowCount ?? 0;
      totalPages = responseApi.pageCount ?? 0;
      recordsSize = responseApi.recordsSize ?? recordsSize;
      skipRecords = responseApi.skipRecords ?? skipRecords;

      final pageRecords = responseApi.records ?? <IdempiereInventory>[];
      if (pageRecords.isNotEmpty) {
        all.addAll(pageRecords);
      }

      if (ref.mounted) {
        if (firstPage) {
          firstPage = false;
        }

        if (totalPages > 0) {
          final currentPage = (skipRecords ~/ recordsSize) + 1;
          final p = currentPage / totalPages;
          ref.read(inventorySearchProgressProvider.notifier).state =
              p.clamp(0.0, 1.0);
        } else {
          final p = (totalRecords > 0) ? (all.length / totalRecords) : 0.0;
          ref.read(inventorySearchProgressProvider.notifier).state =
              p.clamp(0.0, 1.0);
        }
      }

      if (totalRecords == 0) break;
      if (all.length >= totalRecords) break;
      if (pageRecords.isEmpty) break;

      skipRecords += recordsSize;
    }

    if (all.isEmpty) {
      responseAsyncValue.data = [
        IdempiereInventory(
          name: Messages.NO_DATA_FOUND,
          id: Memory.NOT_FOUND_ID,
        ),
      ];
    } else {
      responseAsyncValue.data = all;
    }

    if (ref.mounted) {
      ref.read(inventorySearchProgressProvider.notifier).state = 1.0;
    }

    return responseAsyncValue;
  } on DioException {
    responseAsyncValue.success = false;
    responseAsyncValue.message = '${Messages.ERROR} DioException';
    ref.read(inventorySearchProgressProvider.notifier).state = 1.0;
    return responseAsyncValue;
  } catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.message = Messages.ERROR + e.toString();
    ref.read(inventorySearchProgressProvider.notifier).state = 1.0;
    return responseAsyncValue;
  }
});







final inventoryLineQuantityToCountProvider =
StateProvider.autoDispose.family<double?, int>((ref, lineId) {
  return null;
});

final editingInventoryLineProvider =
StateProvider.autoDispose.family<bool, int>((ref, lineId) {
  return false;
});

final quantityOfInventoryLineToEditProvider =
StateProvider.autoDispose<List<dynamic>?>((ref) {
  return [];
});

final updateInventoryLineIdProvider =
StateProvider.autoDispose<int?>((ref) => null);

final deleteInventoryRequestProvider =
StateProvider.autoDispose<DeleteRequest?>((ref) => null);

final inventoryLineDeletedCounterProvider = StateProvider<int>((ref) {
  return 0;
});

final deleteInventoryLineProvider =
FutureProvider.autoDispose.family<bool, DeleteRequest>((ref, request) async {
  if (request.lineId <= 0) return false;
  final dio = await DioClient.create();

  try {
    // English: Delete inventory line first.
    final line = SqlDataInventoryLine(id: request.lineId);
    Memory.sqlUsersData.copyToSqlData(line);

    final urlLine = line.getUpdateUrl();
    final respLine = await dio.delete(urlLine);

    if (respLine.statusCode != 200) return false;

    final resLine = IdempiereResponseMessage.fromJson(respLine.data);

    if (resLine.deleted != true) return false;

    // English: If headerIdToDelete is provided, delete/cancel header too.
    final headerId = request.headerIdToDelete ?? -1;
    if (headerId > 0) {
      final inventory = SqlDataInventory(id: headerId);
      Memory.sqlUsersData.copyToSqlData(inventory);

      final urlHeader = inventory.getUpdateUrl();
      final payload =
      inventory.getUpdateDocStatusJson(CommonSqlData.DOC_DELETE_STATUS);

      final respHeader = await dio.put(urlHeader, data: payload);
      if (respHeader.statusCode != 200) return false;

      final resHeader = IdempiereResponseMessage.fromJson(respHeader.data);
      if (resHeader.deleted != true) return false;
    }

    // English: Update local state.
    final current = ref.read(inventoryAndLinesProvider);
    final newLines =
    List<IdempiereInventoryLine>.from(current.inventoryLines ?? const []);
    newLines.removeWhere((e) => (e.id ?? -1) == request.lineId);
    current.inventoryLines = newLines;
    ref.read(inventoryAndLinesProvider.notifier).state = current;

    return true;
  } on DioException {
    return false;
  } catch (_) {
    return false;
  } finally {
    ref.read(deleteInventoryRequestProvider.notifier).state = null;
  }
});

final editInventoryLineQuantityProvider =
FutureProvider.autoDispose.family<double?, int>((ref, lineId) async {
  final data = ref.watch(quantityOfInventoryLineToEditProvider);

  if (data == null || data.length != 2) return null;

  final int id = (data[0] as num).toInt();
  final double qty = (data[1] as num).toDouble();

  if (id != lineId) return null;

  // English: Inventory allows zero, only negative is invalid.
  if (id <= 0 || qty < 0) return null;

  final dio = await DioClient.create();

  try {
    final inventoryLine = SqlDataInventoryLine(id: id, qtyCount: qty);
    Memory.sqlUsersData.copyToSqlData(inventoryLine);

    final url = inventoryLine.getUpdateUrl();
    final response = await dio.put(
      url,
      data: inventoryLine.getUpdateQtyCountJson(),
    );

    if (response.statusCode == 200) {
      final res = IdempiereInventoryLine.fromJson(response.data);
      return res.qtyCount;
    }

    return -1;
  } on DioException {
    return -2;
  } catch (_) {
    return -3;
  } finally {}
});