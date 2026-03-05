
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/m_inout/presentation/providers/m_in_out_providers.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_response_message.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../../../../../../config/http/dio_client.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../../shared/domain/entities/response_api.dart';
import '../../../../domain/idempiere/delete_request.dart';
import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../../domain/sql/common_sql_data.dart';
import '../../../../domain/sql/sql_data_movement.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/locator_provider.dart';
import '../../store_on_hand/memory_products.dart';

final movementAndLinesProvider = StateProvider<MovementAndLines>((ref) {
  return MovementAndLines(id: Memory.INITIAL_STATE_ID);
});

final documentTypeFilterProvider = StateProvider<String>((ref) {
  return 'DR'; // valor inicial
});
final documentTypeListMInOutFilterProvider = StateProvider<String>((ref) {
  return 'DR'; // valor inicial
});

// Opciones disponibles, fácil de expandir luego
const List<String> documentTypeOptionsAll = ['DR', 'IP', 'CO','VO'];
const List<String> documentTypeOptionsForMovementConfirm = ['DR', 'IP', 'CO'];
const List<String> documentTypeOptionsForInventory = ['DR','CO'];

final copyLastLocatorToProvider = StateProvider<bool>((ref) => true);

final quantityToMoveProvider = StateProvider.autoDispose<double>((ref) {
  return 0;
});

final checkCanInsertMovementProvider = Provider<bool>((ref) {
  final quantity = ref.watch(quantityToMoveProvider);
  final locatorTo = ref.watch(selectedLocatorToProvider);
  return quantity > 0 && locatorTo.id != null && locatorTo.id! > 0;
});
final fireCreateMovementProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final putAwayMovementCreateProvider = StateProvider.autoDispose<PutAwayMovement?>((ref) {
  return null;
});

final newPutAwayMovementProvider = FutureProvider.autoDispose<MovementAndLines?>((ref) async {
  final int count = ref.watch(fireCreateMovementProvider);
  if(count==0) return null;

  PutAwayMovement? newMovement = ref.read(putAwayMovementCreateProvider);
  if(newMovement == null) return null;


  Dio dio = await DioClient.create();
  MemoryProducts.movementAndLines = MovementAndLines(user: Memory.sqlUsersData);

  try {
    String url = newMovement.movementInsertUrl!;
    final response = await dio.post(url, data: newMovement.movementInsertJson);
    if (response.statusCode == 201) {

      IdempiereMovement movement =  IdempiereMovement.fromJson(response.data);
      if (movement.id != null && movement.id! > 0) {
        MemoryProducts.movementAndLines.cloneMovement(movement);
        newMovement.movementLineToCreate!.mMovementID = movement;
        var creteDataJsonEncode2 =  newMovement.movementLineInsertJson! ;
        String url2 = newMovement.movementLineInsertUrl!;
        final responseLine = await dio.post(url2, data: creteDataJsonEncode2);
        if (responseLine.statusCode == 201) {
          final IdempiereMovementLine movementLine =  IdempiereMovementLine.fromJson(responseLine.data);
          MemoryProducts.movementAndLines.movementLines = [movementLine];
        }
        return MemoryProducts.movementAndLines;
      } else {
        return MemoryProducts.movementAndLines;
      }
    } else {
      return MemoryProducts.movementAndLines;
    }
  } on DioException {
    return MemoryProducts.movementAndLines;
  } catch (e) {
    return MemoryProducts.movementAndLines;
  }

});






final movementLineQuantityToMoveProvider =
StateProvider.autoDispose.family<double?, int>((ref, lineId) {
  return null;
});
final editingMovementLineProvider =
StateProvider.autoDispose.family<bool, int>((ref, lineId) {
  return false;
});

final quantityOfLineToEditProvider = StateProvider.autoDispose<List<dynamic>?>((ref) {
  return [];
});
final idOfMovementLineToDeleteProvider = StateProvider.autoDispose<int>((ref) {
  return -1;
});
final counterProvider = StateProvider<int>((ref) {
  return 1;
});
final deleteRequestProvider =
StateProvider.autoDispose<DeleteRequest?>((ref) => null);

