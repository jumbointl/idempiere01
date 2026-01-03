// pos_adjustment_helpers.dart
import 'pos_adjustment_values.dart';

int nextPosProfileId(List<PosAdjustmentValues> list) {
  if (list.isEmpty) return 1;
  final maxId = list.map((e) => e.id).reduce((a, b) => a > b ? a : b);
  return maxId + 1;
}

List<PosAdjustmentValues> ensureSingleDefault(
    List<PosAdjustmentValues> list,
    int defaultId,
    ) {
  return list.map((e) => e.copyWith(isDefault: e.id == defaultId)).toList();
}
