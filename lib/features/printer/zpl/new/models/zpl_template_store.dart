import 'package:get_storage/get_storage.dart';
import 'zpl_template.dart';

class ZplTemplateStore {
  final GetStorage box;
  final String key;
  static const String _kToPrinterPrefix = 'zpl_to_printer_';

  /// Save printer-ready ZPL content for a template (local cache)
  Future<void> saveToPrinterZpl({
    required String templateId,
    required String zpl,
  }) async {
    // English comment: "Persist printer-ready ZPL locally"
    await box.write(_toPrinterKey(templateId), zpl);
  }

  /// Load printer-ready ZPL content for a template (local cache)
  String? loadToPrinterZpl(String templateId) {
    final v = box.read<String>(_toPrinterKey(templateId));
    if (v == null) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }

  /// Optional: delete printer-ready ZPL cache
  Future<void> deleteToPrinterZpl(String templateId) async {
    await box.remove(_toPrinterKey(templateId));
  }

  ZplTemplateStore(this.box, {this.key = 'zpl_templates'});
  String _toPrinterKey(String templateId) => '$_kToPrinterPrefix$templateId';
  List<ZplTemplate> loadAll() {
    final raw = box.read<List>(key) ?? [];
    final list = raw
        .map((e) => ZplTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // English comment: "Ensure every template has a unique non-empty id"
    bool changed = false;
    final seen = <String>{};

    for (int i = 0; i < list.length; i++) {
      final t = list[i];
      String id = t.id.trim();

      if (id.isEmpty) {
        // English comment: "Fallback id from templateFileName (stable and unique enough)"
        id = t.templateFileName.trim();
        changed = true;
      }

      // English comment: "If still duplicated, add createdAt suffix"
      if (seen.contains(id)) {
        id = '${id}_${t.createdAt.millisecondsSinceEpoch}';
        changed = true;
      }

      seen.add(id);

      if (id != t.id) {
        list[i] = t.copyWith(id: id);
      }
    }

    // English comment: "Persist migration once"
    if (changed) {
      box.write(key, list.map((e) => e.toJson()).toList());
    }

    return list;
  }


  ZplTemplate? findById(String id) {
    final list = loadAll();
    for (final t in list) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<ZplTemplate> loadByMode(ZplTemplateMode mode) {
    final list = loadAll();
    return list.where((t) => t.mode == mode).toList();
  }

  ZplTemplate? loadDefaultByMode(ZplTemplateMode mode) {
    final list = loadByMode(mode);
    if (list.isEmpty) return null;

    final defaults = list.where((t) => t.isDefault).toList();
    if (defaults.isNotEmpty) return defaults.first;

    // English comment: "Fallback to first template if none is marked default"
    return list.first;
  }
  /// Deletes all stored templates.
  Future<void> clearAll() async {
    // English comment: "Remove the entire list from storage"
    await box.remove(key);
  }
  /// ✅ Marca un template como default del mode (y quita default al resto del mismo mode)
  /*Future<void> setDefaultForMode({
    required String templateId,
    required ZplTemplateMode mode,
  }) async {
    final list = loadAll();

    for (int i = 0; i < list.length; i++) {
      final t = list[i];
      if (t.mode != mode) continue;

      if (t.templateFileName == templateId) {
        list[i] = t.copyWith(isDefault: true);
      } else if (t.isDefault) {
        list[i] = t.copyWith(isDefault: false);
      }
    }

    await box.write(key, list.map((e) => e.toJson()).toList());
  }*/
  Future<void> setDefaultForMode({
    required String templateId,
    required ZplTemplateMode mode,
  }) async {
    final list = loadAll();

    for (int i = 0; i < list.length; i++) {
      final t = list[i];
      if (t.mode != mode) continue;

      if (t.id == templateId) {
        list[i] = t.copyWith(isDefault: true);
      } else if (t.isDefault) {

        list[i] = t.copyWith(isDefault: false);
      }
    }

    await box.write(key, list.map((e) => e.toJson()).toList());
  }

  /// ✅ Si en un modo hay 1 solo template, lo fuerza a default
  Future<void> ensureSingleIfOnlyOneDefault(ZplTemplateMode mode) async {
    final list = loadAll();
    final same = list.where((t) => t.mode == mode).toList();
    if (same.length != 1) return;

    final only = same.first;
    if (only.isDefault) return;

    // set default al único
    await setDefaultForMode(templateId: only.id, mode: mode);
  }

  /// ✅ Normaliza por seguridad: si hay 2 defaults por mode, deja solo el primero
  Future<void> normalizeDefaults() async {
    final list = loadAll();
    final modes = <ZplTemplateMode>{...list.map((e) => e.mode)};

    bool changed = false;

    for (final mode in modes) {
      final idxs = <int>[];
      for (int i = 0; i < list.length; i++) {
        if (list[i].mode == mode && list[i].isDefault) idxs.add(i);
      }
      if (idxs.length <= 1) continue;

      // deja el primero
      for (int k = 1; k < idxs.length; k++) {
        final i = idxs[k];
        list[i] = list[i].copyWith(isDefault: false);
        changed = true;
      }
    }

    if (changed) {
      await box.write(key, list.map((e) => e.toJson()).toList());
    }
  }

  Future<void> upsert(ZplTemplate t, {String? toPrinterZpl}) async {
    final list = loadAll();
    final idx = list.indexWhere((x) => x.id == t.id);

    // English comment: "If incoming template is default, clear other defaults for same mode"
    if (t.isDefault) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].mode == t.mode && list[i].id != t.id && list[i].isDefault) {
          list[i] = list[i].copyWith(isDefault: false);
        }
      }
    }

    if (idx >= 0) {
      list[idx] = t;
    } else {
      list.add(t);
    }

    await box.write(key, list.map((e) => e.toJson()).toList());

    // English comment: "Persist printer-ready ZPL if provided"
    if (toPrinterZpl != null && toPrinterZpl.trim().isNotEmpty) {
      await saveToPrinterZpl(templateId: t.id, zpl: toPrinterZpl);
    }

    await ensureSingleIfOnlyOneDefault(t.mode);
    await normalizeDefaults();
  }


  Future<void> deleteById(String id) async {
    final list = loadAll();
    ZplTemplate? deleted;
    for (final t in list) {
      if (t.id == id) {
        deleted = t;
        break;
      }
    }

    final newList = list..removeWhere((e) => e.id == id);
    await box.write(key, newList.map((e) => e.toJson()).toList());

    // Si borraste el default, intenta asignar otro default del mismo mode
    if (deleted != null) {
      final sameMode = newList.where((e) => e.mode == deleted!.mode).toList();
      if (sameMode.isNotEmpty) {
        final any = sameMode.first;
        await setDefaultForMode(templateId: any.id, mode: any.mode);
      }
    }

    await normalizeDefaults();
  }
}