final updateMovementLineIdProvider = StateProvider.autoDispose<int?>((ref) => null);
final deleteMovementLineProvider =
FutureProvider.autoDispose.family<bool, DeleteRequest>((ref, request) async {
  if (request.lineId <= 0) return false;
  final dio = await DioClient.create();

  try {
    // =========================
    // 1) BORRAR LINE (DELETE)
    // =========================
    final line = SqlDataMovementLine(id: request.lineId);
    Memory.sqlUsersData.copyToSqlData(line);

    final urlLine = line.getUpdateUrl();
    final respLine = await dio.delete(urlLine);
    int i  = ref.read(counterProvider);
    ref.read(counterProvider.notifier).state = i+1;

    if (respLine.statusCode != 200) return false;
    final resLine = IdempiereResponseMessage.fromJson(respLine.data);
    if (request.headerIdToDelete ==null || request.headerIdToDelete!<=0){
      return resLine.deleted;
    }

    // =========================
    // 2) SI ES ÚLTIMA LINEA: BORRAR MOVEMENT (PUT docStatus=DELETE)
    // =========================
    final movementId = request.headerIdToDelete ?? -1;
    if (movementId > 0) {
      final movement = SqlDataMovement(id: movementId);
      Memory.sqlUsersData.copyToSqlData(movement);

      final urlMov = movement.getUpdateUrl();
      final payload = movement.getUpdateDocStatusJson(CommonSqlData.DOC_DELETE_STATUS);
      final respMov = await dio.put(urlMov, data: payload);
      if (respMov.statusCode != 200) return false;

      final resMov = IdempiereResponseMessage.fromJson(respMov.data);
      return true;
      /*if (resMov.deleted) {
        return true;
      } else {
        return false;
      }*/
    }

    // =========================
    // 3) UPDATE LOCAL STATE (quitar la línea del movementAndLinesProvider)
    // =========================
    final current = ref.read(movementAndLinesProvider);
    final newLines = List<IdempiereMovementLine>.from(current.movementLines ?? const []);
    newLines.removeWhere((e) => (e.id ?? -1) == request.lineId);
    current.movementLines = newLines;
    ref.read(movementAndLinesProvider.notifier).state = current;

    return true;
  } on DioException {
    return false;
  } catch (e) {
    return false;
  } finally {
    // ✅ limpia el trigger sí o sí
    ref.read(deleteRequestProvider.notifier).state = null;
  }
});


final editQuantityToMoveProvider =
FutureProvider.autoDispose.family<double?, int>((ref, lineId) async {
  final ml = ref.watch(quantityOfLineToEditProvider);

  // ✅ Validación fuerte
  if (ml == null || ml.length != 2) return null;

  final int id = (ml[0] as num).toInt();
  final double qty = (ml[1] as num).toDouble();

  // ✅ Solo esta card debe ejecutar su update
  if (id != lineId) return null;

  // reglas de negocio
  if (id <= 0 || qty < 0) return null;

  final dio = await DioClient.create();

  try {
    final movementLine = SqlDataMovementLine(id: id, movementQty: qty);
    Memory.sqlUsersData.copyToSqlData(movementLine);

    final url = movementLine.getUpdateUrl();
    final response = await dio.put(url, data: movementLine.getUpdateMovementQuantityJson());


    if (response.statusCode == 200) {
      final res = IdempiereMovementLine.fromJson(response.data);
      return res.movementQty;
    }

    return -1; // error http
  } on DioException {
    return -2;
  } catch (e) {
    return -3;
  } finally {

  }
});

final movementSearchProgressProvider =
StateProvider.autoDispose<double>((ref) => 0.0);

final movementNotCompletedToFindByDateProvider  = StateProvider.autoDispose<MovementAndLines?>((ref) {
  return null;
});

