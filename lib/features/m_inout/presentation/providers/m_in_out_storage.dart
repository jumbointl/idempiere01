// features/m_inout/presentation/providers/m_in_out_storage.dart

import 'dart:convert';
import 'package:get_storage/get_storage.dart';

import 'm_in_out_status.dart';

const String KEY_SAVED_MINOUT_V1_TYPE = 'saved_m_inout_v1_type';
const String KEY_SAVED_MINOUT_LIST_V1_ = 'saved_m_inout_list_v1_';

String keySaveMInOutList(String typeName) => '$KEY_SAVED_MINOUT_LIST_V1_$typeName';

class MergeMInOutResult {
  final bool ok;
  final String message;
  final int mergedLines;
  const MergeMInOutResult({required this.ok, required this.message, this.mergedLines = 0});
}

// --- build payload ---
Map<String, dynamic>? buildSaveMInOutPayload(MInOutStatus stateNow) {
  final hasDoc = stateNow.doc.trim().isNotEmpty;
  final hasLines = (stateNow.mInOut?.lines.isNotEmpty ?? false) ||
      (stateNow.mInOut?.allLines.isNotEmpty ?? false);
  final hasBarcodes = stateNow.scanBarcodeListTotal.isNotEmpty ||
      stateNow.scanBarcodeListUnique.isNotEmpty;

  if (!hasDoc && !hasLines && !hasBarcodes) return null;

  return <String, dynamic>{
    'version': 1,
    'savedAt': DateTime.now().toIso8601String(),
    'doc': stateNow.doc,
    'mInOutType': stateNow.mInOutType.name,
    'title': stateNow.title,
    'isSOTrx': stateNow.isSOTrx,
    'viewMInOut': stateNow.viewMInOut,
    'uniqueView': stateNow.uniqueView,
    'orderBy': stateNow.orderBy,
    'manualQty': stateNow.manualQty,
    'scrappedQty': stateNow.scrappedQty,
    'editLocator': stateNow.editLocator,
    'isComplete': stateNow.isComplete,
    'usingRolQuickComplete': stateNow.usingRolQuickComplete,
    'mInOut': stateNow.mInOut?.toJson(),
    'mInOutConfirm': stateNow.mInOutConfirm?.toJson(),
    'scanBarcodeListTotal': stateNow.scanBarcodeListTotal.map((b) => b.toJson()).toList(),
    'scanBarcodeListUnique': stateNow.scanBarcodeListUnique.map((b) => b.toJson()).toList(),
    'linesOver': stateNow.linesOver.map((b) => b.toJson()).toList(),
    'mInOutConfirmList': stateNow.mInOutConfirmList.map((c) => c.toJson()).toList(),
  };
}

List<Map<String, dynamic>> readSavedPayloadList({required GetStorage box, required String key}) {
  final raw = box.read(key);
  if (raw == null || raw.toString().trim().isEmpty) return <Map<String, dynamic>>[];
  try {
    final decoded = jsonDecode(raw is String ? raw : raw.toString());
    if (decoded is List) return decoded.whereType<Map<String, dynamic>>().toList();
  } catch (_) {}
  return <Map<String, dynamic>>[];
}

void writeSavedPayloadList({required GetStorage box, required String key, required List<Map<String, dynamic>> list}) {
  box.write(key, jsonEncode(list));
}

String payloadDocumentNo(Map<String, dynamic> payload) {
  final m = payload['mInOut'];
  if (m is Map<String, dynamic>) {
    final doc = (m['documentNo'] ?? '').toString().trim();
    if (doc.isNotEmpty) return doc;
  }
  return (payload['doc'] ?? '').toString().trim();
}

String payloadSavedAt(Map<String, dynamic> payload) => (payload['savedAt'] ?? '').toString();