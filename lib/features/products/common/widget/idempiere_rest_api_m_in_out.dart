import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../m_inout/domain/entities/line.dart';
import '../../../m_inout/domain/entities/m_in_out.dart';
import '../../../m_inout/presentation/providers/m_in_out_providers.dart';
import '../../../products/domain/idempiere/response_async_value.dart';

// Assumes you already have these:
// - mInOutProvider (state contains mInOut, isMovement, isConfirmFlow, etc.)
// - updateDataByRESTAPIBatchResponseAsyncValue
// - batchDataByRESTAPI
import '../idempiere_rest_api.dart';


bool canEditLocatorInOutLine = false;

Future<ResponseAsyncValue> confirmMInOutByRESTAPIBatch({
  required BuildContext context,
  required WidgetRef ref,
  required String status,
}) async {
  final mInOutState = ref.read(mInOutProvider);
  final MInOut? mInOut = mInOutState.mInOut;

  // English comment: "Validate header"
  if (mInOut == null) {
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'MInOut is null. Cannot confirm.',
    );
  }

  if (mInOut.id == null || mInOut.id! <= 0) {
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'Invalid MInOut.id. Cannot confirm.',
    );
  }

  // English comment: "Pick correct line model"
  final bool isMovement = mInOutState.isMovement;
  final bool isConfirmFlow = mInOutState.isConfirmFlow;

  final String lineModelName = isMovement ? 'm_movementline' : 'm_inoutline';
  final List<Line> lines = mInOut.lines;

  if (lines.isEmpty) {
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'No lines to confirm.',
    );
  }

  // English comment: "Build group 1 (lines)"
  final List<int?> ids = <int?>[];
  final List<Map<String, dynamic>> dataList = <Map<String, dynamic>>[];

  for (final line in lines) {
    ids.add(line.id);

    final payload = <String, dynamic>{
      // English comment: "Keep same behavior as your single-line update"
      'MovementQty': (line.confirmedQty ?? 0.0),
      if (!isMovement) 'QtyEntered': (line.confirmedQty ?? 0.0),

      // Same logic you had:
      // if(!isConfirmFlow) 'ConfirmedQty' :(line.confirmedQty ?? 0)
      if (!isConfirmFlow) 'ConfirmedQty': (line.confirmedQty ?? 0),

      // Same logic you had (only if not movement and docStatus is DR)
      if (canEditLocatorInOutLine && line.editLocator!=null && line.editLocator!>0 )
        'M_Locator_ID': line.editLocator!,
    };

    dataList.add(payload);
  }

  // English comment: "Build group 2 (header doc-action)"
  final String headerModelName = 'minout'; // as requested
  final List<int?> ids2 = <int?>[mInOut.id];
  final List<Map<String, dynamic>> dataList2 = <Map<String, dynamic>>[
    <String, dynamic>{'doc-action': status},
  ];

  // English comment: "Execute both groups in a single batch transaction"
  final result = await updateDataByRESTAPIBatchResponseAsyncValue(
    modelName: lineModelName,
    ids: ids,
    dataList: dataList,
    modelName2: headerModelName,
    ids2: ids2,
    dataList2: dataList2,
    ref: ref,
    successMessage: 'Lines updated',
    successMessage2: 'MInOut doc-action sent',
  );

  return result;
}