final findMovementNotCompletedByDateProvider =
FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final MovementAndLines? movement =
  ref.watch(movementNotCompletedToFindByDateProvider);


  // reset progress
  ref.read(movementSearchProgressProvider.notifier).state = 0.0;

  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();
  if (movement == null || movement.filterMovementDateStartAt == null) {
    return responseAsyncValue;
  }

  responseAsyncValue.isInitiated = true;

  final String docStatus = movement.filterDocumentStatus?.id ?? 'DR';
  final String date = movement.filterMovementDateStartAt!;

  String endDateClause = '';
  if (movement.filterMovementDateEndAt != null) {
    endDateClause = "AND MovementDate le ${movement.filterMovementDateEndAt!} ";
  }

  const String idempiereModelName = 'm_movement';
  final Dio dio = await DioClient.create();

  try {
    // ===========================
    // Construir baseUrl (sin top/skip)
    // ===========================
    int warehouseDefault = Memory.sqlUsersData.mWarehouseID?.id ?? -1;

    String baseUrl = "/api/v1/models/$idempiereModelName";

    if (movement.filterWarehouseFrom == null && movement.filterWarehouseTo == null) {
      baseUrl =
      "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' "
          "AND MovementDate ge '$date' "
          "$endDateClause"
          "AND (M_WarehouseTo_ID eq $warehouseDefault OR M_Warehouse_ID eq $warehouseDefault)"
          "&\$orderby=MovementDate desc";
    } else if (movement.filterWarehouseFrom != null && movement.filterWarehouseTo != null) {
      final int warehouse = movement.filterWarehouseFrom!.id!;
      final int warehouseTo = movement.filterWarehouseTo!.id!;
      baseUrl =
      "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' "
          "AND MovementDate ge '$date' "
          "$endDateClause"
          "AND M_WarehouseTo_ID eq $warehouseTo "
          "AND M_Warehouse_ID eq $warehouse"
          "&\$orderby=MovementDate desc";
    } else if (movement.filterWarehouseFrom == null) {
      final int warehouse = movement.filterWarehouseTo!.id!;
      final int warehouseTo = movement.filterWarehouseTo!.id!;
      baseUrl =
      "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' "
          "AND MovementDate ge '$date' "
          "$endDateClause"
          "AND M_WarehouseTo_ID eq $warehouseTo "
          "AND M_Warehouse_ID neq $warehouse"
          "&\$orderby=MovementDate desc";
    } else {
      final int warehouse = movement.filterWarehouseFrom!.id!;
      final int warehouseTo = movement.filterWarehouseFrom!.id!;
      baseUrl =
      "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' "
          "AND MovementDate ge '$date' "
          "$endDateClause"
          "AND M_WarehouseTo_ID neq $warehouseTo "
          "AND M_Warehouse_ID eq $warehouse"
          "&\$orderby=MovementDate desc";
    }

    // ===========================
    // Paginación
    // ===========================
    final List<IdempiereMovement> all = [];

    int totalRecords = 0; // rowCount
    int totalPages = 0;   // pageCount
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
          IdempiereMovement(name: Messages.ERROR, id: response.statusCode)
        ];
        ref.read(movementSearchProgressProvider.notifier).state = 1.0;
        return responseAsyncValue;
      }

      responseAsyncValue.success = true;

      final responseApi = ResponseApi<IdempiereMovement>.fromJson(
        response.data,
        IdempiereMovement.fromJson,
      );

      // ✅ Variables pedidas
      totalRecords = responseApi.rowCount ?? 0;
      totalPages = responseApi.pageCount ?? 0;
      recordsSize = responseApi.recordsSize ?? recordsSize;
      skipRecords = responseApi.skipRecords ?? skipRecords;

      // records de esta página
      final pageRecords = responseApi.records ?? <IdempiereMovement>[];
      if (pageRecords.isNotEmpty) {
        all.addAll(pageRecords);
      }

      // ✅ Progreso:
      // - si ya sabemos totalPages, usamos determinado
      // - si no, dejamos indeterminado (0.0) hasta la 1ª respuesta
      if (ref.mounted) {
        if (firstPage) {
          firstPage = false;
        }

        if (totalPages > 0) {
          // pág actual aproximada (0-based -> 1-based)
          final currentPage = (skipRecords ~/ recordsSize) + 1;
          final p = currentPage / totalPages;
          ref.read(movementSearchProgressProvider.notifier).state =
              p.clamp(0.0, 1.0);
        } else {
          // si API no da pageCount, progreso por items
          final p = (totalRecords > 0) ? (all.length / totalRecords) : 0.0;
          ref.read(movementSearchProgressProvider.notifier).state =
              p.clamp(0.0, 1.0);
        }
      }

      // condición fin
      if (totalRecords == 0) break;
      if (all.length >= totalRecords) break;
      if (pageRecords.isEmpty) break;

      // siguiente página
      skipRecords += recordsSize;
    }

    // Si no hay datos
    if (all.isEmpty) {
      responseAsyncValue.data = [
        IdempiereMovement(name: Messages.NO_DATA_FOUND, id: Memory.NOT_FOUND_ID)
      ];
    } else {
      responseAsyncValue.data = all;
    }

    // 100%
    if (ref.mounted) {
      ref.read(movementSearchProgressProvider.notifier).state = 1.0;
    }
    return responseAsyncValue;
  } on DioException {
    responseAsyncValue.success = false;
    responseAsyncValue.message = '${Messages.ERROR} DioException';
    ref.read(movementSearchProgressProvider.notifier).state = 1.0;
    return responseAsyncValue;
  } catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.message = Messages.ERROR + e.toString();
    ref.read(movementSearchProgressProvider.notifier).state = 1.0;
    return responseAsyncValue;
  }
});

