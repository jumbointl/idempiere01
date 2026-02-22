import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../products/domain/idempiere/idempiere_locator.dart';
import 'locator_zpl_template.dart';

const _kLocatorTplList = 'locator_zpl_templates_v1';
const _kLocatorTplSelectedId = 'locator_zpl_selected_id_v1';
const _kLocatorTplCopies = 'locator_zpl_copies_v1';

final locatorDataToPrintProvider =
StateProvider<IdempiereLocator?>((ref) => null);

class LocatorZplTemplatesState {
  final List<LocatorZplTemplate> list;
  final String? selectedId;

  const LocatorZplTemplatesState({
    required this.list,
    required this.selectedId,
  });

  LocatorZplTemplatesState copyWith({
    List<LocatorZplTemplate>? list,
    String? selectedId,
  }) {
    return LocatorZplTemplatesState(
      list: list ?? this.list,
      selectedId: selectedId ?? this.selectedId,
    );
  }

  static const empty =
  LocatorZplTemplatesState(list: <LocatorZplTemplate>[], selectedId: null);
}

final locatorZplTemplatesProvider =
StateNotifierProvider<LocatorZplTemplatesNotifier,
    LocatorZplTemplatesState>(
      (ref) => LocatorZplTemplatesNotifier(GetStorage())..loadFromStorage(),
);

final selectedLocatorZplTemplateProvider =
Provider<LocatorZplTemplate?>((ref) {
  final st = ref.watch(locatorZplTemplatesProvider);
  final id = st.selectedId;
  if (id == null || id.trim().isEmpty) return null;

  for (final t in st.list) {
    if (t.id == id) return t;
  }
  return null;
});

class LocatorZplTemplatesNotifier
    extends StateNotifier<LocatorZplTemplatesState> {
  final GetStorage box;

  LocatorZplTemplatesNotifier(this.box)
      : super(LocatorZplTemplatesState.empty);

  void loadFromStorage() {
    final rawList = box.read(_kLocatorTplList);
    final rawSelected = box.read(_kLocatorTplSelectedId);

    final list = <LocatorZplTemplate>[];

    if (rawList is List) {
      for (final it in rawList) {
        try {
          if (it is Map) {
            list.add(
                LocatorZplTemplate.fromJson(Map<String, dynamic>.from(it)));
          } else if (it is String) {
            final decoded = jsonDecode(it);
            if (decoded is Map) {
              list.add(LocatorZplTemplate.fromJson(
                  Map<String, dynamic>.from(decoded)));
            }
          }
        } catch (_) {}
      }
    }

    String? selectedId = rawSelected?.toString();

    // Validar selected
    if (selectedId != null &&
        !list.any((e) => e.id == selectedId)) {
      selectedId = null;
    }

    final ensured =
    _ensureDefaultTemplate(list, selectedId);

    state = LocatorZplTemplatesState(
      list: ensured.list,
      selectedId: ensured.selectedId,
    );

    if (ensured.changed) {
      _persist();
    }
  }

  /// 🔥 NUEVA LÓGICA INTELIGENTE
  /// - Si NO existe el template default → lo agrega
  /// - Solo lo marca default si NO hay otro con isDefault=true
  /// - No pisa defaults del usuario
  _EnsureResult _ensureDefaultTemplate(
      List<LocatorZplTemplate> list,
      String? selectedId) {

    final def = LocatorZplTemplate.getDefaultTemplate();

    final hasDefaultTemplate =
    list.any((t) => t.id == def.id);

    final hasOtherDefault =
    list.any((t) => t.isDefault);

    bool changed = false;
    final out = [...list];

    if (!hasDefaultTemplate) {
      final injected = hasOtherDefault
          ? def.copyWith(isDefault: false)
          : def;

      out.insert(0, injected);
      changed = true;
    }

    // Si no hay selected, elegir default real
    String? newSelectedId = selectedId;

    if (newSelectedId == null || newSelectedId.trim().isEmpty) {
      final defaultTpl =
      out.firstWhere((t) => t.isDefault, orElse: () => out.first);
      newSelectedId = defaultTpl.id;
      changed = true;
    }

    return _EnsureResult(
      list: out,
      selectedId: newSelectedId,
      changed: changed,
    );
  }

  void _persist() {
    box.write(
        _kLocatorTplList, state.list.map((e) => e.toJson()).toList());
    box.write(_kLocatorTplSelectedId, state.selectedId);
  }

  void upsert(LocatorZplTemplate t) {
    final list = [...state.list];
    final idx = list.indexWhere((x) => x.id == t.id);

    if (t.isDefault) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }

    if (idx >= 0) {
      list[idx] = t;
    } else {
      list.insert(0, t);
    }

    final selectedId = t.isDefault ? t.id : state.selectedId;

    state = state.copyWith(list: list, selectedId: selectedId);
    _persist();
  }

  void deleteById(String id) {
    final list = state.list.where((x) => x.id != id).toList();
    String? selectedId =
    (state.selectedId == id) ? null : state.selectedId;

    final ensured =
    _ensureDefaultTemplate(list, selectedId);

    state = state.copyWith(
        list: ensured.list, selectedId: ensured.selectedId);

    _persist();
  }

  void select(String id) {
    if (!state.list.any((x) => x.id == id)) return;
    state = state.copyWith(selectedId: id);
    _persist();
  }
}

class _EnsureResult {
  final List<LocatorZplTemplate> list;
  final String? selectedId;
  final bool changed;

  _EnsureResult({
    required this.list,
    required this.selectedId,
    required this.changed,
  });
}

final locatorZplCopiesProvider =
StateNotifierProvider<LocatorZplCopiesNotifier, int>(
      (ref) => LocatorZplCopiesNotifier(GetStorage())
    ..loadFromStorage(),
);

class LocatorZplCopiesNotifier extends StateNotifier<int> {
  final GetStorage box;

  LocatorZplCopiesNotifier(this.box) : super(1);

  void loadFromStorage() {
    final raw = box.read(_kLocatorTplCopies);
    final v = int.tryParse((raw ?? '1').toString()) ?? 1;
    state = v < 1 ? 1 : v;
  }

  void setCopies(int v) {
    final c = v < 1 ? 1 : v;
    state = c;
    box.write(_kLocatorTplCopies, c);
  }
}