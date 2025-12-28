
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_response_message.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../../../../../../config/http/dio_client.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../../shared/domain/entities/response_api.dart';
import '../../../../domain/idempiere/delete_request.dart';
import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_confirm.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../../domain/sql/common_sql_data.dart';
import '../../../../domain/sql/sql_data_movement.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/locator_provider.dart';
import '../../store_on_hand/memory_products.dart';

final movementAndLinesProvider = StateProvider.autoDispose<MovementAndLines>((ref) {
  return MemoryProducts.movementAndLines;
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

final putAwayMovementCreateProvider = StateProvider.autoDispose<PutAwayMovement?>((ref) {
  return null;
});

final newPutAwayMovementProvider = FutureProvider.autoDispose<MovementAndLines?>((ref) async {

  PutAwayMovement? newMovement = ref.watch(putAwayMovementCreateProvider);
  if(newMovement == null) return null;


  Dio dio = await DioClient.create();
  MemoryProducts.movementAndLines = MovementAndLines(user: Memory.sqlUsersData);

  try {
    String url = newMovement.movementInsertUrl!;
    final response = await dio.post(url, data: newMovement.movementInsertJson);
    print(url);
    if (response.statusCode == 201) {

      IdempiereMovement movement =  IdempiereMovement.fromJson(response.data);
      if (movement.id != null && movement.id! > 0) {
        MemoryProducts.movementAndLines.cloneMovement(movement);
        newMovement.movementLineToCreate!.mMovementID = movement;
        var creteDataJsonEncode2 =  newMovement.movementLineInsertJson! ;
        String url2 = newMovement.movementLineInsertUrl!;
        print(url2);
        print(creteDataJsonEncode2);
        print('----------------------------------createTed');
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

final newScannedMovementIdForSearchProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
final newMovementIdForMovementLineSearchProvider  = StateProvider.autoDispose<int>((ref) {
  return -1;
});


final newFindMovementByIdOrDocumentNOProvider = FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final String scannedCode = ref.watch(newScannedMovementIdForSearchProvider).toUpperCase();
  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();
  if(scannedCode=='') {
    MemoryProducts.movementAndLines.clearData();
    responseAsyncValue.data = MemoryProducts.movementAndLines;
    return responseAsyncValue;
  }
  responseAsyncValue.isInitiated = true;
  String idempiereModelName ='m_movement';
  Dio dio = await DioClient.create();
  try {
    String url =  "/api/v1/models/$idempiereModelName";
    int? aux = int.tryParse(scannedCode);
    if(aux==null || scannedCode.startsWith('0')){
      url = "/api/v1/models/$idempiereModelName?\$filter=DocumentNo eq '$scannedCode'";
    } else{
      url = "/api/v1/models/$idempiereModelName?\$filter=M_Movement_ID eq $scannedCode";
    }
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {

      responseAsyncValue.success = true;
      final responseApi =
      ResponseApi<IdempiereMovement>.fromJson(response.data, IdempiereMovement.fromJson);
      late IdempiereMovement m;
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        m = responseApi.records![0];
        if(m.id==null || m.id==Memory.INITIAL_STATE_ID || m.id!<=0) {
          MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.NOT_FOUND,
              id: Memory.NOT_FOUND_ID,
              identifier: scannedCode));
          responseAsyncValue.data = MemoryProducts.movementAndLines;
          return responseAsyncValue;
        } else {
          responseAsyncValue.success = true;
          MemoryProducts.movementAndLines.cloneMovement(m);
          await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, MemoryProducts.movementAndLines);
          final String searchField ='M_Movement_ID';
          String idempiereModelName ='m_movementline';
          Dio dio = await DioClient.create();
          String url =
              "/api/v1/models/$idempiereModelName?\$expand=M_Product_ID&\$filter=$searchField eq ${m.id!}&\$orderby=Line";
          url = url.replaceAll(' ', '%20');
          print(url);
          final response = await dio.get(url);

          if (response.statusCode == 200) {
            responseAsyncValue.success = true;
            final responseApi =
            ResponseApi<IdempiereMovementLine>.fromJson(response.data, IdempiereMovementLine.fromJson);
            if (responseApi.records != null && responseApi.records!.isNotEmpty) {
              final dataList = responseApi.records!;
              MemoryProducts.movementAndLines.movementLines = dataList;
            } else {
              MemoryProducts.movementAndLines.movementLines = [];
            }

          }
          idempiereModelName ='m_movementconfirm';
          url =
              "/api/v1/models/$idempiereModelName?\$filter=$searchField eq ${m.id!}&\$orderby=Line";
          url = url.replaceAll(' ', '%20');
          print(url);
          final response2 = await dio.get(url);
          if (response2.statusCode == 200) {
            final responseApi =
            ResponseApi<IdempiereMovementConfirm>.fromJson(response2.data, IdempiereMovementConfirm.fromJson);
            if (responseApi.records != null && responseApi.records!.isNotEmpty) {
              final dataList = responseApi.records!;
              MemoryProducts.movementAndLines.movementConfirms = dataList;

            } else {
              MemoryProducts.movementAndLines.movementConfirms  = [];
            }
          }

        }

      } else {
        MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode));
      }
      responseAsyncValue.data = MemoryProducts.movementAndLines;
    } else {
      responseAsyncValue.success = true;
      responseAsyncValue.message = '${response.statusCode} ${response.statusMessage!}';
      MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.NOT_FOUND, id: Memory.NOT_FOUND_ID, identifier: scannedCode));
      responseAsyncValue.data = MemoryProducts.movementAndLines;

    }
    ref.read(movementAndLinesProvider.notifier).state = MemoryProducts.movementAndLines;
    return responseAsyncValue;
  } on DioException {

    responseAsyncValue.success = false;
    responseAsyncValue.message = '${Messages.ERROR} DioException';
    MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.ERROR, id: Memory.ERROR_ID, identifier: scannedCode));
    ref.read(movementAndLinesProvider.notifier).state = MemoryProducts.movementAndLines;
    responseAsyncValue.data = MemoryProducts.movementAndLines;
    return responseAsyncValue;

  } catch (e) {
    MemoryProducts.movementAndLines.cloneMovement(IdempiereMovement(name: Messages.ERROR, id: Memory.ERROR_ID, identifier: scannedCode));
    ref.read(movementAndLinesProvider.notifier).state = MemoryProducts.movementAndLines;
    responseAsyncValue.success = false ;
    responseAsyncValue.message = Messages.ERROR +e.toString();
    responseAsyncValue.data = MemoryProducts.movementAndLines;
    return responseAsyncValue;
  } finally {
    await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, MemoryProducts.movementAndLines);
  }

});


