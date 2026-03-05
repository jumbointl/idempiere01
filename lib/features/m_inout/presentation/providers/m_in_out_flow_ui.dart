import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

import 'm_in_out_providers.dart'; // donde están: mInOutProvider, buildSaveMInOutPayload, keySaveMInOutList, readSavedPayloadList, payloadDocumentNo, _writeSavedPayloadList
import '../../../products/common/messages_dialog.dart';
import 'm_in_out_storage.dart'; // tus toasts / dialogs

void mergeMInOut(BuildContext context, WidgetRef ref) {
  final notifier = ref.read(mInOutProvider.notifier);

  final result = notifier.mergeFromStorage();

  if (!result.ok) {
    showErrorMessage(context, ref, result.message);
    return;
  }

  if (!context.mounted) return;
  showSuccessMessage(context, ref, result.message);
}

/// Guarda en LISTA por tipo:
/// - key = saved_m_inout_list_v1_<type>
/// - dedup por documentNo
/// - keep last 10
void saveMInOut(BuildContext context, WidgetRef ref) {
  final box = GetStorage();
  final stateNow = ref.read(mInOutProvider);

  final payload = buildSaveMInOutPayload(stateNow);

  if (payload == null) {
    if (context.mounted) {
      showWarningCenterToast(
        context,
        'No hay datos para guardar.',
        durationSeconds: 3,
      );
    }
    return;
  }

  try {
    final typeName = stateNow.mInOutType.name;
    final key = keySaveMInOutList(typeName);

    // 1) leer lista existente (por tipo)
    final list = readSavedPayloadList(box: box, key: key);

    // 2) dedup por documentNo
    final newDoc = payloadDocumentNo(payload);
    final filtered = list.where((p) => payloadDocumentNo(p) != newDoc).toList();

    // 3) insertar newest first
    filtered.insert(0, payload);

    // 4) keep last 10
    final trimmed = filtered.take(10).toList();

    // 5) escribir lista
    writeSavedPayloadList(box: box, key: key, list: trimmed);

    // opcional: guardar “último tipo usado”
    box.write(KEY_SAVED_MINOUT_V1_TYPE, typeName);

    // (opcional) si querés mantener compatibilidad legacy, podés también guardar el último payload:
    // box.write(KEY_SAVED_MINOUT_V1, jsonEncode(payload));

    if (context.mounted) {
      showSuccessCenterToast(
        context,
        'Guardado local OK ✅ ($typeName)',
        durationSeconds: 3,
      );
    }
  } catch (e) {
    if (context.mounted) {
      showErrorCenterToast(
        context,
        'Error al guardar: $e',
        durationSeconds: 5,
      );
    }
  }
}