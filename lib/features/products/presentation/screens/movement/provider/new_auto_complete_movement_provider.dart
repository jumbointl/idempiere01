import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/config/http/dio_client.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/domain/sql/common_sql_data.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import 'new_movement_provider.dart';

final fireAutoCompleteMovementProvider =
StateProvider.autoDispose<int>((ref) {
  return 0;
});

final autoCompleteMovementDraftProvider =
StateProvider.autoDispose<PutAwayMovement?>((ref) {
  return null;
});

final newAutoCompleteMovementProvider =
FutureProvider.autoDispose<MovementAndLines?>((ref) async {
  final count = ref.watch(fireAutoCompleteMovementProvider);
  if (count == 0) return null;

  final PutAwayMovement? draft = ref.read(autoCompleteMovementDraftProvider);
  if (draft == null) return null;

  final dio = await DioClient.create();
  MemoryProducts.movementAndLines = MovementAndLines(user: Memory.sqlUsersData);

  String step = 'Movement create start';
  int errorId = Memory.ERROR_DOCUMENT_NOT_CREATED_ID;
  String createdMovementId = '';

  try {
    final String url = draft.movementInsertUrl ?? '';
    final Map<String, dynamic>? payload =
    draft.movementToCreate?.getInsertForSwitchBetweenLocatorJson(
      description: Memory.getDescriptionFromApp(),
    );

    if (url.isEmpty || payload == null) return null;

    final response = await dio.post(url, data: payload);

    if (response.statusCode != 201) {
      return MovementAndLines(
        id: Memory.ERROR_ID,
        name:
        '${Messages.ERROR}${response.statusCode} : ${response.statusMessage}',
      );
    }

    errorId = Memory.ERROR_DOCUMENT_LINE_NOT_CREATED_ID;

    IdempiereMovement createdMovement =
    IdempiereMovement.fromJson(response.data);

    step = 'Movement created id: ${createdMovement.id ?? 0}';
    debugPrint(step);

    createdMovementId = createdMovement.id?.toString() ?? '';

    if (createdMovement.id == null || createdMovement.id! <= 0) {
      return MovementAndLines(
        id: errorId,
        name: createdMovementId,
        description: Messages.ERROR_DOCUMENT_NOT_CREATED,
      );
    }

    MemoryProducts.movementAndLines.cloneMovement(createdMovement);
    draft.movementLineToCreate!.mMovementID = createdMovement;

    final Map<String, dynamic>? linePayload =
    draft.getInsertForSwitchBetweenLocatorJson(
      description: Memory.getDescriptionFromApp(),
    );

    final String lineUrl = draft.movementLineInsertUrl ?? '';

    if (linePayload == null || lineUrl.isEmpty) {
      return MovementAndLines(
        id: errorId,
        name: createdMovementId,
        description: 'Movement line payload is null or line url is empty',
      );
    }

    final responseLine = await dio.post(lineUrl, data: linePayload);

    if (responseLine.statusCode != 201) {
      return MovementAndLines(
        id: errorId,
        name: createdMovementId,
        description:
        '${Messages.ERROR_DOCUMENT_NOT_CREATED} line ${responseLine.statusCode} : ${responseLine.statusMessage}',
      );
    }

    final IdempiereMovementLine movementLine =
    IdempiereMovementLine.fromJson(responseLine.data);

    step = 'MovementLine created id: ${movementLine.id ?? 0}';
    debugPrint(step);

    MemoryProducts.movementAndLines.movementLines = [movementLine];

    errorId = Memory.ERROR_DOCUMENT_NOT_COMPLETE_ID;

    SqlDataMovement updateMovement = SqlDataMovement(id: createdMovement.id);
    Memory.sqlUsersData.copyToSqlData(updateMovement);

    final String updateUrl = updateMovement.getUpdateUrl();
    final Map<String, dynamic> updatePayload =
    createdMovement.getUpdateDocStatusJson(
      CommonSqlData.DOC_COMPLETE_STATUS,
    );

    final responseComplete = await dio.put(updateUrl, data: updatePayload);

    if (responseComplete.statusCode == 200) {
      step = 'Movement completed id: ${createdMovement.id ?? 0}';
      debugPrint(step);

      createdMovement = SqlDataMovement.fromJson(responseComplete.data);

      final result = ref.read(movementAndLinesProvider);
      result.cloneMovement(createdMovement);

      if (MemoryProducts.movementAndLines.movementLines != null) {
        result.movementLines = MemoryProducts.movementAndLines.movementLines;
      }

      ref.read(movementAndLinesProvider.notifier).state = result;
      MemoryProducts.movementAndLines = result;

      return result;
    }

    return MovementAndLines(
      id: errorId,
      name: createdMovementId,
      description: Messages.ERROR_DOCUMENT_NOT_COMPLETED,
    );
  } on DioException catch (e) {
    debugPrint('DioException');
    final String title = e.response?.data['title'] ?? '';
    final dynamic status = e.response?.data['status'] ?? '';
    final String detail = e.response?.data['detail'] ?? '';

    String message = 'Title : $title\nStatus : $status\nDetail : $detail';
    if (title.isEmpty && detail.isEmpty) {
      message = e.toString();
    }

    return MovementAndLines(
      id: Memory.ERROR_ID,
      name: '${Messages.ERROR} : $message',
    );
  } catch (e) {
    debugPrint('Exception on step: $step');
    debugPrint(e.toString());

    return MovementAndLines(
      id: Memory.ERROR_ID,
      name: '${Messages.ERROR} ${e.toString()}',
    );
  }
});