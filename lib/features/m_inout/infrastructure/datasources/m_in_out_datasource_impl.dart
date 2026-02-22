
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/line_confirm.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/locate.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/model_crud.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/model_crud_request.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/response_api.dart';
import 'package:monalisa_app_001/features/m_inout/domain/datasources/m_inout_datasource.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/standard_response.dart';

import '../../../../config/config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/common/idempiere_rest_api.dart';
import '../../../products/domain/models/idempiere_query_page_utils.dart';
import '../../../products/domain/models/m_in_out_list_type.dart';
import '../../../shared/domain/entities/ad_login_request.dart';
import '../../../shared/domain/entities/field_crud.dart';
import '../../../shared/domain/entities/model_set_doc_action.dart';
import '../../../shared/domain/entities/model_set_doc_action_request.dart';
import '../../../shared/shared.dart';
import '../../domain/entities/line.dart';
import '../../domain/entities/m_in_out_confirm.dart';
import '../../presentation/providers/line_provider.dart';
import '../../presentation/providers/m_in_out_providers.dart';

class MInOutDataSourceImpl implements MInOutDataSource {
  late final Dio dio;
  late final Future<void> _dioInitialized;

  MInOutDataSourceImpl() {
    _dioInitialized = _initDio();
  }

  Future<void> _initDio() async {
    dio = await DioClient.create();
  }

