import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'pos_adjustment_values.dart';
import 'pos_text_utils.dart';

class BematechEscPos {
  static int baseCols(PaperSize p) {
    if (p == PaperSize.mm58) return 32;
    if (p == PaperSize.mm72) return 42;
    return 48;
  }

  static List<int> applyCharSet(PosAdjustmentValues p) =>
      escT(resolveEscTCodeTable(p));

  static int imageWidthDots(PosAdjustmentValues adj) {
    return adj.paperSize.width + adj.printWidthAdjustment;
  }
}
