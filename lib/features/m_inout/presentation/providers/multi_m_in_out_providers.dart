import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';

import '../../domain/entities/line.dart';
import '../../domain/entities/m_in_out.dart';
import '../../infrastructure/repositories/m_in_out_repository_impl.dart';
import '../../../products/common/idempiere_rest_api.dart';
import 'm_in_out_providers.dart';
import 'multi_m_in_out_session.dart';

/// State for the Multiple Receipt screen. Holds N concurrent MInOut sessions
/// and a global scan list, plus completed sessions in a separate bucket.
class MultiMInOutState {
  final String type; // currently always 'receipt'
  final List<MultiMInOutSession> activeSessions;
  final List<MultiMInOutSession> completedSessions;
  final List<MultiScannedBarcode> globalScans;
  final bool isLoading;
  final String errorMessage;

  const MultiMInOutState({
    this.type = 'receipt',
    this.activeSessions = const <MultiMInOutSession>[],
    this.completedSessions = const <MultiMInOutSession>[],
    this.globalScans = const <MultiScannedBarcode>[],
    this.isLoading = false,
    this.errorMessage = '',
  });

  MultiMInOutState copyWith({
    String? type,
    List<MultiMInOutSession>? activeSessions,
    List<MultiMInOutSession>? completedSessions,
    List<MultiScannedBarcode>? globalScans,
    bool? isLoading,
    String? errorMessage,
  }) =>
      MultiMInOutState(
        type: type ?? this.type,
        activeSessions: activeSessions ?? this.activeSessions,
        completedSessions: completedSessions ?? this.completedSessions,
        globalScans: globalScans ?? this.globalScans,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'activeSessions': activeSessions.map((s) => s.toJson()).toList(),
        'completedSessions': completedSessions.map((s) => s.toJson()).toList(),
        'globalScans': globalScans.map((s) => s.toJson()).toList(),
      };