final movementIdForConfirmProvider = StateProvider.autoDispose<int?>((ref) {
  return null;
});
final confirmMovementProvider = FutureProvider.autoDispose<MovementAndLines?>((ref) async {

  int id = ref.watch(movementIdForConfirmProvider) ?? -1;
  if(id <=0) return null;
  Dio dio = await DioClient.create();
  try {
    SqlDataMovement movement = SqlDataMovement(id:id);
    Memory.sqlUsersData.copyToSqlData(movement);
    print(movement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));

    String url =movement.getUpdateUrl();
    print(url);
    final response = await dio.put(url, data: movement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));
    print(response);
    print(response.statusCode);


    if (response.statusCode == 200) {
      movement =  SqlDataMovement.fromJson(response.data);
      MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
      movementAndLines.cloneMovement(movement);
      ref.read(movementAndLinesProvider.notifier).state = movementAndLines;
      MemoryProducts.movementAndLines = movementAndLines ;
      return movementAndLines ;
    } else {
      return MovementAndLines(id: Memory.ERROR_ID,
          name: '${Messages.ERROR }${response.statusCode} : ${response.statusMessage}' );

    }



  } on DioException catch (e) {
    debugPrint('DioException');

    String title = e.response?.data['title'] ?? '';
    int status = e.response?.data['status'] ?? '';
    String detail = e.response?.data['detail'] ?? '';
    String messages ='Title : $title\nStatus : $status\nDetail : $detail';
    if(title=='' && detail==''){
      messages = e.toString();
    }

    return MovementAndLines(id: Memory.ERROR_ID,
        name: '${Messages.ERROR } : $messages' );
  } catch (e) {
    debugPrint('Exception');
    debugPrint(e.toString());

    return MovementAndLines(id: Memory.ERROR_ID,
        name: '${Messages.ERROR } ${e.toString()}' );
  }

});

final movementIdForCancelProvider = StateProvider.autoDispose<int?>((ref) {
  return null;
});
final cancelMovementProvider = FutureProvider.autoDispose<MovementAndLines?>((ref) async {
  int id = ref.watch(movementIdForCancelProvider) ?? -1;
  if(id <=0) return null;
  Dio dio = await DioClient.create();
  try {
    SqlDataMovement movement = SqlDataMovement(id:id);
    Memory.sqlUsersData.copyToSqlData(movement);
    String url =movement.getUpdateUrl();
    Map<String, dynamic> payload = movement.getUpdateDocStatusJson(CommonSqlData.DOC_DELETE_STATUS);
    final response = await dio.put(url, data: payload);

    if (response.statusCode == 200) {
      movement =  SqlDataMovement.fromJson(response.data);

      MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
      movementAndLines.cloneMovement(movement);
      ref.read(movementAndLinesProvider.notifier).state = movementAndLines;
      MemoryProducts.movementAndLines = movementAndLines;
      return movementAndLines;
    } else {
      return MovementAndLines(id: Memory.ERROR_ID,
          name: '${Messages.ERROR }${response.statusCode} : ${response.statusMessage}' );
    }



  } on DioException catch (e) {
    debugPrint('DioException');

    String title = e.response?.data['title'] ?? '';
    int status = e.response?.data['status'] ?? '';
    String detail = e.response?.data['detail'] ?? '';
    String messages ='Title : $title\nStatus : $status\nDetail : $detail';
    if(title=='' && detail==''){
      messages = e.toString();
    }
    return MovementAndLines(id: Memory.ERROR_ID,
        name: '${Messages.ERROR } $messages' );
    //final authDataNotifier = ref.read(authProvider.notifier);
    //throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    return MovementAndLines(id: Memory.ERROR_ID,
        name: '${Messages.ERROR } ${e.toString()}' );
    //throw Exception(e.toString());
  }

});
final movementLineDeletedCounterProvider = StateProvider<int>((ref) {
  return 0;
});
final fireCreateMovementWithCompleteProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final putAwayMovementCreateWithCompleteProvider = StateProvider.autoDispose<PutAwayMovement?>((ref) {
  return null;
});

