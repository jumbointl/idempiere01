// pos_adjustment_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'pos_adjustment_storage.dart';
import 'pos_adjustment_values.dart';

final posAdjustmentsProvider =
StateProvider<List<PosAdjustmentValues>>((ref) {
  PosAdjustmentStorage.ensureDefaultProfiles();
  return PosAdjustmentStorage.readRawList()
      .map(PosAdjustmentValues.fromJson)
      .toList();
});

final useAlwaysDefaultPosProvider = StateProvider<bool>((ref) {
  return PosAdjustmentStorage.readAlwaysDefault();
});

void savePosAdjustments(WidgetRef ref, List<PosAdjustmentValues> list) {
  PosAdjustmentStorage.writeRawList(list.map((e) => e.toJson()).toList());
  ref.read(posAdjustmentsProvider.notifier).state = list;
}
