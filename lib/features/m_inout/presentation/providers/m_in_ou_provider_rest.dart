import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/line.dart';
import '../../domain/entities/line_confirm.dart';
import '../../domain/entities/m_in_out.dart';
import 'm_in_out_providers.dart';
import 'm_in_out_type.dart';

List<Map<String, dynamic>> buildBatchOpsForMinOutSetDocAction({
  required WidgetRef ref,
  required MInOut mInOut,
  required List<Line> linesToUpdate,
  required List<LineConfirm> lineConfirmsToUpdate,
  required String docStatusToSet, // e.g. "CO"
}) {
  final mInOutState = ref.read(mInOutProvider);
  final authData = ref.read(authProvider);

  final bool isMovement = mInOutState.isMovement;
  final bool isConfirmFlow = mInOutState.isConfirmFlow;

  final String lineModelName = isMovement ? 'm_movementline' : 'm_inoutline';

  // Model name for lineConfirm depends on your confirm type
  final String lineConfirmModelName =
  (mInOutState.mInOutType == MInOutType.moveConfirm)
      ? 'M_MovementLineConfirm'
      : 'M_InOutLineConfirm';

  final ops = <Map<String, dynamic>>[];

  // 1) Update movement/inout lines
  for (var i = 0; i < linesToUpdate.length; i++) {
    final line = linesToUpdate[i];
    final id = line.id;

    // English comment: "Skip invalid IDs (or throw if you prefer strict)"
    if (id == null || id <= 0) continue;

    final payload = <String, dynamic>{
      'MovementQty': (line.confirmedQty ?? 0.0),
      if (!isMovement) 'QtyEntered': (line.confirmedQty ?? 0.0),
      if (!isConfirmFlow) 'ConfirmedQty': (line.confirmedQty ?? 0),
      if (line.editLocator != null && line.editLocator! > 0)
        'M_Locator_ID': line.editLocator!,
    };

    final op = {
      "method": "PUT",
      // Batch manual: singular "model"
      "path": "v1/model/$lineModelName/$id",
      "body": payload,
    };

    debugPrint('Batch line op $i -> $op');
    ops.add(op);
  }

  // 2) Update lineConfirm rows (ConfirmedQty + Description)
  for (var i = 0; i < lineConfirmsToUpdate.length; i++) {
    final lc = lineConfirmsToUpdate[i];
    final id = lc.id;

    if (id == null || id <= 0) continue;

    final confirmedQty = (lc.confirmedQty ?? 0).toDouble();

    final data = <String, dynamic>{
      'ConfirmedQty': confirmedQty,
      'Description':
      '${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())} --> '
          '${authData.userName} --> ConfirmedQty(${lc.targetQty ?? 0}) --> $confirmedQty',
    };

    final op = {
      "method": "PUT",
      "path": "v1/model/$lineConfirmModelName/$id",
      "body": data,
    };

    debugPrint('Batch lineConfirm op $i -> $op');
    ops.add(op);
  }

  // 3) SetDocAction / DocStatus on header (m_inout)
  final headerId = mInOut.id;
  if (headerId != null && headerId > 0) {
    final op = {
      "method": "PUT",
      "path": "v1/model/m_inout/$headerId",
      "body": {
        "DocStatus": docStatusToSet, // e.g. "CO"
      }
    };

    debugPrint('Batch header op -> $op');
    ops.add(op);
  }

  return ops;
}