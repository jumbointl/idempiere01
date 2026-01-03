// bematech_escpos.dart
import 'pos_adjustment_values.dart';

class BematechEscPos {
  static bool isBematech(PosAdjustmentValues p) {
    final m = p.machineModel.toLowerCase();
    return m.contains('bematech') || m.contains('mp-4200') || m.contains('mp4200');
  }

  /// ESC t n: Bematech obedece MUCHO mejor que setGlobalCodeTable
  /// CP850 => ESC t 2
  static List<int> escT(int n) => [0x1B, 0x74, n];
  static List<int> applyCharSet(PosAdjustmentValues p) {
    // ✅ si el perfil define escTCodeTable, usamos eso SIEMPRE
    if (p.escTCodeTable != null) {
      return escT(p.escTCodeTable!);
    }

    // fallback por enum (menos exacto)
    if (p.charSet == PosCharSet.cp850) return escT(2);

    // cp1252: NO hay n estándar universal, pero tu test mostró que 16 funciona:
    return escT(16);
  }

  static int safeColsFor80mm(PosAdjustmentValues p) {
    final cols = 48 + p.charactersPerLineAdjustment;
    if (cols < 32) return 32;
    if (cols > 48) return 48;
    return cols;
  }

  static int imageWidthDots(PosAdjustmentValues p) {
    final w = 576 + p.printWidthAdjustment;
    if (w < 384) return 384;
    if (w > 576) return 576;
    return w;
  }
}
