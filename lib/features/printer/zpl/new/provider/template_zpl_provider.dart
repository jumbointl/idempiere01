

import 'package:flutter_riverpod/legacy.dart';

import '../models/zpl_template.dart';

final exampleLoadCounterProvider = StateProvider<int>((ref) {
  return 0;
});

final selectedZplTemplateModeProvider =
StateProvider<ZplTemplateMode>((ref) {
  return ZplTemplateMode.movement; // default
});

