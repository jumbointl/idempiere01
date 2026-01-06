import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
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

  /// ✅ Crea perfiles iniciales si no existe ninguno guardado
  static void ensureDefaultProfiles() {
    final list = readRawList();
    if (list.isNotEmpty) return;

    final defaults = <PosAdjustmentValues>[
      // 1) Default: la mayoría (80mm + CP1252-like + rawLatin1)
      const PosAdjustmentValues(
        id: 1,
        machineModel: 'BEMATECH 80MM 1252',
        paperSize: PaperSize.mm80,
        printWidthAdjustment: 0,
        charactersPerLineAdjustment: 0,
        charSet: PosCharSet.cp1252,
        escTCodeTable: 16, // ✅ recomendado (tu firmware)
        textMode: PosTextMode.rawLatin1,
        isDefault: true,
      ),

      // 2) 72mm UTF8 raw (si el firmware soporta ESC t 8 + utf8)
      const PosAdjustmentValues(
        id: 2,
        machineModel: 'BEMATECH 72MM UTF8',
        paperSize: PaperSize.mm72,
        printWidthAdjustment: 0,
        charactersPerLineAdjustment: 0,
        charSet: PosCharSet.utf8,
        escTCodeTable: 8,
        textMode: PosTextMode.rawUtf8,
        isDefault: false,
      ),

      // 3) 72mm CP850 raw (para € sin UTF8)
      const PosAdjustmentValues(
        id: 3,
        machineModel: 'BEMATECH 72MM 850',
        paperSize: PaperSize.mm72,
        printWidthAdjustment: 0,
        charactersPerLineAdjustment: 0,
        charSet: PosCharSet.cp850,
        escTCodeTable: 2,
        textMode: PosTextMode.rawLatin1,
        isDefault: false,
      ),
      // 4) 72mm CP858 raw (para € sin UTF8)
      const PosAdjustmentValues(
        id: 4,
        machineModel: 'BEMATECH 72MM 858',
        paperSize: PaperSize.mm72,
        printWidthAdjustment: 0,
        charactersPerLineAdjustment: 0,
        charSet: PosCharSet.cp858,
        escTCodeTable: 5,
        textMode: PosTextMode.rawLatin1,
        isDefault: false,
      ),

      // 5) Genérico 80mm CP1252 raw
      const PosAdjustmentValues(
        id: 5,
        machineModel: 'GENERIC 80MM 1252',
        paperSize: PaperSize.mm80,
        printWidthAdjustment: 0,
        charactersPerLineAdjustment: 0,
        charSet: PosCharSet.cp1252,
        escTCodeTable: 16,
        textMode: PosTextMode.generator,
        isDefault: false,
      ),

      // 6) Genérico 72mm CP1252 raw
      const PosAdjustmentValues(
        id: 6, // ✅ ID único
        machineModel: 'GENERIC 72MM 1252',
        paperSize: PaperSize.mm72,
        printWidthAdjustment: 0,
        charactersPerLineAdjustment: 0,
        charSet: PosCharSet.cp1252,
        escTCodeTable: 16,
        textMode: PosTextMode.generator,
        isDefault: false,
      ),
    ];

    writeRawList(defaults.map((e) => e.toJson()).toList());

    // opcional: siempre usar default por defecto
    writeAlwaysDefault(false);
  }
  static Future<void> resetToDefaults() async {
    await _box.remove(kPosAdjustmentsKey);
    await _box.remove(kPosAlwaysDefaultKey);
    // vuelve a crear los perfiles base
    ensureDefaultProfiles();
  }

}