  @override
  Future<List<MInOut>> getMInOutList(WidgetRef ref) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    final int warehouseID = ref.read(authProvider).selectedWarehouse!.id;
    MInOut a;
    try {
      final String url =
          "/api/v1/models/m_inout?\$filter=IsSOTrx%20eq%20${mInOutState.isSOTrx}%20AND%20M_Warehouse_ID%20eq%20$warehouseID%20AND%20(DocStatus%20eq%20'DR'%20OR%20DocStatus%20eq%20'IP')";

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final responseApi =
            ResponseApi<MInOut>.fromJson(response.data, MInOut.fromJson);

        if (responseApi.records != null && responseApi.records!.isNotEmpty) {
          final mInOutList = responseApi.records!;
          return mInOutList;
        } else {
          return [];
        }
      } else {
        throw Exception(
            'Error al obtener la lista de ${mInOutState.title}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<MInOutConfirm>> getMInOutConfirmList(
      int mInOutId, WidgetRef ref) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    debugPrint('getMInOutConfirmList start');
    final String confirmType =
        mInOutState.mInOutType == MInOutType.receiptConfirm ||
                mInOutState.mInOutType == MInOutType.shipmentConfirm
            ? "%20AND%20ConfirmType%20eq%20'SC'"
            : mInOutState.mInOutType == MInOutType.pickConfirm ||
                    mInOutState.mInOutType == MInOutType.qaConfirm
                ? "%20AND%20ConfirmType%20eq%20'PC'"
                : "";


    try {
      final String url =
          "/api/v1/models/m_inoutConfirm?\$filter=M_InOut_ID%20eq%20$mInOutId$confirmType";
      final response = await dio.get(url);
      debugPrint('url $url');
      debugPrint('getMInOutConfirmList response ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseApi = ResponseApi<MInOutConfirm>.fromJson(
            response.data, MInOutConfirm.fromJson);

        if (responseApi.records != null && responseApi.records!.isNotEmpty) {
          final mInOutConfirmList = responseApi.records!;
          mInOutState.copyWith(mInOutConfirmList: mInOutConfirmList);
          debugPrint('getMInOutConfirmList return');
          return mInOutConfirmList;

        } else {
          debugPrint('getMInOutConfirmList return empty');
          return [];
        }
      } else {
        debugPrint(
            'Error al obtener la lista de ${mInOutState.title}: ${response.statusCode}');
        throw Exception(
            'Error al obtener la lista de ${mInOutState.title}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Error al obtener la lista de ${mInOutState.title}: $e');
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      debugPrint('Error al obtener la lista de ${mInOutState.title}: $e');
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<MInOut>> getMovementList(WidgetRef ref) async {
    debugPrint('getMovementList');
    await _dioInitialized;
    final int warehouseID = ref.read(authProvider).selectedWarehouse!.id;
    final mInOutState = ref.read(mInOutProvider);

    try {
      final String url =
          "/api/v1/models/m_movement?\$filter=(M_Warehouse_ID%20eq%20$warehouseID%20OR%20M_Warehouse_ID%20eq%20null%20OR%20M_WarehouseTo_ID%20eq%20$warehouseID)%20AND%20(DocStatus%20eq%20'DR'%20OR%20DocStatus%20eq%20'IP')";
      print(url);
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final responseApi =
            ResponseApi<MInOut>.fromJson(response.data, MInOut.fromJson);

        if (responseApi.records != null && responseApi.records!.isNotEmpty) {
          final mInOutList = responseApi.records!;
          return mInOutList;
        } else {
          return [];
        }
      } else {
        throw Exception(
            'Error al obtener la lista de ${mInOutState.title}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<MInOut> getMInOut(
    String mInOutDoc,
    WidgetRef ref,
  ) async {
    print('getMInOut');
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    final int warehouseID = ref.read(authProvider).selectedWarehouse!.id;
    try {
      final String url =
          "/api/v1/models/m_inout?\$filter=DocumentNo%20eq%20'${mInOutDoc.toString()}'%20AND%20IsSOTrx%20eq%20${mInOutState.isSOTrx}%20AND%20M_Warehouse_ID%20eq%20$warehouseID";
      print(url);

      print(url.replaceAll('%20', ' '));
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final responseApi =
            ResponseApi<MInOut>.fromJson(response.data, MInOut.fromJson);
        if (responseApi.records != null && responseApi.records!.isNotEmpty) {
          final mInOut = responseApi.records!.first;
          print('mInOutgetMInOut-----${mInOut.id ?? 'NULL'}');
          final lines = await getLinesMInOut(mInOut.id!, ref);
          mInOut.lines = lines;
          print('mInOutgetMInOut--lines ${lines.isNotEmpty ? mInOut.lines.length :'empty' }');
          return mInOut;
        } else {
          throw Exception(
              'No se encontraron registros del ${mInOutState.title}');
        }
      } else {
        throw Exception(
            'Error al cargar los datos del ${mInOutState.title}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Line>> getLinesMInOut(
    int mInOutId,
    WidgetRef ref,
  ) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    final List<Line> allLines = [];
    int skip = 0;
    bool hasMoreRecords = true;

    try {
      while (hasMoreRecords) {
        final String url =
            "/api/v1/models/m_inoutline?\$filter=M_InOut_ID%20eq%20$mInOutId&\$orderby=Line,M_InOutLine_ID&\$skip=$skip";
        final response = await dio.get(url);
        print('getLinesMInOut $url');
        if (response.statusCode != 200) {
          throw Exception(
              'Error loading ${mInOutState.title} data: ${response.statusCode}');
        }

        final responseApi =
            ResponseApi<Line>.fromJson(response.data, Line.fromJson);

        if (responseApi.records == null || responseApi.records!.isEmpty) {
          if (skip == 0) {
            throw Exception('No records found for ${mInOutState.title}');
          }
          break;
        }

        allLines.addAll(responseApi.records!);
        skip += responseApi.records!.length;
        hasMoreRecords = responseApi.rowCount! > skip;
      }

      return allLines;
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<MInOutConfirm> getMInOutConfirm(
    int mInOutConfirmId,
    WidgetRef ref,
  ) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    try {
      final String url =
          "/api/v1/models/m_inoutconfirm?\$filter=M_InOutConfirm_ID%20eq%20$mInOutConfirmId";
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final responseApi = ResponseApi<MInOutConfirm>.fromJson(
            response.data, MInOutConfirm.fromJson);

        if (responseApi.records != null && responseApi.records!.isNotEmpty) {
          final mInOutConfirm = responseApi.records!.first;

          final lines = await getLinesMInOutConfirm(mInOutConfirm.id!, ref);
          mInOutConfirm.linesConfirm = lines;

          return mInOutConfirm;
        } else {
          throw Exception(
              'No se encontraron registros del ${mInOutState.title}');
        }
      } else {
        throw Exception(
            'Error al cargar los datos del ${mInOutState.title}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  @override
  Future<List<MInOutConfirm>> getMInOutConfirmInDraftByMInOutID({
    required int mInOutId,
    required int excludedMInOutConfirmId,
    required WidgetRef ref,
  }) async {
    await _dioInitialized;

    // EN: Prefer ref.read in repositories (avoid rebuild subscriptions)
    final mInOutState = ref.read(mInOutProvider);

    final List<MInOutConfirm> confirmList = [];
    int skip = 0;
    bool hasMoreRecords = true;
    final isMovement = mInOutState.mInOutType == MInOutType.move ||
        mInOutState.mInOutType == MInOutType.moveConfirm;
    final modelName = isMovement ? 'M_MovementConfirm' : 'M_InOutConfirm';
    final columnId = isMovement ? 'M_MovementConfirm_ID' : 'M_InOutConfirm_ID';
    final columnSearch = isMovement ? 'M_Movement_ID' : 'M_InOut_ID';



    try {
      while (hasMoreRecords) {
        // EN: Keep filter operators consistent (use "and")
        late final String url;
        if(excludedMInOutConfirmId>0) {
          url =
        "/api/v1/models/$modelName?"
            "\$filter=$columnSearch%20eq%20$mInOutId%20and%20"
            "$columnId%20neq%20$excludedMInOutConfirmId%20and%20"
            "DocStatus%20eq%20'DR'"
            "&\$orderby=$columnId"
            "&\$skip=$skip";
        } else {
          url =
          "/api/v1/models/$modelName?"
              "\$filter=$columnSearch%20eq%20$mInOutId%20and%20"
              "DocStatus%20eq%20'DR'"
              "&\$orderby=$columnId"
              "&\$skip=$skip";
        }


        debugPrint('url $url');
        final response = await dio.get(url);

        if (response.statusCode != 200) {
          throw Exception(
            'Error loading ${mInOutState.title} data: ${response.statusCode}',
          );
        }

        final responseApi = ResponseApi<MInOutConfirm>.fromJson(
          response.data,
          MInOutConfirm.fromJson,
        );

        final records = responseApi.records ?? const <MInOutConfirm>[];

        // ⭐ CAMBIO PRINCIPAL
        // EN: No records is NOT an error → just return empty list
        if (records.isEmpty) return confirmList;

        confirmList.addAll(records);
        skip += records.length;
        hasMoreRecords = (responseApi.rowCount ?? 0) > skip;
      }

      return confirmList;
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  @override
  Future<List<LineConfirm>> getLinesMInOutConfirmToUpdateTargetQty({
    required List<int> listConfirmsIds,
    required List<int> mInOutLineIds,
    required WidgetRef ref,
  }) async {
    debugPrint('getLinesMInOutConfirmToUpdateTargetQty');
    await _dioInitialized;

    final mInOutState = ref.read(mInOutProvider);

    if (listConfirmsIds.isEmpty || mInOutLineIds.isEmpty) return [];

    const int chunkSize = 50;

    final List<LineConfirm> allLines = [];
    final isMovement = mInOutState.mInOutType == MInOutType.move ||
        mInOutState.mInOutType == MInOutType.moveConfirm;


    try {

      // 🔥 CHUNK LOOP CONFIRM IDS
      for (int cStart = 0; cStart < listConfirmsIds.length; cStart += chunkSize) {

        final confirmChunk =
        listConfirmsIds.skip(cStart).take(chunkSize).toList();

        final confirmsIds = confirmChunk.join(',');

        // 🔥 CHUNK LOOP LINE IDS
        for (int lStart = 0; lStart < mInOutLineIds.length; lStart += chunkSize) {

          final lineChunk =
          mInOutLineIds.skip(lStart).take(chunkSize).toList();

          final lineIds = lineChunk.join(',');

          int skip = 0;
          bool hasMoreRecords = true;

          debugPrint(
            'LinesChunk confirmChunk=${confirmChunk.length} '
                'lineChunk=${lineChunk.length}',
          );

          while (hasMoreRecords) {

            final String url =
                "/api/v1/models/m_inoutlineconfirm?"
                "\$filter=M_InOutLine_ID%20in%20($lineIds)%20and%20"
                "M_InOutConfirm_ID%20in%20($confirmsIds)"
                "&\$orderby=M_InOutLineConfirm_ID"
                "&\$skip=$skip";

            debugPrint('getLinesChunk url: $url');

            final response = await dio.get(url);

            if (response.statusCode != 200) {
              throw Exception(
                'Error loading ${mInOutState.title}: ${response.statusCode}',
              );
            }

            final responseApi = ResponseApi<LineConfirm>.fromJson(
              response.data,
              LineConfirm.fromJson,
            );

            final records = responseApi.records ?? const <LineConfirm>[];

            if (records.isEmpty) break;

            allLines.addAll(records);

            skip += records.length;
            hasMoreRecords = (responseApi.rowCount ?? 0) > skip;
          }
        }
      }

      return allLines;

    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  @override
  Future<MInOut> getMovement(String movementDoc, WidgetRef ref) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    final int warehouseID = ref.read(authProvider).selectedWarehouse!.id;
    try {
      final String url =
          "/api/v1/models/m_movement?\$filter=DocumentNo%20eq%20'${movementDoc.toString()}'%20AND%20(M_Warehouse_ID%20eq%20$warehouseID"
          "%20OR%20M_Warehouse_ID%20eq%20null%20OR%20M_WarehouseTo_ID%20eq%20$warehouseID)";
      print(url);
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final responseApi =
            ResponseApi<MInOut>.fromJson(response.data, MInOut.fromJson);


        if (responseApi.records != null && responseApi.records!.isNotEmpty) {
          final mInOut = responseApi.records!.first;

          final lines = await getLinesMovement(mInOut.id!, ref);
          await Future.delayed(Duration(microseconds: 500));
          mInOut.lines = lines;

          return mInOut;
        } else {
          throw Exception(
              'No se encontraron registros del ${mInOutState.title}');
        }
      } else {
        throw Exception(
            'Error al cargar los datos del ${mInOutState.title}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<Line>> getLinesMovement(
    int movementId,
    WidgetRef ref,
  ) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    final List<Line> allLines = [];
    int skip = 0;
    bool hasMoreRecords = true;

    try {
      while (hasMoreRecords) {
        final String url =
            "/api/v1/models/m_movementline?\$filter=M_Movement_ID%20eq%20$movementId&\$orderby=line&\$skip=$skip";
        print(url);
        final response = await dio.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              'Error loading ${mInOutState.title} data: ${response.statusCode}');
        }

        final responseApi =
            ResponseApi<Line>.fromJson(response.data, Line.fromJson);

        if (responseApi.records == null || responseApi.records!.isEmpty) {
          if (skip == 0) {
            throw Exception('No records found for ${mInOutState.title}');
          }
          break;
        }

        allLines.addAll(responseApi.records!);
        skip += responseApi.records!.length;
        print('Total records: ${responseApi.rowCount} extracted records: $skip');
        hasMoreRecords = responseApi.rowCount! > skip;
        print('hasMoreRecords: $hasMoreRecords');
        await Future.delayed(Duration(microseconds: 200));
      }

      updateRepeatedLines(ref, allLines);
      await Future.delayed(Duration(microseconds: 200));
      print('allLines length: ${allLines.length}');

      return allLines;
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<MInOutConfirm>> getMovementConfirmList(
      int movementId,
      WidgetRef ref,
      ) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);

    final List<MInOutConfirm> allConfirms = [];
    int skip = 0;
    bool hasMoreRecords = true;

    try {
      while (hasMoreRecords) {
        final String url =
            "/api/v1/models/m_movementConfirm?\$filter=M_Movement_ID%20eq%20$movementId"
            "&\$orderby=M_MovementConfirm_ID"
            "&\$skip=$skip";
        debugPrint('url $url');

        final response = await dio.get(url);

        if (response.statusCode != 200) {
          throw Exception(
            'Error al obtener la lista de ${mInOutState.title}: ${response.statusCode}',
          );
        }

        final responseApi = ResponseApi<MInOutConfirm>.fromJson(
          response.data,
          MInOutConfirm.fromJson,
        );

        // Si no hay records, cortamos.
        if (responseApi.records == null || responseApi.records!.isEmpty) {
          // A diferencia de getLinesMovement, acá NO tiramos excepción si skip==0,
          // porque para confirm list es válido que no haya confirms.
          break;
        }

        allConfirms.addAll(responseApi.records!);
        skip += responseApi.records!.length;

        debugPrint(
          'Total records: ${responseApi.rowCount} extracted records: $skip',
        );

        final rowCount = responseApi.rowCount ?? 0;
        hasMoreRecords = rowCount > skip;

        debugPrint('hasMoreRecords: $hasMoreRecords');

        // Micro-pausa (igual a tu patrón)
        await Future.delayed(const Duration(microseconds: 200));
      }

      return allConfirms;
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  @override
  Future<MInOutConfirm> getMovementConfirm(
      int movementConfirmId, WidgetRef ref) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    try {
      final String url =
          "/api/v1/models/m_movementConfirm?\$filter=M_MovementConfirm_ID%20eq%20$movementConfirmId";
      print(url);
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final responseApi = ResponseApi<MInOutConfirm>.fromJson(
            response.data, MInOutConfirm.fromJson);

        if (responseApi.records != null && responseApi.records!.isNotEmpty) {
          final mInOutConfirm = responseApi.records!.first;

          final lines = await getLinesMovementConfirm(mInOutConfirm.id!, ref);
          mInOutConfirm.linesConfirm = lines;

          return mInOutConfirm;
        } else {
          throw Exception(
              'No se encontraron registros del ${mInOutState.title}');
        }
      } else {
        throw Exception(
            'Error al cargar los datos del ${mInOutState.title}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<LineConfirm>> getLinesMovementConfirm(
    int movementConfirmId,
    WidgetRef ref,
  ) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    final List<LineConfirm> allLines = [];
    int skip = 0;
    bool hasMoreRecords = true;

    try {
      while (hasMoreRecords) {
        final String url =
            "/api/v1/models/m_movementlineconfirm?\$filter=M_MovementConfirm_ID%20eq%20$movementConfirmId&\$orderby=M_MovementLineConfirm_ID&\$skip=$skip";
        print(url);
        final response = await dio.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              'Error loading ${mInOutState.title} data: ${response.statusCode}');
        }

        final responseApi = ResponseApi<LineConfirm>.fromJson(
            response.data, LineConfirm.fromJson);

        if (responseApi.records == null || responseApi.records!.isEmpty) {
          if (skip == 0) {
            throw Exception('No records found for ${mInOutState.title}');
          }
          break;
        }

        allLines.addAll(responseApi.records!);
        skip += responseApi.records!.length;
        hasMoreRecords = responseApi.rowCount! > skip;
      }
      debugPrint('confirm line allLines length: ${allLines.length}');
      return allLines;
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<MInOut> setDocAction(WidgetRef ref) async {
    print('----------setDocAction----------init ');
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);

    final isConfirm = mInOutState.mInOutType != MInOutType.shipment &&
        mInOutState.mInOutType != MInOutType.receipt &&
        mInOutState.mInOutType != MInOutType.shipmentPrepare &&
        mInOutState.mInOutType != MInOutType.move;



    final currentStatus = isConfirm
        ? mInOutState.mInOutConfirm?.docStatus.id?.toString() ?? 'DR'
        : mInOutState.mInOut?.docStatus.id?.toString() ?? 'DR';

    var status = isConfirm
        ? 'CO'
        : (currentStatus == 'DR'
            ? 'PR'
            : (currentStatus == 'IP' ? 'CO' : 'DR'));
    if(mInOutState.mInOutType == MInOutType.move){
      status ='CO';
    }
    if(mInOutState.mInOutType == MInOutType.shipmentPrepare){
      status ='PR';
    }
    print('-----status : $status currentStatus : $currentStatus isConfirm : $isConfirm');

    try {
      final String url =
          "/ADInterface/services/rest/model_adservice/set_docaction";
      final authData = ref.read(authProvider);

      final serviceType = isConfirm
          ? (mInOutState.mInOutType == MInOutType.moveConfirm
              ? 'SetDocumentActionMovementConfirm'
              : 'SetDocumentActionInOutConfirm')
          : (mInOutState.mInOutType == MInOutType.move
              ? 'SetDocumentActionMovement'
              : 'SetDocumentActionShipment');

      final tableName = isConfirm
          ? (mInOutState.mInOutType == MInOutType.moveConfirm
              ? 'M_MovementConfirm'
              : 'M_InOutConfirm')
          : (mInOutState.mInOutType == MInOutType.move
              ? 'M_Movement'
              : 'M_InOut');

      final recordId = isConfirm
          ? mInOutState.mInOutConfirm?.id ?? 0
          : mInOutState.mInOut?.id ?? 0;

      final request = {
        'ModelSetDocActionRequest': ModelSetDocActionRequest(
          modelSetDocAction: ModelSetDocAction(
            serviceType: serviceType,
            tableName: tableName,
            recordId: recordId,
            docAction: status,
          ),
          adLoginRequest: AdLoginRequest(
            user: authData.userName,
            pass: authData.password,
            lang: "es_PY",
            clientId: authData.selectedClient!.id,
            roleId: authData.selectedRole!.id,
            orgId: authData.selectedOrganization!.id,
            warehouseId: authData.selectedWarehouse!.id,
            stage: 9,
          ),
        ).toJson()
      };
      print(request);
      print(url);

      final response = await dio.post(url, data: request);
      if (response.statusCode == 200) {
        final standardResponse =
            StandardResponse.fromJson(response.data['StandardResponse']);
        if (standardResponse.isError == false) {

          int duration = 3;
          await Future.delayed(Duration(seconds: duration));
          final bool isMovement =(mInOutState.mInOutType == MInOutType.move
              || mInOutState.mInOutType == MInOutType.moveConfirm);


          final mInOutResponse = isMovement

              ? await getMovement(
                  mInOutState.mInOut!.documentNo!.toString(), ref)
              : await getMInOut(
                  mInOutState.mInOut!.documentNo!.toString(), ref);
          if (mInOutResponse.id == mInOutState.mInOut!.id) {

            return mInOutResponse;
          } else {
            throw Exception('Error al confirmar el ${mInOutState.title}');
          }
        } else {
          throw Exception(standardResponse.error ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Error al cargar los datos del ${mInOutState.title}: ${response.statusCode}');
      }

    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  @override
  Future<MInOutConfirm> setDocActionConfirm(WidgetRef ref) async {
    print('----------setDocAction----------init ');
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);


    final currentStatus = mInOutState.mInOutConfirm?.docStatus.id?.toString() ?? 'DR';


    var status = 'CO';

    print('-----status : $status currentStatus : $currentStatus isConfirm');

    try {
      final String url =
          "/ADInterface/services/rest/model_adservice/set_docaction";
      final authData = ref.read(authProvider);

      final serviceType = mInOutState.mInOutType == MInOutType.moveConfirm
          ? 'SetDocumentActionMovementConfirm'
          : 'SetDocumentActionInOutConfirm';

      final tableName = mInOutState.mInOutType == MInOutType.moveConfirm
          ? 'M_MovementConfirm'
          : 'M_InOutConfirm';

      final recordId =  mInOutState.mInOutConfirm?.id ?? 0 ;

      final request = {
        'ModelSetDocActionRequest': ModelSetDocActionRequest(
          modelSetDocAction: ModelSetDocAction(
            serviceType: serviceType,
            tableName: tableName,
            recordId: recordId,
            docAction: status,
          ),
          adLoginRequest: AdLoginRequest(
            user: authData.userName,
            pass: authData.password,
            lang: "es_PY",
            clientId: authData.selectedClient!.id,
            roleId: authData.selectedRole!.id,
            orgId: authData.selectedOrganization!.id,
            warehouseId: authData.selectedWarehouse!.id,
            stage: 9,
          ),
        ).toJson()
      };
      print(request);
      print(url);

      final response = await dio.post(url, data: request);
      if (response.statusCode == 200) {
        final standardResponse =
        StandardResponse.fromJson(response.data['StandardResponse']);
        if (standardResponse.isError == false) {

          int duration = 3;
          await Future.delayed(Duration(seconds: duration));
          final bool isMovement =(mInOutState.mInOutType == MInOutType.move
              || mInOutState.mInOutType == MInOutType.moveConfirm);


          final mInOutResponse = isMovement

              ? await getMovementConfirm(
              recordId, ref)
              : await getMInOutConfirm(
              recordId, ref);
          if (mInOutResponse.id == recordId) {

            return mInOutResponse;
          } else {
            throw Exception('Error al confirmar el ${mInOutState.title}');
          }
        } else {
          throw Exception(standardResponse.error ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Error al cargar los datos del ${mInOutState.title}: ${response.statusCode}');
      }

    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Line> updateMInOutLineMovementQtyAndLocator(Line line, WidgetRef ref) async {
    final mInOutState = ref.read(mInOutProvider);

    // Decide target model & qty column
    final bool isMovement = mInOutState.isMovement;
    final String modelName = isMovement ? 'm_movementline' : 'm_inoutline';
    final String qtyColumn = 'MovementQty';
    final String qtyEnteredColumn = 'QtyEntered';
    final bool isConfirmFlow = mInOutState.isConfirmFlow;

    final int? recordId = line.id;
    if (recordId == null) {
      throw Exception('Line.id is null. Cannot update record.');
    }

    // Build payload
    final Map<String, dynamic> payload = {
      qtyColumn: (line.confirmedQty ?? 0.0),
      if(!isMovement) qtyEnteredColumn: (line.confirmedQty ?? 0.0),
      if(!isConfirmFlow) 'ConfirmedQty' :(line.confirmedQty ?? 0),
    };

    // Optional locator update
    /*if (line.editLocator != null) {
      // Try int first. If your server requires object, use {'id': line.editLocator}.
      payload['M_Locator_ID'] = line.editLocator;
    }*/

    await updateDataByRESTAPI(
      modelName: modelName,
      id: recordId,
      data: payload,
      ref: ref,
    );

    return Line(id: recordId);
  }

  /*@override
  Future<Line> updateMInOutLine(Line line, WidgetRef ref) async {
    await _dioInitialized;
    try {
      final String url =
          "/ADInterface/services/rest/model_adservice/update_data";
      print(url);
      final authData = ref.read(authProvider);
      final mInOutData = ref.read(mInOutProvider);

      String serviceType = 'UpdateInOutLine';
      String tableName = 'M_InOutLine';
      String columnToUpdate ='TargetQty';

      if (mInOutData.mInOutType == MInOutType.moveConfirm) {
        serviceType = 'UpdateMovementLine';
        tableName = 'M_MovementLine';
        columnToUpdate ='MovementQty';
      }

      final request = {
        'ModelCRUDRequest': ModelCrudRequest(
          modelCrud: ModelCrud(
            serviceType: serviceType,
            tableName: tableName,
            recordId: line.id,
            action: "Update",
            dataRow: {
              'field': [
                FieldCrud(
                    column: columnToUpdate, val: line.confirmedQty.toString()),

              ].map((field) => field.toJson()).toList(),
            },
          ),
          adLoginRequest: AdLoginRequest(
            user: authData.userName,
            pass: authData.password,
            lang: "es_PY",
            clientId: authData.selectedClient!.id,
            roleId: authData.selectedRole!.id,
            orgId: authData.selectedOrganization!.id,
            warehouseId: authData.selectedWarehouse!.id,
            stage: 9,
          ),
        ).toJson()
      };
      print(url);
      print(request);

      final response = await dio.post(url, data: request);

      if (response.statusCode == 200) {
        final standardResponse =
        StandardResponse.fromJson(response.data['StandardResponse']);
        print('StandardResponse ${standardResponse.toJson()}');
        if (standardResponse.isError == null ||
            standardResponse.isError == false) {
          Line lineResponse = Line(
            id: line.id,
          );
          return lineResponse;
        } else {
          throw Exception(standardResponse.error ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Error al cargar los datos de la línea ${line.line}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }*/

  @override
  Future<LineConfirm> updateLineConfirm(Line line, WidgetRef ref) async {
    await _dioInitialized;
    try {
      final String url =
          "/ADInterface/services/rest/model_adservice/update_data";
      print(url);
      final authData = ref.read(authProvider);
      final mInOutData = ref.read(mInOutProvider);

      String serviceType = 'UpdateInOutLineConfirm';
      String tableName = 'M_InOutLineConfirm';

      if (mInOutData.mInOutType == MInOutType.moveConfirm) {
        serviceType = 'UpdateMovementLineConfirm';
        tableName = 'M_MovementLineConfirm';
      }
      final request = {
        'ModelCRUDRequest': ModelCrudRequest(
          modelCrud: ModelCrud(
            serviceType: serviceType,
            tableName: tableName,
            recordId: line.confirmId,
            action: "Update",
            dataRow: {
              'field': [

                FieldCrud(
                    column: 'ConfirmedQty', val: line.confirmedQty.toString()),
                FieldCrud(
                    column: 'ScrappedQty', val: line.scrappedQty.toString()),
                FieldCrud(
                    column: 'Description',
                    val:
                        '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())} --> ${authData.userName} --> ${(line.manualQty ?? 0) > 0 ? 'Manual Confirm' : 'Scanner Confirm'} }'),
              ].map((field) => field.toJson()).toList(),
            },
          ),
          adLoginRequest: AdLoginRequest(
            user: authData.userName,
            pass: authData.password,
            lang: "es_PY",
            clientId: authData.selectedClient!.id,
            roleId: authData.selectedRole!.id,
            orgId: authData.selectedOrganization!.id,
            warehouseId: authData.selectedWarehouse!.id,
            stage: 9,
          ),
        ).toJson()
      };
      print(url);
      print(request);

      final response = await dio.post(url, data: request);

      if (response.statusCode == 200) {
        final standardResponse =
            StandardResponse.fromJson(response.data['StandardResponse']);
        print('StandardResponse ${standardResponse.toJson()}');
        if (standardResponse.isError == null ||
            standardResponse.isError == false) {
          LineConfirm lineResponse = LineConfirm(
            id: line.confirmId,
          );
          return lineResponse;
        } else {
          throw Exception(standardResponse.error ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Error al cargar los datos de la línea ${line.line}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<int> getLocator(String value, WidgetRef ref) async {
    await _dioInitialized;
    try {
      final String url =
          "/api/v1/models/m_locator?\$filter=Value%20eq%20'$value'";
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final responseApi =
            ResponseApi<Locate>.fromJson(response.data, Locate.fromJson);

        if (responseApi.records != null && responseApi.records!.isNotEmpty) {
          final locate = responseApi.records!.first;
          return locate.id!;
        } else {
          throw Exception('No se encontró el estante $value');
        }
      } else {
        throw Exception(
            'Error al cargar los datos del estante: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<bool> updateLocator(Line line, WidgetRef ref) async {
    print('update locator line : ${line.toJson()}');
    await _dioInitialized;
    try {
      final String url =
          "/ADInterface/services/rest/model_adservice/update_data";

      final authData = ref.read(authProvider);
      final mInOutData = ref.read(mInOutProvider);

      String serviceType = 'UpdateInOutLine';
      String tableName = 'M_InOutLine';
      String locator = 'M_Locator_ID';

      if (mInOutData.mInOutType == MInOutType.move ||
          mInOutData.mInOutType == MInOutType.moveConfirm) {
        serviceType = 'UpdateMovementLine';
        tableName = 'M_MovementLine';
        locator = 'M_Locator_ID';
      }

      final request = {
        'ModelCRUDRequest': ModelCrudRequest(
          modelCrud: ModelCrud(
            serviceType: serviceType,
            tableName: tableName,
            recordId: line.id,
            action: "Update",
            dataRow: {
              'field': [
                FieldCrud(
                    column: 'Description',
                    val:
                        '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())} --> ${authData.userName} --> ${line.mLocatorId!.identifier} --> ${line.editLocator.toString()}'),
                FieldCrud(column: locator, val: line.editLocator.toString()),
              ].map((field) => field.toJson()).toList(),
            },
          ),
          adLoginRequest: AdLoginRequest(
            user: authData.userName,
            pass: authData.password,
            lang: "es_PY",
            clientId: authData.selectedClient!.id,
            roleId: authData.selectedRole!.id,
            orgId: authData.selectedOrganization!.id,
            warehouseId: authData.selectedWarehouse!.id,
            stage: 9,
          ),
        ).toJson()
      };
      print('update locator line : $url');
      print('update locator line : $request');
      final response = await dio.post(url, data: request);

      if (response.statusCode == 200) {
        final standardResponse =
            StandardResponse.fromJson(response.data['StandardResponse']);
        if (standardResponse.isError == null ||
            standardResponse.isError == false) {
          return true;
        } else {
          throw Exception(standardResponse.error ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Error al cargar los datos de la línea ${line.line}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  @override
  Future<bool> updateMovementQty(Line line, WidgetRef ref) async {
    print('update movementQty line : ${line.toJson()}');
    await _dioInitialized;
    try {
      final String url =
          "/ADInterface/services/rest/model_adservice/update_data";

      final authData = ref.read(authProvider);
      final mInOutData = ref.read(mInOutProvider);

      String serviceType = 'UpdateInOutLine';
      String tableName = 'M_InOutLine';
      String columnToUpdate = 'MovementQty';

      if (mInOutData.mInOutType == MInOutType.move ||
          mInOutData.mInOutType == MInOutType.moveConfirm) {
        serviceType = 'UpdateMovementLine';
        tableName = 'M_MovementLine';
        columnToUpdate = 'MovementQty';
      }

      final request = {
        'ModelCRUDRequest': ModelCrudRequest(
          modelCrud: ModelCrud(
            serviceType: serviceType,
            tableName: tableName,
            recordId: line.id,
            action: "Update",
            dataRow: {
              'field': [
                FieldCrud(
                    column: 'Description',
                    val:
                    '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())} --> ${authData.userName} --> MovementQty --> ${line.movementQty.toString()}'),
                FieldCrud(column: columnToUpdate, val: line.confirmedQty.toString()),
              ].map((field) => field.toJson()).toList(),
            },
          ),
          adLoginRequest: AdLoginRequest(
            user: authData.userName,
            pass: authData.password,
            lang: "es_PY",
            clientId: authData.selectedClient!.id,
            roleId: authData.selectedRole!.id,
            orgId: authData.selectedOrganization!.id,
            warehouseId: authData.selectedWarehouse!.id,
            stage: 9,
          ),
        ).toJson()
      };
      print('update movementQty line : $url');
      print('update movementQty line : $request');
      final response = await dio.post(url, data: request);

      if (response.statusCode == 200) {
        final standardResponse =
        StandardResponse.fromJson(response.data['StandardResponse']);
        if (standardResponse.isError == null ||
            standardResponse.isError == false) {
          return true;
        } else {
          throw Exception(standardResponse.error ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Error al cargar los datos de la línea ${line.line}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  @override
  Future<bool> updateLineConfirmConfirmQty(LineConfirm line, WidgetRef ref) async {
    await _dioInitialized;

    final authData = ref.read(authProvider);
    final mInOutData = ref.read(mInOutProvider);

    // Model correcto según tipo
    final String modelName =
    (mInOutData.mInOutType == MInOutType.moveConfirm)
        ? 'M_MovementLineConfirm'
        : 'M_InOutLineConfirm';

    // Valor a escribir (tu flujo actual copia confirmedQty -> TargetQty)
    final double confirmedQty = (line.confirmedQty ?? 0).toDouble();

    // Payload mínimo: solo TargetQty + (opcional) Description
    final Map<String, dynamic> data = <String, dynamic>{
      'ConfirmedQty': confirmedQty,
      'Description':
      '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())} --> '
          '${authData.userName} --> ConfirmedQty(${line.targetQty ?? 0}) --> $confirmedQty',
    };

    try {
      debugPrint('updateLineConfirmTargetQty model=$modelName id=${line.id} data=$data');

      final int? id = line.id;
      if (id == null || id <= 0) {
        throw Exception('LineConfirm.id inválido: $id');
      }

      final resp = await updateDataByRESTAPI(
        modelName: modelName,
        id: id,
        data: data,
        ref: ref,
      );

      // Si llegó 200 en updateDataByRESTAPI, OK.
      return resp.statusCode == 200;
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /* @override
  Future<bool> updateLineConfirmTargetQty(LineConfirm line, WidgetRef ref) async {

    print('update LineConfirm movementQty line : ${line.toJson()}');
    //
    await _dioInitialized;
    try {
      final String url =
          "/ADInterface/services/rest/model_adservice/update_data";

      final authData = ref.read(authProvider);
      final mInOutData = ref.read(mInOutProvider);


      String serviceType = 'UpdateInOutLineConfirm';
      String tableName = 'M_InOutLineConfirm';

      if (mInOutData.mInOutType == MInOutType.moveConfirm) {
        serviceType = 'UpdateMovementLineConfirm';
        tableName = 'M_MovementLineConfirm';
      }


      final request = {
        'ModelCRUDRequest': ModelCrudRequest(
          modelCrud: ModelCrud(
            serviceType: serviceType,
            tableName: tableName,
            recordId: line.id,
            action: "Update",
            dataRow: {
              'field': [
                FieldCrud(
                    column: 'TargetQty', val: line.confirmedQty.toString()),
                FieldCrud(
                    column: 'ConfirmedQty', val: line.confirmedQty.toString()),
                FieldCrud(
                    column: 'ScrappedQty', val: '0'),
                FieldCrud(
                    column: 'Description',
                    val:
                    '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())} --> ${authData.userName} --> TargetQty --> ${line.confirmedQty}'),

              ].map((field) => field.toJson()).toList(),
            },
          ),
          adLoginRequest: AdLoginRequest(
            user: authData.userName,
            pass: authData.password,
            lang: "es_PY",
            clientId: authData.selectedClient!.id,
            roleId: authData.selectedRole!.id,
            orgId: authData.selectedOrganization!.id,
            warehouseId: authData.selectedWarehouse!.id,
            stage: 9,
          ),
        ).toJson()
      };
      print('update LineConfirm movementQty line : $url');
      print('update LineConfirm movementQty line : $request');
      final response = await dio.post(url, data: request);

      if (response.statusCode == 200) {
        final standardResponse =
        StandardResponse.fromJson(response.data['StandardResponse']);
        if (standardResponse.isError == null ||
            standardResponse.isError == false) {
          return true;
        } else {
          throw Exception(standardResponse.error ?? 'Unknown error');
        }
      } else {
        throw Exception(
            'Error al cargar los datos de la línea ${line.id}: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }*/


  @override
  Future<List<MInOut>> getMInOutListByDateRange({
    required WidgetRef ref,
    required DateTimeRange<DateTime> dates,
    required String inOut,
  }) async {
    await _dioInitialized;

    final mInOutState = ref.read(mInOutProvider);
    final int warehouseID = ref.read(authProvider).selectedWarehouse!.id;
    final String docStatus = ref.read(documentTypeListMInOutFilterProvider);

    String filterInOut = '';
    switch (inOut) {
      case MInOutListTypeX.ALL:
        filterInOut = '';
        break;
      case MInOutListTypeX.SHIPPING:
        filterInOut = 'IsSOTrx%20eq%20true%20AND%20';
        break;
      case MInOutListTypeX.RECEIVE:
        filterInOut = 'IsSOTrx%20eq%20false%20AND%20';
        break;
    }

    final String baseUrl =
        "/api/v1/models/m_inout?\$filter=$filterInOut"
        "M_Warehouse_ID%20eq%20$warehouseID%20AND%20(DocStatus%20eq%20'$docStatus')";

    final String dateSuffix = buildMovementDateFilterSuffix(dates);

    try {
      final meta = PaginationMeta();

      final list = await fetchAllPages<MInOut>(
        orderByColumn: 'M_InOut_ID',
        dio: dio,
        baseUrl: baseUrl,
        filterSuffix: dateSuffix,
        parser: MInOut.fromJson,
        outMeta: meta,
      );

      return list;
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception('Error al obtener la lista de ${mInOutState.title}: $e');
    }
  }



  @override
  Future<List<MInOut>> getMovementListByDateRange({
    required WidgetRef ref,
    required DateTimeRange<DateTime> dates,
    required String inOut, // no lo usas, lo dejo por firma
  }) async {
    await _dioInitialized;

    final int warehouseID = ref.read(authProvider).selectedWarehouse!.id;
    final mInOutState = ref.read(mInOutProvider);
    final String docStatus = ref.read(documentTypeListMInOutFilterProvider);

    final String baseUrl =
        "/api/v1/models/m_movement?\$filter="
        "(M_Warehouse_ID%20eq%20$warehouseID%20OR%20M_Warehouse_ID%20eq%20null)%20"
        "AND%20(DocStatus%20eq%20'$docStatus')";

    final String dateSuffix = buildMovementDateFilterSuffix(dates);

    try {
      final meta = PaginationMeta();

      final list = await fetchAllPages<MInOut>(
        orderByColumn: 'M_Movement_ID',
        dio: dio,
        baseUrl: baseUrl,
        filterSuffix: dateSuffix,
        parser: MInOut.fromJson,
        outMeta: meta,
      );

      return list;
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception('Error al obtener la lista de ${mInOutState.title}: $e');
    }
  }

  @override
  Future<List<LineConfirm>> getLinesMInOutConfirm(
      int mInOutConfirmId,
      WidgetRef ref,
      ) async {
    await _dioInitialized;
    final mInOutState = ref.read(mInOutProvider);
    final List<LineConfirm> allLines = [];
    int skip = 0;
    bool hasMoreRecords = true;

    try {
      while (hasMoreRecords) {
        final String url =
            "/api/v1/models/m_inoutlineconfirm?\$filter=M_InOutConfirm_ID%20eq%20$mInOutConfirmId&orderby=M_InOutLineConfirm_ID&\$skip=$skip";
        debugPrint(url);
        final response = await dio.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              'Error loading ${mInOutState.title} data: ${response.statusCode}');
        }

        final responseApi = ResponseApi<LineConfirm>.fromJson(
            response.data, LineConfirm.fromJson);

        if (responseApi.records == null || responseApi.records!.isEmpty) {
          if (skip == 0) {
            throw Exception('No records found for ${mInOutState.title}');
          }
          break;
        }

        allLines.addAll(responseApi.records!);
        skip += responseApi.records!.length;
        hasMoreRecords = responseApi.rowCount! > skip;
      }

      return allLines;
    } on DioException catch (e) {
      final authDataNotifier = ref.read(authProvider.notifier);
      throw CustomErrorDioException(e, authDataNotifier);
    } catch (e) {
      throw Exception(e.toString());
    }
  }






}
