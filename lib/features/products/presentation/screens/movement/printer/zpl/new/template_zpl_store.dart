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

  Future<void> upsert(ZplTemplate t) async {
    final list = loadAll();
    final idx = list.indexWhere((x) => x.id == t.id);
    if (idx >= 0) {
      list[idx] = t;
    } else {
      list.add(t);
    }
    await box.write(key, list.map((e) => e.toJson()).toList());
  }

  Future<void> deleteById(String id) async {
    final list = loadAll()..removeWhere((e) => e.id == id);
    await box.write(key, list.map((e) => e.toJson()).toList());
  }
}