final newPutAwayMovementWithCompleteProvider = FutureProvider.autoDispose<MovementAndLines?>((ref) async {
  final int count = ref.watch(fireCreateMovementWithCompleteProvider);
  if(count==0) return null;

  PutAwayMovement? newMovement = ref.read(putAwayMovementCreateWithCompleteProvider);
  if(newMovement == null) return null;
  final mInOut = ref.read(mInOutProvider).mInOut ;
  if(mInOut == null) return null;
  final line = ref.read(lineToUpdateLocatorProvider);
  if(line == null || line.id == null || line.id! <=0) return null;


  Dio dio = await DioClient.create();
  MemoryProducts.movementAndLines = MovementAndLines(user: Memory.sqlUsersData);
  String step ='Movement create start';
  debugPrint(step);
  int errorId = Memory.ERROR_DOCUMENT_NOT_CREATED_ID ;
  String createdMovementId ='';
  String description = Memory.getDescriptionMoveBetweenFromApp(mInOut: mInOut, line: line);
  try {
    String url = newMovement.movementInsertUrl ??'';
    final payLoad =
    newMovement.movementToCreate?.getInsertForSwitchBetweenLocatorJson(description: description) ;
    if(url.isEmpty || payLoad == null) return null ;

    final response = await dio.post(url, data: payLoad);
    if (response.statusCode == 201) {
      errorId = Memory.ERROR_DOCUMENT_LINE_NOT_CREATED_ID ;
      IdempiereMovement createdMovement =  IdempiereMovement.fromJson(response.data);
      step ='Movement created id: ${createdMovement.id ?? 0}';
      createdMovementId = createdMovement.id?.toString() ?? '';
      debugPrint(step);
      if (createdMovement.id != null && createdMovement.id! > 0) {
        MemoryProducts.movementAndLines.cloneMovement(createdMovement);
        newMovement.movementLineToCreate!.mMovementID = createdMovement;

        var creteDataJsonEncode2 =  newMovement.getInsertForSwitchBetweenLocatorJson(description: description) ;
        String url2 = newMovement.movementLineInsertUrl!;
        final responseLine = await dio.post(url2, data: creteDataJsonEncode2);
        if (responseLine.statusCode == 201) {

          final IdempiereMovementLine movementLine =  IdempiereMovementLine.fromJson(responseLine.data);
          step ='MovementLine created id: ${movementLine.id ?? 0}';
          debugPrint(step);
          MemoryProducts.movementAndLines.movementLines = [movementLine];
          SqlDataMovement newMovement = SqlDataMovement(id:createdMovement.id);
          Memory.sqlUsersData.copyToSqlData(newMovement);

          String url =newMovement.getUpdateUrl();
          errorId = Memory.ERROR_DOCUMENT_NOT_COMPLETE_ID ;
          final response = await dio.put(url, data: createdMovement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));


          if (response.statusCode == 200) {
            step ='Movement completed id: ${createdMovement.id ?? 0}';
            debugPrint(step);
            createdMovement =  SqlDataMovement.fromJson(response.data);
            MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
            movementAndLines.cloneMovement(createdMovement);
            ref.read(movementAndLinesProvider.notifier).state = movementAndLines;
            MemoryProducts.movementAndLines = movementAndLines ;
            return movementAndLines ;
          } else {
            step ='MovementLine not completed id: ${createdMovement.id ?? 0}';
            return MovementAndLines(id: errorId,
                description: Messages.ERROR_DOCUMENT_NOT_COMPLETED,
                name: createdMovementId);

          }



        }
        step ='MovementLine no created';
        return MovementAndLines(id: errorId,
            name: createdMovementId,
            description: '${Messages.ERROR_DOCUMENT_NOT_CREATED} $step ${response.statusCode} : ${response.statusMessage}' );
      } else {
        step ='Movement no created';
        return MovementAndLines(id: errorId,
            name: createdMovementId,
            description: '${Messages.ERROR_DOCUMENT_NOT_CREATED} $step ${response.statusCode} : ${response.statusMessage}' ,
            );
      }
    } else {
      step ='Movement no created';
      return MovementAndLines(id: errorId,
          name: createdMovementId,
          description: '${Messages.ERROR_DOCUMENT_NOT_CREATED} $step ${response.statusCode} : ${response.statusMessage}' );
    }
  } on DioException catch (e) {
    debugPrint(step);
    debugPrint('DioException');

    String title = e.response?.data['title'] ?? '';
    int status = e.response?.data['status'] ?? '';
    String detail = e.response?.data['detail'] ?? '';
    String messages ='Title : $title\nStatus : $status\nDetail : $detail';
    if(title=='' && detail==''){
      messages = e.toString();
    }

    return MovementAndLines(id: errorId,
        name: createdMovementId,
        description: '${Messages.ERROR } : $messages' );
  } catch (e) {
    return MovementAndLines(id: errorId,
        name: createdMovementId,
        description: 'Exception $step ${e.toString()}' );
  }

});