  factory MultiMInOutState.fromJson(Map<String, dynamic> json) =>
      MultiMInOutState(
        type: json['type']?.toString() ?? 'receipt',
        activeSessions: (json['activeSessions'] as List?)
                ?.map((e) => MultiMInOutSession.fromJson(
                    (e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        completedSessions: (json['completedSessions'] as List?)
                ?.map((e) => MultiMInOutSession.fromJson(
                    (e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
        globalScans: (json['globalScans'] as List?)
                ?.map((e) => MultiScannedBarcode.fromJson(
                    (e as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}

/// Storage key for persisted Multiple Receipt state per type.
String _multiStorageKey(String type) => 'saved_multi_m_inout_v1_$type';

/// Riverpod provider.
final multiMInOutProvider =
    StateNotifierProvider<MultiMInOutNotifier, MultiMInOutState>((ref) {
  return MultiMInOutNotifier(ref: ref);
});

/// Holds the value entered by the user in `getDoubleDialog` when editing a
/// line quantity from the multi-receipt Líneas tab.
final multiReceiptEditQtyProvider = StateProvider.autoDispose<double>((ref) => 0);

class MultiMInOutNotifier extends StateNotifier<MultiMInOutState> {
  final Ref ref;
  final _repo = MInOutRepositoryImpl();
  final _storage = GetStorage();
  int _sessionSeq = 0;

  MultiMInOutNotifier({required this.ref}) : super(const MultiMInOutState());

  // ---------------- INIT / RESTORE ----------------

  /// Prime the singleton MInOut state with the right type so the underlying
  /// datasource builds the correct URL (IsSOTrx etc.). Called once when the
  /// screen mounts. Does NOT load any document into the singleton.
  void primeForType(String type, WidgetRef widgetRef) {
    ref.read(mInOutProvider.notifier).setParameters(type);
    state = state.copyWith(type: type);
  }

  /// Restore previously saved state from GetStorage (if any).
  Future<void> restoreFromStorage() async {
    try {
      final raw = _storage.read(_multiStorageKey(state.type));
      if (raw == null) return;
      final map = raw is String
          ? (jsonDecode(raw) as Map).cast<String, dynamic>()
          : (raw as Map).cast<String, dynamic>();
      final restored = MultiMInOutState.fromJson(map);
      state = state.copyWith(
        activeSessions: restored.activeSessions,
        completedSessions: restored.completedSessions,
        globalScans: restored.globalScans,
      );
      _sessionSeq = restored.activeSessions.length +
          restored.completedSessions.length;
    } catch (e) {
      debugPrint('multi: restore failed $e');
    }
  }

  /// Persist current state. Called after every meaningful mutation so the
  /// session can be recovered after killing the app.
  Future<void> _persist() async {
    try {
      _storage.write(
        _multiStorageKey(state.type),
        jsonEncode(state.toJson()),
      );
    } catch (e) {
      debugPrint('multi: persist failed $e');
    }
  }

  /// Public save trigger ("Grabar" button).
  Future<void> save() => _persist();

  Future<void> clearAll() async {
    state = state.copyWith(
      activeSessions: const [],
      completedSessions: const [],
      globalScans: const [],
    );
    await _storage.remove(_multiStorageKey(state.type));
  }

  // ---------------- SESSION MANAGEMENT ----------------

  /// Internal helper: fetch a MInOut by documentNo silently. Returns null on
  /// any failure (including not-found). Does NOT mutate state on error.
  Future<MInOut?> _tryFetchMInOut(
    String documentNo,
    WidgetRef widgetRef,
  ) async {
    try {
      ref.read(mInOutProvider.notifier).setParameters(state.type);
      return await _repo.getMInOut(documentNo, widgetRef);
    } catch (_) {
      return null;
    }
  }

  /// Add a session from an already-fetched MInOut (used after picking from
  /// the available-documents list).
  Future<bool> addSessionFromMInOut(MInOut mInOut) async {
    final docNo = mInOut.documentNo ?? '';
    if (docNo.isEmpty) return false;
    if (state.activeSessions.any((s) => s.documentNo == docNo)) {
      state = state.copyWith(errorMessage: 'Documento $docNo ya está agregado');
      return false;
    }
    _sessionSeq++;
    final session = MultiMInOutSession(
      sessionId: 's${DateTime.now().millisecondsSinceEpoch}_$_sessionSeq',
      colorIndex:
          state.activeSessions.length + state.completedSessions.length,
      mInOut: mInOut,
    );
    state = state.copyWith(
      activeSessions: [...state.activeSessions, session],
    );
    await _persist();
    return true;
  }

  Future<bool> addSessionByDocumentNo(
    String documentNo,
    WidgetRef widgetRef,
  ) async {
    final trimmed = documentNo.trim();
    if (trimmed.isEmpty) return false;

    if (state.activeSessions.any((s) => s.documentNo == trimmed)) {
      state = state.copyWith(
        errorMessage: 'Documento $trimmed ya está agregado',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');
    final mInOut = await _tryFetchMInOut(trimmed, widgetRef);
    state = state.copyWith(isLoading: false);
    if (mInOut == null) {
      state = state.copyWith(
        errorMessage: 'Documento $trimmed no encontrado',
      );
      return false;
    }
    return addSessionFromMInOut(mInOut);
  }

  Future<void> removeSession(String sessionId) async {
    state = state.copyWith(
      activeSessions: state.activeSessions
          .where((s) => s.sessionId != sessionId)
          .toList(growable: false),
    );
    await _persist();
  }

  /// Fetch the list of available MInOut documents in DR/IP state for the
  /// current type, excluding documents already open in this session.
  Future<List<MInOut>> fetchAvailableDocs(WidgetRef widgetRef) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      ref.read(mInOutProvider.notifier).setParameters(state.type);
      final list = await _repo.getMInOutList(widgetRef);
      final activeDocs =
          state.activeSessions.map((s) => s.documentNo).toSet();
      state = state.copyWith(isLoading: false);
      return list
          .where((m) =>
              m.documentNo != null && !activeDocs.contains(m.documentNo))
          .toList();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return const [];
    }
  }

  // ---------------- SCAN DISPATCH ----------------

  /// Add a barcode and dispatch it. Resolution order:
  ///   1. Match against UPC of lines in any active session.
  ///   2. If no UPC match → try as DocumentNo (auto-add new session).
  ///   3. Else → mark unmatched.
  ///
  /// Returns a [DispatchOutcome] describing what happened so the UI can react
  /// (show chooser dialog, show "session added" toast, show "no encontrado").
  Future<DispatchOutcome> dispatchBarcodeAsync(
    String code,
    WidgetRef widgetRef,
  ) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return const DispatchOutcome._(DispatchMode.empty);

    // 1. UPC match across all active sessions.
    final candidates = <MapEntry<MultiMInOutSession, List<Line>>>[];
    for (final s in state.activeSessions) {
      final matches = s.linesMatchingUpc(trimmed);
      if (matches.isNotEmpty) candidates.add(MapEntry(s, matches));
    }

    if (candidates.length == 1 && candidates.first.value.length == 1) {
      final session = candidates.first.key;
      final line = candidates.first.value.first;
      _confirmInternal(session.sessionId, line.id, 1);
      _appendScan(MultiScannedBarcode(
        code: trimmed,
        sessionId: session.sessionId,
        sessionColorIndex: session.colorIndex,
        scannedAt: DateTime.now(),
        resolution: 'matched',
      ));
      _appendBarcodeToSession(session.sessionId, trimmed);
      await _persist();
      return const DispatchOutcome._(DispatchMode.auto);
    }

    if (candidates.isNotEmpty) {
      _appendScan(MultiScannedBarcode(
        code: trimmed,
        scannedAt: DateTime.now(),
        resolution: 'pending_choice',
      ));
      await _persist();
      return DispatchOutcome._(DispatchMode.choice, candidates: candidates);
    }

    // 2. No UPC match → try as DocumentNo.
    final alreadyOpen =
        state.activeSessions.any((s) => s.documentNo == trimmed);
    if (!alreadyOpen) {
      final mInOut = await _tryFetchMInOut(trimmed, widgetRef);
      if (mInOut != null) {
        await addSessionFromMInOut(mInOut);
        _appendScan(MultiScannedBarcode(
          code: trimmed,
          scannedAt: DateTime.now(),
          resolution: 'document_added',
        ));
        await _persist();
        return DispatchOutcome._(
          DispatchMode.documentAdded,
          documentNo: trimmed,
        );
      }
    }

    // 3. Unmatched.
    _appendScan(MultiScannedBarcode(
      code: trimmed,
      scannedAt: DateTime.now(),
      resolution: 'unmatched',
    ));
    await _persist();
    return const DispatchOutcome._(DispatchMode.unmatched);
  }

  /// User picked a (session, line) from the chooser dialog.
  Future<void> resolveChoice(
    String code,
    String sessionId,
    int? lineId,
  ) async {
    _confirmInternal(sessionId, lineId, 1);
    final session =
        state.activeSessions.firstWhere((s) => s.sessionId == sessionId);
    _appendBarcodeToSession(sessionId, code);

    // Update the last pending_choice scan with resolved sessionId.
    final scans = [...state.globalScans];
    for (var i = scans.length - 1; i >= 0; i--) {
      if (scans[i].code == code &&
          scans[i].resolution == 'pending_choice' &&
          scans[i].sessionId == null) {
        scans[i] = MultiScannedBarcode(
          code: code,
          sessionId: sessionId,
          sessionColorIndex: session.colorIndex,
          scannedAt: scans[i].scannedAt,
          resolution: 'matched',
        );
        break;
      }
    }
    state = state.copyWith(globalScans: scans);
    await _persist();
  }

  void _appendScan(MultiScannedBarcode scan) {
    state = state.copyWith(globalScans: [...state.globalScans, scan]);
    _persist();
  }

  void _appendBarcodeToSession(String sessionId, String code) {
    state = state.copyWith(
      activeSessions: state.activeSessions
          .map((s) => s.sessionId == sessionId
              ? s.copyWith(scannedBarcodes: [...s.scannedBarcodes, code])
              : s)
          .toList(growable: false),
    );
  }

  void _confirmInternal(String sessionId, int? lineId, double delta) {
    state = state.copyWith(
      activeSessions: state.activeSessions.map((s) {
        if (s.sessionId != sessionId) return s;
        final updatedLines = s.mInOut.lines.map((l) {
          if (l.id != lineId) return l;
          return l.copyWith(
            confirmedQty: (l.confirmedQty ?? 0) + delta,
          );
        }).toList(growable: false);
        return s.copyWith(
          mInOut: s.mInOut.copyWith(lines: updatedLines),
        );
      }).toList(growable: false),
    );
  }

  /// Manual line confirmation (used from the Líneas tab).
  Future<void> bumpLineQty(
    String sessionId,
    int? lineId,
    double delta,
  ) async {
    _confirmInternal(sessionId, lineId, delta);
    await _persist();
  }

  /// Replace a line's confirmedQty with an absolute value.
  /// Used by the Editar button + getDoubleDialog flow.
  Future<void> setLineQty(
    String sessionId,
    int? lineId,
    double qty,
  ) async {
    state = state.copyWith(
      activeSessions: state.activeSessions.map((s) {
        if (s.sessionId != sessionId) return s;
        final updatedLines = s.mInOut.lines.map((l) {
          if (l.id != lineId) return l;
          return l.copyWith(confirmedQty: qty);
        }).toList(growable: false);
        return s.copyWith(
          mInOut: s.mInOut.copyWith(lines: updatedLines),
        );
      }).toList(growable: false),
    );
    await _persist();
  }

  // ---------------- COMPLETE ----------------

  /// Push line quantities to iDempiere then drive doc-action DR → PR → CO
  /// and finally move the session to the completed bucket.
  /// Mirrors the receipt branch of `MInOutNotifier.setDocAction` but operates
  /// on a specific session, never touching the singleton state.
  Future<bool> completeSession(String sessionId, WidgetRef widgetRef) async {
    final idx =
        state.activeSessions.indexWhere((s) => s.sessionId == sessionId);
    if (idx < 0) return false;
    var session = state.activeSessions[idx];

    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      // 1. Push each line's actual received quantity.
      for (final line in session.mInOut.lines) {
        if (line.id == null) continue;
        final qty = line.confirmedQty ?? 0;
        await updateDataByRESTAPI(
          modelName: 'm_inoutline',
          id: line.id!,
          data: {
            'MovementQty': qty,
            'QtyEntered': qty,
            'ConfirmedQty': qty,
          },
          ref: widgetRef,
        );
      }

      // 2. Doc-action loop: DR → PR, then IP → CO.
      var current = session.mInOut.docStatus.id ?? 'DR';
      var attempts = 0;
      while ((current == 'DR' || current == 'IP') && attempts < 3) {
        final next = current == 'DR' ? 'PR' : 'CO';
        if (session.mInOut.id == null) break;
        await updateDocumentStatusByRESTAPI(
          modelName: 'M_InOut',
          id: session.mInOut.id!,
          ref: widgetRef,
          status: next,
        );
        await Future.delayed(const Duration(seconds: 2));
        final refreshed =
            await _tryFetchMInOut(session.documentNo, widgetRef);
        if (refreshed == null) break;
        current = refreshed.docStatus.id ?? current;
        session = session.copyWith(mInOut: refreshed);
        attempts++;
      }

      state = state.copyWith(isLoading: false);

      if (current == 'CO') {
        final newActive = [...state.activeSessions]..removeAt(idx);
        final completed = session.copyWith(status: 'completed');
        state = state.copyWith(
          activeSessions: newActive,
          completedSessions: [...state.completedSessions, completed],
        );
        await _persist();
        return true;
      }

      // Document didn't reach CO — surface error and keep session active with
      // its refreshed mInOut so the user can retry.
      final newActive = [...state.activeSessions];
      newActive[idx] = session;
      state = state.copyWith(
        activeSessions: newActive,
        errorMessage: 'No se pudo completar (status final: $current)',
      );
      await _persist();
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ---------------- ERRORS ----------------
  void clearError() {
    if (state.errorMessage.isNotEmpty) {
      state = state.copyWith(errorMessage: '');
    }
  }
}

/// Outcome of [MultiMInOutNotifier.dispatchBarcodeAsync].
enum DispatchMode {
  /// Empty input.
  empty,

  /// Single UPC match auto-confirmed.
  auto,

  /// Multiple matches — caller must show chooser using [DispatchOutcome.candidates].
  choice,

  /// No UPC match; the code resolved to a DocumentNo and a new session was
  /// added automatically.
  documentAdded,

  /// No UPC match and not a known DocumentNo.
  unmatched,
}

class DispatchOutcome {
  final DispatchMode mode;
  final List<MapEntry<MultiMInOutSession, List<Line>>> candidates;
  final String? documentNo;

  const DispatchOutcome._(
    this.mode, {
    this.candidates = const [],
    this.documentNo,
  });

  bool get needsChoice => mode == DispatchMode.choice;
}
