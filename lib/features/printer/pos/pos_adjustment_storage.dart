import 'package:get_storage/get_storage.dart';

import 'pos_adjustment_storage_keys.dart';
import 'pos_adjustment_values.dart';

class PosAdjustmentStorage {
  static final GetStorage _box = GetStorage();

  static bool readAlwaysDefault() =>
      (_box.read(kPosAlwaysDefaultKey) as bool?) ?? false;

  static void writeAlwaysDefault(bool value) =>
      _box.write(kPosAlwaysDefaultKey, value);

  static List<Map<String, dynamic>> readRawList() {
    final raw = _box.read(kPosAdjustmentsKey);
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static void writeRawList(List<Map<String, dynamic>> list) {
    _box.write(kPosAdjustmentsKey, list);
  }

  /// ✅ Crea 2 perfiles iniciales si no existe ninguno guardado
  static void ensureDefaultProfiles() {
    final list = readRawList();
    if (list.isNotEmpty) return;

    final defaults = <PosAdjustmentValues>[
      // 1) ✅ Bematech MP-4200 TH (tus 15 máquinas)
      const PosAdjustmentValues(
        id: 1,
        machineModel: 'BEMATECH MP-4200 TH',
        printWidthAdjustment: -48,          // 576 -> 528 (73.5mm)
        charactersPerLineAdjustment: -6,    // 48 -> 42 cols
        charSet: PosCharSet.cp850,          // Bematech estable
        isDefault: true,
      ),

      // 2) Genérico 80mm
      const PosAdjustmentValues(
        id: 2,
        machineModel: 'GENERIC 80MM',
        printWidthAdjustment: 0,            // 576
        charactersPerLineAdjustment: 0,     // 48 cols
        charSet: PosCharSet.cp1252,
        isDefault: false,
      ),
    ];

    writeRawList(defaults.map((e) => e.toJson()).toList());

    // opcional: siempre usar default por defecto
    writeAlwaysDefault(true);
  }
}