final newFindMovementLinesByMovementIdProvider = FutureProvider.autoDispose<MovementAndLines>((ref) async {
  final int? id = ref.watch(newMovementIdForMovementLineSearchProvider);
  print('----------------------------------start findMovementLinesByMovementIdProvider $id');
  MemoryProducts.movementAndLines.movementLines = null;
  if(id==null || id==Memory.INITIAL_STATE_ID || id<=0) return MemoryProducts.movementAndLines;
  String searchField ='M_Movement_ID';
  String idempiereModelName ='m_movementline';
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=$searchField eq $id&\$orderby=Line";
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {

      final responseApi =
      ResponseApi<IdempiereMovementLine>.fromJson(response.data, IdempiereMovementLine.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final dataList = responseApi.records!;
        if(dataList.isEmpty){
          MemoryProducts.movementAndLines.movementLines = [];
          await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, MemoryProducts.movementAndLines);
        } else {
          MemoryProducts.movementAndLines.movementLines = dataList;
          await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, MemoryProducts.movementAndLines);
          return MemoryProducts.movementAndLines;
        }
      }
    }
    MovementAndLines movementAndLines = MovementAndLines();
    movementAndLines.cloneMovementAndLines(MemoryProducts.movementAndLines);
    return MemoryProducts.movementAndLines;
  } on DioException {
    MovementAndLines movementAndLines = MovementAndLines();
    movementAndLines.cloneMovementAndLines(MemoryProducts.movementAndLines);
    return MemoryProducts.movementAndLines;
  } catch (e) {
    MovementAndLines movementAndLines = MovementAndLines();
    movementAndLines.cloneMovementAndLines(MemoryProducts.movementAndLines);
    return MemoryProducts.movementAndLines;
  }

});

