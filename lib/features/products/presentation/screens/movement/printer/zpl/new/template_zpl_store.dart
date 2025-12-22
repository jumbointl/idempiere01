import 'package:get_storage/get_storage.dart';
import 'template_zpl_models.dart';

class ZplTemplateStore {
  final GetStorage box;
  final String key;

  ZplTemplateStore(this.box, {this.key = 'zpl_templates'});

  List<ZplTemplate> loadAll() {
    final raw = box.read<List>(key) ?? [];
    return raw
        .map((e) => ZplTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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
    final d = list.where((t) => t.isDefault).toList();
    return d.isEmpty ? null : d.first;
  }

  /// ✅ Marca un template como default del mode (y quita default al resto del mismo mode)
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

  Future<void> upsert(ZplTemplate t) async {
    final list = loadAll();
    final idx = list.indexWhere((x) => x.id == t.id);

    // Si viene marcado como default, hay que limpiar otros defaults del mismo mode
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

    // si en este modo hay uno solo, que sea default
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
