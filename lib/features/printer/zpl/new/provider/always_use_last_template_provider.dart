import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';


/// Storage key for "always use last ZPL template"
const String kAlwaysUseLastTemplateKey = 'always_use_last_zpl_template';

final alwaysUseLastTemplateProvider = StateProvider<bool>((ref) {
  return false;
});
/// Load the value from local storage
bool loadAlwaysUseLastTemplate() {
  final box = GetStorage();
  return box.read<bool>(kAlwaysUseLastTemplateKey) ?? false;
}
/// Save the value to local storage
Future<void> saveAlwaysUseLastTemplate(bool value) async {
  final box = GetStorage();
  await box.write(kAlwaysUseLastTemplateKey, value);
}
