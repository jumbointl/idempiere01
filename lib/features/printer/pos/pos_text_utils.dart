import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

List<int> hrCustom(Generator g, int cols, {String ch = '-'}) {
  if (cols < 10) cols = 10;
  if (cols > 60) cols = 60; // protección
  return g.text(ch * cols);
}
