import 'dart:convert';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'pos_adjustment_values.dart';

List<int> escT(int n) => [0x1B, 0x74, n];
List<int> lf() => [0x0A];

int resolveEscTCodeTable(PosAdjustmentValues p) {
  if (p.escTCodeTable != null) return p.escTCodeTable!;
  switch (p.charSet) {
    case PosCharSet.cp850:
      return 2;
    case PosCharSet.cp858:
      return 5;
    case PosCharSet.utf8:
      return 8;
    case PosCharSet.cp1252:
    default:
      return 16; // tu firmware
  }
}

/// true si algún codeUnit está fuera de Latin1 (0..255)
bool containsNonLatin1(String s) {
  for (final cu in s.codeUnits) {
    if (cu > 255) return true;
  }
  return false;
}

String sanitizeForLatin1Common(String s) => s
    .replaceAll('—', '-')
    .replaceAll('–', '-')
    .replaceAll('“', '"')
    .replaceAll('”', '"')
    .replaceAll("‘", "'")
    .replaceAll("’", "'")
    .replaceAll('\u00A0', ' ');

String sanitizeForCp850(String s) =>
    sanitizeForLatin1Common(s).replaceAll('€', 'EUR');

String sanitizeForCp858Or1252(String s) => sanitizeForLatin1Common(s);

void addRawLatin1Line(List<int> bytes, String s, {required int escTN}) {
  // Si trae algo fuera de Latin1 -> manda UTF8 RAW
  if (containsNonLatin1(s)) {
    addRawUtf8Line(bytes, s);
    return;
  }
  bytes.addAll(escT(escTN));
  bytes.addAll(latin1.encode(s));
  bytes.addAll(lf());
}

void addRawUtf8Line(List<int> bytes, String s) {
  bytes.addAll(escT(8));
  bytes.addAll(utf8.encode(s));
  bytes.addAll(lf());
}

/// Modo “smart”: intenta gen.text, si explota -> cae a RAW seguro
void addTextByMode({
  required List<int> bytes,
  required Generator gen,
  required PosAdjustmentValues adj,
  required String text,
  PosStyles styles = const PosStyles(),
}) {
  final n = resolveEscTCodeTable(adj);

  switch (adj.textMode) {
    case PosTextMode.generator:
      try {
        // OJO: no metas escT antes de gen.text si gen.text ya controla encoding
        bytes.addAll(gen.text(text, styles: styles));
      } catch (_) {
        final safe = (n == 2) ? sanitizeForCp850(text) : sanitizeForCp858Or1252(text);
        addRawLatin1Line(bytes, safe, escTN: n);
      }
      return;

    case PosTextMode.rawLatin1:
      final safe = (n == 2) ? sanitizeForCp850(text) : sanitizeForCp858Or1252(text);
      addRawLatin1Line(bytes, safe, escTN: n);
      return;

    case PosTextMode.rawUtf8:
      addRawUtf8Line(bytes, text);
      return;
  }
}

List<int> escAlignLeft() => [0x1B, 0x61, 0x00]; // ESC a 0
List<int> escBoldOff()   => [0x1B, 0x45, 0x00];
void addHrSafeNormal({
  required List<int> bytes,
  required Generator gen,
  required PosAdjustmentValues adj,
  required int cols,
  String ch = '-',
}) {
  // ✅ fuerza estado: LEFT + BOLD OFF (sticky en ESC/POS)
  bytes.addAll(escAlignLeft());
  bytes.addAll(escBoldOff());

  // ✅ imprime la línea en el modo “seguro” actual
  addTextByMode(
    bytes: bytes,
    gen: gen,
    adj: adj,
    text: ch * cols,
    // styles aquí ya no es crítico, porque arriba forzamos ESC/POS
  );
}
  void addHrSafeBold({
    required List<int> bytes,
    required Generator gen,
    required PosAdjustmentValues adj,
    required int cols,
    String ch = '-',
  }) {
    bytes.addAll(escAlignLeft());
    bytes.addAll(escBoldOff());
    addTextByMode(
    bytes: bytes,
    gen: gen,
    adj: adj,
    text: ch * cols,
    styles: const PosStyles(
    align: PosAlign.left,
    bold: true,
    ),
    );
  }
