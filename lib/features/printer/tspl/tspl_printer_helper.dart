// -----------------------------------------------------------------------------
// QR helper: calculate cellWidth (magnification) for TSPL QRCODE
// -----------------------------------------------------------------------------
import '../../products/domain/models/label_profile.dart';

/// Calculates a TSPL QR cell width (module size in dots) that fits inside the
/// printable area, based on label width and available height.
///
/// Assumptions:
/// - dotsPerMm default 8 (203dpi). Adjust if your printer is 300dpi (~12).
/// - We approximate QR module count by content length to avoid heavy version math.
/// - Returns a safe range (2..8) by default.
///
/// You can reuse this for any QR TSPL builder.
int calculateQrCellWidth({
  required int labelWidthDots,
  required int labelHeightDots,
  required int marginXDots,
  required int marginYDots,
  required int topReservedDots,
}) {
  // espacio disponible (ancho y alto) para el QR
  final int availW = (labelWidthDots - (marginXDots * 2)).clamp(1, labelWidthDots);
  final int availH = (labelHeightDots - marginYDots - topReservedDots).clamp(1, labelHeightDots);

  // Módulos aproximados del QR:
  // versión chica suele estar en 25..33; sumamos quiet zone ~8 módulos => 33..41
  const int modulesWithQuiet = 41;

  // cell máximo por ancho y por alto
  final int cellByW = (availW / modulesWithQuiet).floor();
  final int cellByH = (availH / modulesWithQuiet).floor();

  // Elegimos el mínimo para que quepa en ambos
  int cell = cellByW < cellByH ? cellByW : cellByH;

  // Limites típicos
  cell = cell.clamp(2, 8);

  return cell;
}

// -----------------------------------------------------------------------------
// Code128 helper: calculate narrow & wide based on content length and width
// -----------------------------------------------------------------------------
/// Returns (narrow, wide) for TSPL Code128 barcode that tries to fit in the
/// printable width.
///
/// - If content is long and the estimated width exceeds target, it reduces narrow.
/// - wide is derived from narrow (commonly wide = narrow*2).
///
/// Notes:
/// - This is a heuristic. Real width depends on start/stop, code set shifts, etc.
/// - Works well enough to auto-adjust for "short vs long" values.
({int narrow, int wide}) calculateCode128NarrowWide({
  required String data,
  required int labelWidthDots,
  required int marginXDots,
  int defaultNarrow = 2,
  int defaultWide = 3,
  double targetWidthFactor = 0.80, // use 80% of printable area as max
  int minNarrow = 1,
  int maxNarrow = 4,
  int minWide = 2,
  int maxWide = 8,
}) {
  final String v = data.trim().replaceAll('\n', ' ').replaceAll('\r', ' ');

  final int printableW =
  (labelWidthDots - (marginXDots * 2)).clamp(1, labelWidthDots);

  // Code128 rough width estimate:
  // modules ≈ (chars * 11) + overhead
  int estimateBarcodeWidthDots({required int n, required int narrowDots}) {
    final int modules = (n * 11) + 35;
    return modules * narrowDots;
  }

  int narrow = defaultNarrow.clamp(minNarrow, maxNarrow);
  int wide = defaultWide.clamp(minWide, maxWide);

  final int targetMax = (printableW * targetWidthFactor).round();

  // Try with default narrow first
  final int estDefault = estimateBarcodeWidthDots(n: v.length, narrowDots: narrow);

  if (estDefault > targetMax) {
    // Reduce narrow (down to 1) if too wide
    narrow = 1;
  }

  // Derive wide from narrow (typical: 2x), clamp
  wide = (narrow * 2).clamp(minWide, maxWide);

  return (narrow: narrow, wide: wide);
}
/// Calculates X (in dots) to center a text string on the label.
/// - Uses profile.widthMm (mm) -> dotsPerMm
/// - Estimates text width by characters (good enough for TSPL fonts)
/// - Clamps inside margins
///
/// NOTE: TSPL TEXT fonts are not truly monospaced across all models,
/// but this heuristic works well in practice for centering.
int calculateCenteredTextX({
  required String text,
  required LabelProfile profile,
  int dotsPerMm = 8, // 203dpi
  int? fontIdOverride,
  double scaleX = 1.0, // TSPL TEXT x-multiplier (the 6th param in TEXT)
}) {
  final String t = text.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();

  final int labelW = (profile.widthMm * dotsPerMm).round();
  final int mx = (profile.marginXmm * dotsPerMm).round();

  final int fontId = (fontIdOverride ?? profile.fontId);
  final int safeFontId = fontId > 0 ? fontId : 2;

  // Rough per-character width in dots by fontId.
  // These are typical for TSPL internal fonts at x-multiplier = 1.
  // Tune if you see consistent drift on your printer.
  int charW;
  switch (safeFontId) {
    case 1:
      charW = 10;
      break;
    case 2:
      charW = 12;
      break;
    case 3:
      charW = 16;
      break;
    default:
      charW = 12;
      break;
  }

  final int textW = (t.length * charW * scaleX).round();

  int x = ((labelW - textW) / 2).round();

  // Keep inside margins
  x = x.clamp(mx, (labelW - mx).clamp(mx, labelW));

  return x;
}
int estimateBarcodeWidthDots(int length, int n) {
  final modules = (length * 11) + 35;
  return modules * n;
}