final movementLineForEditQuantityToMoveProvider =
StateProvider.autoDispose.family<IdempiereMovementLine?, int>((ref, lineId) {
  return null;
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
  print(request.lineId);
  print(request.movementIdToDelete);
  final dio = await DioClient.create();

  try {
    // =========================
    // 1) BORRAR LINE (DELETE)
    // =========================
    final line = SqlDataMovementLine(id: request.lineId);
    Memory.sqlUsersData.copyToSqlData(line);

    final urlLine = line.getUpdateUrl();
    print(urlLine);
    final respLine = await dio.delete(urlLine);
    print(respLine.data);
    int i  = ref.read(counterProvider);
    print('deleteMovementLineProvider $i');
    ref.read(counterProvider.notifier).state = i+1;

    if (respLine.statusCode != 200) return false;

    final resLine = IdempiereResponseMessage.fromJson(respLine.data);
    if (request.movementIdToDelete ==null || request.movementIdToDelete!<=0){
      print('return ${resLine.deleted}');
      return resLine.deleted;
    }
    print('deleteMovementLineProvider delete movement');

    // =========================
    // 2) SI ES ÚLTIMA LINEA: BORRAR MOVEMENT (PUT docStatus=DELETE)
    // =========================
    final movementId = request.movementIdToDelete ?? -1;
    if (movementId > 0) {
      final movement = SqlDataMovement(id: movementId);
      Memory.sqlUsersData.copyToSqlData(movement);

      final urlMov = movement.getUpdateUrl();
      print(urlMov);
      final payload = movement.getUpdateDocStatusJson(CommonSqlData.DOC_DELETE_STATUS);
      print(payload);
      final respMov = await dio.put(urlMov, data: payload);
      print(respMov.data);
      print(respMov.statusCode);
      if (respMov.statusCode != 200) return false;


      final resMov = IdempiereResponseMessage.fromJson(respMov.data);
      print(resMov.toJson());
      print(resMov.deleted);
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
  } on DioException catch (e) {
    print('DioException delete line/movement: $e');
    return false;
  } catch (e) {
    print('Exception delete line/movement: $e');
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
    print(url);
    print(movementLine.getUpdateMovementQuantityJson());
    final response = await dio.put(url, data: movementLine.getUpdateMovementQuantityJson());


    if (response.statusCode == 200) {
      final res = IdempiereMovementLine.fromJson(response.data);
      return res.movementQty;
    }

    return -1; // error http
  } on DioException catch (e) {
    print('DioException edit quantity: $lineId $e');
    return -2;
  } catch (e) {
    print('Exception edit quantity: $lineId $e');
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

  print('----------------------------------findMovementNotCompletedByDateProvider');

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

      print(url);

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


/*final findMovementNotCompletedByDateProvider = FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final MovementAndLines? movement = ref.watch(movementNotCompletedToFindByDateProvider);
  print('----------------------------------findMovementNotCompletedByDateProvider');
  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();
  if(movement== null || movement.filterMovementDateStartAt == null) return responseAsyncValue;

  responseAsyncValue.isInitiated = true;
  String docStatus = movement.filterDocumentStatus?.id ?? 'DR' ;
  String endDate = '';
  if(movement.filterMovementDateEndAt !=null){
    endDate = 'AND MovementDate le ${movement.filterMovementDateEndAt!} ';
  }

  String date = movement.filterMovementDateStartAt!;

  String idempiereModelName ='m_movement';
  Dio dio = await DioClient.create();
  try {
    String url =  "/api/v1/models/$idempiereModelName";
    int warehouse = Memory.sqlUsersData.mWarehouseID?.id ?? -1;
    if(movement.filterWarehouseFrom ==null && movement.filterWarehouseTo == null){
      url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' ${endDate}AND (M_WarehouseTo_ID eq $warehouse OR M_Warehouse_ID eq $warehouse)&\$orderby=MovementDate desc";
    } else if(movement.filterWarehouseFrom !=null && movement.filterWarehouseTo  != null){
      int warehouse = movement.filterWarehouseFrom!.id!;
      int warehouseTo = movement.filterWarehouseTo !.id!;
      url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' ${endDate}AND M_WarehouseTo_ID eq $warehouseTo AND M_Warehouse_ID eq $warehouse&\$orderby=MovementDate desc";
    } else if(movement.filterWarehouseFrom ==null){
      //int warehouseTo = movement.filterWarehouseTo !.id!;
      //url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' AND M_WarehouseTo_ID eq $warehouseTo&\$orderby=MovementDate desc";
      int warehouse = movement.filterWarehouseTo !.id!;
      int warehouseTo = movement.filterWarehouseTo !.id!;
      url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' ${endDate}AND M_WarehouseTo_ID eq $warehouseTo AND M_Warehouse_ID neq $warehouse&\$orderby=MovementDate desc";
    } else {
      //int warehouse = movement.mWarehouseID!.id!;
      //url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' AND M_Warehouse_ID eq $warehouse&\$orderby=MovementDate desc";
      int warehouse = movement.filterWarehouseFrom!.id!;
      int warehouseTo = movement.filterWarehouseFrom!.id!;
      url = "/api/v1/models/$idempiereModelName?\$filter=DocStatus eq '$docStatus' AND MovementDate ge '$date' ${endDate}AND M_WarehouseTo_ID neq $warehouseTo AND M_Warehouse_ID eq $warehouse&\$orderby=MovementDate desc";
    }
    int skip = 0 ;
    url='$url&\$top=100&\$skip=$skip';
    print(url);
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      responseAsyncValue.success = true;
      final responseApi =
      ResponseApi<IdempiereMovement>.fromJson(response.data, IdempiereMovement.fromJson);


      int totalRecords = responseApi.rowCount ?? 0; //registros totales que debe ser extraidos
      int totalPages = responseApi.pageCount ?? 0; // veces a ejecutar  para todos los registros
      int recordsSize = responseApi.recordsSize ?? 100; // default = 100 (catidad de registro maximo enviado por cada consulta)
      int skipRecords = responseApi.skipRecords ?? 0; // inicio de posicion de registros a extraer

      late List<IdempiereMovement> m;
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        m = responseApi.records!;
      } else {
        m = [IdempiereMovement(name: Messages.NO_DATA_FOUND, id: Memory.NOT_FOUND_ID)];
      }
      responseAsyncValue.data = m;
      return responseAsyncValue;


    } else {
      responseAsyncValue.success = true;
      List<IdempiereMovement>  m = [IdempiereMovement(name: Messages.ERROR, id: response.statusCode)];
      responseAsyncValue.data = m;
      return responseAsyncValue;
    }

  } on DioException {
    responseAsyncValue.success = false;
    responseAsyncValue.message = '${Messages.ERROR} DioException';
    return  responseAsyncValue;

  } catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.message = Messages.ERROR +e.toString();
    return  responseAsyncValue;
  }

});*/
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

    String url =movement.getUpdateUrl();
    print(url);
    print(movement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));
    final response = await dio.put(url, data: movement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));

    if (response.statusCode == 200) {
      movement =  SqlDataMovement.fromJson(response.data);
      MovementAndLines movementAndLines = MovementAndLines();
      movementAndLines.cloneMovement(movement);
      MemoryProducts.movementAndLines = movementAndLines;
      print('result confirmMovementProvider ${movementAndLines.docStatus?.id ?? 'doc null'}');
      return movementAndLines;
    } else {
      return MovementAndLines(id: Memory.ERROR_ID,
          name: '${Messages.ERROR }${response.statusCode} : ${response.statusMessage}' );

    }



  } on DioException catch (e) {
    return MovementAndLines(id: Memory.ERROR_ID,
        name: '${Messages.ERROR } ${e.toString()}' );
  } catch (e) {
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
    print(url);
    Map<String, dynamic> payload = movement.getUpdateDocStatusJson(CommonSqlData.DOC_DELETE_STATUS);
    print(payload);
    print('---put-------------cancelMovementProvider 4 ');
    final response = await dio.put(url, data: payload);

    if (response.statusCode == 200) {
      movement =  SqlDataMovement.fromJson(response.data);
      MovementAndLines movementAndLines = MovementAndLines();
      movementAndLines.cloneMovement(movement);
      MemoryProducts.movementAndLines = movementAndLines;
      print('---result-------------cancelMovementProvider ${movement.docStatus?.id ?? 'doc null'}');
      print('---movement-------------movement ${movementAndLines.docStatus?.id ?? 'doc null'}');
      print('---result-------------cancelMovementProvider ${movement.docStatus?.id ?? 'doc null'}');
      print('---movement-------------movement ${movementAndLines.docStatus?.toJson() ?? 'doc null'}');
      return movementAndLines;
    } else {
      print('${Messages.ERROR }${response.statusCode} : ${response.statusMessage}');
      return MovementAndLines(id: Memory.ERROR_ID,
          name: '${Messages.ERROR }${response.statusCode} : ${response.statusMessage}' );
      throw Exception(
          'Error al obtener la lista de $url: ${response.statusCode}');
    }



  } on DioException catch (e) {
    print('DioException: ${e.toString()}');
    return MovementAndLines(id: Memory.ERROR_ID,
        name: '${Messages.ERROR } ${e.toString()}' );
    //final authDataNotifier = ref.read(authProvider.notifier);
    //throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    print('Exception: ${e.toString()}');
    return MovementAndLines(id: Memory.ERROR_ID,
        name: '${Messages.ERROR } ${e.toString()}' );
    //throw Exception(e.toString());
  }

});
final movementLineDeletedCounterProvider = StateProvider<int>((ref) {
  return 0;
});
