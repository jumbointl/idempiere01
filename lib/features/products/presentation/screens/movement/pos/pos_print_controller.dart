// pos_print_controller.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';


// ====== PROVIDER ======
final posPrintControllerProvider =
AsyncNotifierProvider<PosPrintController, Uint8List?>(PosPrintController.new);

class PosPrintController extends AsyncNotifier<Uint8List?> {
  late String _ip;
  late int _port;
  late MovementAndLines _data;

  // Papel 80mm típico
  static const int _dotsPerLine = 576;
  static const int _colsFontB = 64; // ancho lógico en “columnas” para tabla

  @override
  Future<Uint8List?> build() async => null;

  void init({required String ip, required int port, required MovementAndLines data}) {
    _ip = ip;
    _port = port;
    _data = data;
    _generate();
  }

  Future<void> _generate() async {
    final bytes = await _buildTicketBytes(_data);
    state = AsyncData(bytes);
  }

  Future<void> printToSocket() async {
    final bytes = state.value ?? await _buildTicketBytes(_data);
    final socket = await Socket.connect(_ip, _port, timeout: const Duration(seconds: 6));
    socket.add(bytes);
    await socket.flush();
    await socket.close();
  }
  void _doubleSize(BytesBuilder out, bool on) {
    // bit7=doble alto, bit4=doble ancho, ambos 1 → 0x11
    out.add([0x1D, 0x21, on ? 0x11 : 0x00]);
  }

  // ========================= Construcción del ticket =========================
  Future<Uint8List> _buildTicketBytes(MovementAndLines m) async {
    final out = BytesBuilder();

    // Init
    _escInit(out);
    _selectFontB(out);
    _selectCodePage1252(out); // acentos/ñ

    // ---------- Encabezado gráfico (logo + título grande) ----------
    await _printHeaderCompositeRaster(out, m);

    // ---------- Encabezado textual (fuera de la imagen) ----------
    _alignLeft(out);

    if ((m.movementDate ?? '').isNotEmpty) _text(out, '${m.movementDate}\n');
    _text(out, 'MONALISA S.A.\n');
    _text(out, '${m.documentStatus}\n');
    _feed(out, 1);
    _doubleSize(out, true);
    _text(out, '${m.documentNumber}\n');
    _doubleSize(out, false);
    _text(out, 'Av. Monseñor Rodriguez\n');
    _text(out, 'C/ Av. Carlos Antonio López, CDE\n');
    _text(out, 'Actualizacion de existencias \n');


    // ---------- QR (línea) + BARCODE (línea siguiente) → NATIVO ----------
    _printQrAndBarcodeNativeTwoRows(
      out,
      qrData: m.documentNumber,
      barcodeData: (m.id ?? 0).toString(),
      qrModule: 6,         // módulos generosos para fácil lectura
      qrEcc: 2,            // 0=L,1=M,2=Q,3=H → Q
      barcodeHeight: 80,   // alto barras
      barcodeModule: 3,    // grosor barra (2–4)
      hriBelow: true,      // mostrar texto debajo
    );

    // ---------- Tabla ----------
    out.add(_rasterLineThick()); // línea superior gruesa

    // Header de tabla 40/60
    final leftW1 = (_colsFontB * 0.40).floor();
    final rightW1 = _colsFontB - leftW1;
    _bold(out, true);
    _row(out, 'UPC/SKU', 'Hasta/Desde', leftW1, rightW1, rightAlignRight: true);
    _row(out, 'Línea/Nombre Producto', 'Cantidad', leftW1, rightW1, rightAlignRight: true);
    _row(out, 'Atributo', '', leftW1, rightW1, rightAlignRight: true);
    _bold(out, false);

    out.add(_rasterLineThick()); // separador grueso header/body

    // Body: 2 filas por ítem
    final items = m.movementLines ?? const <IdempiereMovementLine>[];
    double totalItems = 0.0;

    for (final e in items) {
      totalItems += (e.movementQty ?? 0.0);

      // Fila 1: 40/60 → (UPC SKU) vs (To / From)
      final f1left = '${e.uPC ?? '-'}  ${e.sKU ?? '-'}';
      final f1right = '${e.locatorToName}  ${e.locatorFromName}';
      _row(out, f1left, f1right, leftW1, rightW1, rightAlignRight: true);

      // Fila 2: 60/40 → (Nombre + Atributo) vs (Cantidad grande)
      final leftW2 = (_colsFontB * 0.60).floor();
      final rightW2 = _colsFontB - leftW2;
      final f2left =
          '${e.productNameWithLine}  ${(e.attributeName?.isNotEmpty ?? false) ? e.attributeName! : '-'}';
      _row(out, _fitLeft(f2left, leftW2), '', leftW2, rightW2, rightAlignRight: true);

      // Cantidad grande a la derecha (en su propia línea visual)
      _alignRight(out);
      _doubleHeight(out, true);
      _bold(out, true);
      _text(out, '${e.movementQtyString}\n');
      _bold(out, false);
      _doubleHeight(out, false);
      _alignLeft(out);

      // Línea fina entre ítems
      out.add(_rasterLineThin());
    }

    // ---------- Total ----------
    final totalStr = totalItems.toStringAsFixed(3);
    _alignRight(out);
    _bold(out, true);
    _doubleHeight(out, true);
    _text(out, 'ITEMS TOTAL $totalStr\n');
    _doubleHeight(out, false);
    _bold(out, false);
    _alignLeft(out);

    out.add(_rasterLineThick()); // línea inferior gruesa (footer de tabla)

    // ---------- Footer: repetir QR + BARCODE (nativo, 2 filas) ----------
    _printQrAndBarcodeNativeTwoRows(
      out,
      qrData: m.documentNumber,
      barcodeData: (m.id ?? 0).toString(),
      qrModule: 6,
      qrEcc: 2,
      barcodeHeight: 60,
      barcodeModule: 3,
      hriBelow: true,
    );

    _feed(out, 2);
    _cutPartial(out);
    return out.takeBytes();
  }

  // ========================= Header: logo + título (raster) =========================
  Future<void> _printHeaderCompositeRaster(BytesBuilder out, MovementAndLines m) async {
    final logoImg = await _loadAssetDecode(m.movementIcon);

    final W = _dotsPerLine;   // 576
    final H = 160;
    final leftW  = (W * 0.30).floor(); // 30% logo
    final midW   = (W * 0.40).floor(); // 40% título
    // final rightW = W - leftW - midW; // 30% libre

    final canvas = img.Image(width: W, height: H);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    // LOGO a la izquierda
    if (logoImg != null) {
      final scaled = _fitImage(logoImg, maxW: leftW, maxH: H);
      final lx = ((leftW - scaled.width) ~/ 2);
      final ly = ((H - scaled.height) ~/ 2);
      _blit(canvas, scaled, dstX: lx, dstY: ly);
    }

    // TÍTULO centrado (3×)
    const title = 'REMISION FISCAL';
    const tScale = 3;
    final titleW = title.length * (5 * tScale + 1);
    final tx = leftW + ((midW - titleW) ~/ 2);
    final ty = (H - (7 * tScale)) ~/ 2;
    _drawText5x7Scaled(canvas, title, tx, ty, scale: tScale);

    final mono = _toMonochrome(canvas, threshold: 128);
    out.add(_encodeRasterImageGSv0(mono));
  }

  // ========================= QR + BARCODE NATIVOS (2 filas) =========================
  void _printQrAndBarcodeNativeTwoRows(
      BytesBuilder out, {
        required String qrData,
        required String barcodeData,
        int qrModule = 6,            // 1..16
        int qrEcc = 2,               // 0=L,1=M,2=Q,3=H
        int barcodeHeight = 80,       // 1..255
        int barcodeModule = 3,        // 2..6 recomendado
        bool hriBelow = true,
      }) {
    // --- QR nativo (fila 1) ---
    _alignLeft(out);
    _qrNative(out, qrData, moduleSize: qrModule, ecc: qrEcc);
    _feed(out, 1);

    // --- Barcode nativo (fila 2) ---
    // Ajustes de presentación
    _setBarcodeHRI(out, hriBelow ? 2 : 0);         // 0:None,1:Above,2:Below,3:Both
    _setBarcodeModuleWidth(out, barcodeModule);    // GS w
    _setBarcodeHeight(out, barcodeHeight);         // GS h
    // (Opcional) fuente del HRI → GS f 0 (A) / 1 (B)
    out.add([0x1D, 0x66, 0x00]);

    // Code128 (GS k 73), datos en Code Set B con {B prefijo
    final clean = _asciiPrintable(barcodeData);
    final payload = '{B$clean'; // impresora calcula checksum
    final bytes = const Latin1Encoder().convert(payload);
    final len = bytes.length.clamp(1, 255);

    out.add([0x1D, 0x6B, 0x49, len]); // GS k m=73(Code128) len
    out.add(bytes);
    out.add([0x0A]); // salto
  }

  // ========================= ESC/POS básicos =========================
  void _escInit(BytesBuilder out) => out.add([0x1B, 0x40]); // ESC @
  void _selectFontB(BytesBuilder out) => out.add([0x1B, 0x4D, 0x01]); // ESC M 1
  void _alignLeft(BytesBuilder out)  => out.add([0x1B, 0x61, 0x00]);
  void _alignRight(BytesBuilder out) => out.add([0x1B, 0x61, 0x02]);
  void _bold(BytesBuilder out, bool on) => out.add([0x1B, 0x45, on ? 1 : 0]);
  void _doubleHeight(BytesBuilder out, bool on) => out.add([0x1D, 0x21, on ? 0x10 : 0x00]);
  void _feed(BytesBuilder out, int n) => out.add([0x1B, 0x64, n]);
  void _cutPartial(BytesBuilder out) => out.add([0x1D, 0x56, 0x42, 0x00]);

  // Codepage
  void _selectCodePage1252(BytesBuilder out) => out.add([0x1B, 0x74, 16]); // CP1252

  void _text(BytesBuilder out, String s) => out.add(const Latin1Encoder().convert(s));

  // Barcode helpers
  void _setBarcodeHeight(BytesBuilder out, int h) => out.add([0x1D, 0x68, h.clamp(1, 255)]);
  void _setBarcodeModuleWidth(BytesBuilder out, int w) => out.add([0x1D, 0x77, w.clamp(2, 6)]); // 2..6
  void _setBarcodeHRI(BytesBuilder out, int pos) => out.add([0x1D, 0x48, pos.clamp(0, 3)]);     // 0..3

  // QR nativo
  void _qrNative(BytesBuilder out, String data, {int moduleSize = 4, int ecc = 1}) {
    final bytes = const Latin1Encoder().convert(data);
    // Modelo 2
    out.add([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
    // Tamaño módulo
    out.add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, moduleSize.clamp(1, 16)]);
    // ECC (0=L,1=M,2=Q,3=H)
    out.add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30 + ecc.clamp(0, 3)]);
    // Store
    final pL = (bytes.length + 3) & 0xFF;
    final pH = ((bytes.length + 3) >> 8) & 0xFF;
    out.add([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30]);
    out.add(bytes);
    // Print
    out.add([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
  }

  // ========================= Helpers de filas (tabla por caracteres) =================
  void _row(BytesBuilder out, String left, String right, int leftW, int rightW,
      {bool rightAlignRight = true}) {
    final l = _fitLeft(left, leftW);
    final r = rightAlignRight ? _fitRight(right, rightW) : _fitLeft(right, rightW);
    _text(out, '$l$r\n');
  }
  String _fitLeft(String s, int w)  => (s.length <= w) ? s.padRight(w) : s.substring(0, w);
  String _fitRight(String s, int w) => (s.length <= w) ? s.padLeft(w)  : s.substring(s.length - w);

  // ========================= Líneas raster =========================
  Uint8List _rasterLineThick() {
    final w = _dotsPerLine;
    const h = 5;
    final line = img.Image(width: w, height: h);
    img.fill(line, color: img.ColorRgb8(0, 0, 0));
    return _encodeRasterImageGSv0(line);
  }
  Uint8List _rasterLineThin() {
    final w = _dotsPerLine;
    const h = 2;
    final line = img.Image(width: w, height: h);
    img.fill(line, color: img.ColorRgb8(0, 0, 0));
    return _encodeRasterImageGSv0(line);
  }

  // ========================= Utils imagen (para header raster) ======================
  Future<img.Image?> _loadAssetDecode(String assetPath) async {
    try {
      final bd = await rootBundle.load(assetPath);
      final bytes = bd.buffer.asUint8List();
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }
  img.Image _fitImage(img.Image src, {required int maxW, required int maxH}) {
    final sx = maxW / src.width;
    final sy = maxH / src.height;
    final s  = (sx < sy) ? sx : sy;
    final newW = (src.width * s).clamp(1, maxW).toInt();
    final newH = (src.height * s).clamp(1, maxH).toInt();
    return img.copyResize(src, width: newW, height: newH);
  }
  void _blit(img.Image dst, img.Image src, {required int dstX, required int dstY}) {
    for (int y = 0; y < src.height; y++) {
      final ty = dstY + y;
      if (ty < 0 || ty >= dst.height) continue;
      for (int x = 0; x < src.width; x++) {
        final tx = dstX + x;
        if (tx < 0 || tx >= dst.width) continue;
        dst.setPixel(tx, ty, src.getPixel(x, y));
      }
    }
  }
  img.Image _toMonochrome(img.Image src, {int threshold = 128}) {
    final gray = img.grayscale(src);
    final out = img.Image(width: gray.width, height: gray.height);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final c = gray.getPixel(x, y);
        final lum = img.getLuminance(c);
        final black = lum < threshold;
        out.setPixel(x, y, black ? img.ColorRgb8(0, 0, 0) : img.ColorRgb8(255, 255, 255));
      }
    }
    return out;
  }
  Uint8List _encodeRasterImageGSv0(img.Image mono) {
    final w = mono.width, h = mono.height;
    final bytesPerRow = (w + 7) >> 3;
    final out = BytesBuilder();
    out.add([0x1D, 0x76, 0x30, 0x00]); // GS v 0 m=0
    out.add([bytesPerRow & 0xFF, (bytesPerRow >> 8) & 0xFF, h & 0xFF, (h >> 8) & 0xFF]);
    final row = List<int>.filled(bytesPerRow, 0);
    for (int y = 0; y < h; y++) {
      row.fillRange(0, bytesPerRow, 0);
      int bit = 7, byteIndex = 0, current = 0;
      for (int x = 0; x < w; x++) {
        final col = mono.getPixel(x, y);
        final isBlack = col.r < 128; // tras BN: r=g=b
        if (isBlack) current |= (1 << bit);
        if (bit == 0) { row[byteIndex++] = current; current = 0; bit = 7; } else { bit--; }
      }
      if (bit != 7) row[byteIndex] = current;
      out.add(row);
    }
    out.add([0x0A]);
    return out.takeBytes();
  }

  // ========================= Utils varios =========================
  String _asciiPrintable(String s) {
    // Reemplaza no imprimibles por '?', útil para Code128 nativo
    final codes = s.codeUnits.map((c) => (c >= 32 && c <= 126) ? c : 63).toList();
    return String.fromCharCodes(codes);
  }
  void _drawText5x7Scaled(img.Image dst, String text, int x, int y, {int scale = 1}) {
    var dx = x;
    for (final ch in text.codeUnits) {
      if (ch == 32) { dx += (5 * scale + scale); continue; }
      final glyph = _font5x7[ch] ?? _font5x7[63];
      for (int row = 0; row < 7; row++) {
        final line = glyph![row];
        for (int col = 0; col < 5; col++) {
          final bit = (line >> (4 - col)) & 1;
          if (bit == 1) {
            for (int yy = 0; yy < scale; yy++) {
              for (int xx = 0; xx < scale; xx++) {
                img.drawPixel(dst, dx + col * scale + xx, y + row * scale + yy, img.ColorRgb8(0, 0, 0));
              }
            }
          }
        }
      }
      dx += (5 * scale + scale);
    }
  }
}

// Fuente 5x7 mínima (A–Z, dígitos y '?')
const Map<int, List<int>> _font5x7 = {
  63: [0x1E,0x11,0x15,0x17,0x10,0x00,0x00], // '?'
  // Dígitos 0-9
  48: [0x0E,0x11,0x13,0x15,0x19,0x11,0x0E],
  49: [0x04,0x0C,0x04,0x04,0x04,0x04,0x0E],
  50: [0x0E,0x11,0x01,0x06,0x08,0x10,0x1F],
  51: [0x1F,0x02,0x04,0x02,0x01,0x11,0x0E],
  52: [0x02,0x06,0x0A,0x12,0x1F,0x02,0x02],
  53: [0x1F,0x10,0x1E,0x01,0x01,0x11,0x0E],
  54: [0x06,0x08,0x10,0x1E,0x11,0x11,0x0E],
  55: [0x1F,0x01,0x02,0x04,0x08,0x08,0x08],
  56: [0x0E,0x11,0x11,0x0E,0x11,0x11,0x0E],
  57: [0x0E,0x11,0x11,0x0F,0x01,0x02,0x0C],
  // Letras A-Z
  65: [0x0E,0x11,0x11,0x1F,0x11,0x11,0x11],
  66: [0x1E,0x11,0x1E,0x11,0x11,0x11,0x1E],
  67: [0x0E,0x11,0x10,0x10,0x10,0x11,0x0E],
  68: [0x1C,0x12,0x11,0x11,0x11,0x12,0x1C],
  69: [0x1F,0x10,0x1E,0x10,0x10,0x10,0x1F],
  70: [0x1F,0x10,0x1E,0x10,0x10,0x10,0x10],
  71: [0x0E,0x11,0x10,0x17,0x11,0x11,0x0E],
  72: [0x11,0x11,0x11,0x1F,0x11,0x11,0x11],
  73: [0x0E,0x04,0x04,0x04,0x04,0x04,0x0E],
  74: [0x07,0x02,0x02,0x02,0x12,0x12,0x0C],
  75: [0x11,0x12,0x14,0x18,0x14,0x12,0x11],
  76: [0x10,0x10,0x10,0x10,0x10,0x10,0x1F],
  77: [0x11,0x1B,0x15,0x15,0x11,0x11,0x11],
  78: [0x11,0x19,0x15,0x13,0x11,0x11,0x11],
  79: [0x0E,0x11,0x11,0x11,0x11,0x11,0x0E],
  80: [0x1E,0x11,0x11,0x1E,0x10,0x10,0x10],
  81: [0x0E,0x11,0x11,0x11,0x15,0x12,0x0D],
  82: [0x1E,0x11,0x11,0x1E,0x14,0x12,0x11],
  83: [0x0F,0x10,0x0E,0x01,0x01,0x11,0x0E],
  84: [0x1F,0x04,0x04,0x04,0x04,0x04,0x04],
  85: [0x11,0x11,0x11,0x11,0x11,0x11,0x0E],
  86: [0x11,0x11,0x11,0x11,0x11,0x0A,0x04],
  87: [0x11,0x11,0x11,0x15,0x15,0x1B,0x11],
  88: [0x11,0x11,0x0A,0x04,0x0A,0x11,0x11],
  89: [0x11,0x11,0x0A,0x04,0x04,0x04,0x04],
  90: [0x1F,0x01,0x02,0x04,0x08,0x10,0x1F],
};

// Patrones Code128 (0..106)
const List<List<int>> _code128Patterns = [
  [2,1,2,2,2,2],[2,2,2,1,2,2],[2,2,2,2,2,1],[1,2,1,2,2,3],[1,2,1,3,2,2],
  [1,3,1,2,2,2],[1,2,2,2,1,3],[1,2,2,3,1,2],[1,3,2,2,1,2],[2,2,1,2,1,3],
  [2,2,1,3,1,2],[2,3,1,2,1,2],[1,1,2,2,3,2],[1,2,2,1,3,2],[1,2,2,2,3,1],
  [1,1,3,2,2,2],[1,2,3,1,2,2],[1,2,3,2,2,1],[2,2,3,2,1,1],[2,2,1,1,3,2],
  [2,2,1,2,3,1],[2,1,3,2,1,2],[2,2,3,1,1,2],[3,1,2,1,3,1],[3,1,1,2,2,2],
  [3,2,1,1,2,2],[3,2,1,2,2,1],[3,1,2,2,1,2],[3,2,2,1,1,2],[3,2,2,2,1,1],
  [2,1,2,1,2,3],[2,1,2,3,2,1],[2,3,2,1,2,1],[1,1,1,3,2,3],[1,3,1,1,2,3],
  [1,3,1,3,2,1],[1,1,2,3,1,3],[1,3,2,1,1,3],[1,3,2,3,1,1],[2,1,1,3,1,3],
  [2,3,1,1,1,3],[2,3,1,3,1,1],[1,1,2,1,3,3],[1,1,2,3,3,1],[1,3,2,1,3,1],
  [1,1,3,1,2,3],[1,1,3,3,2,1],[1,3,3,1,2,1],[3,1,3,1,2,1],[2,1,1,1,3,3],
  [2,1,1,3,3,1],[2,3,1,1,3,1],[2,1,3,1,1,3],[2,1,3,3,1,1],[2,1,3,1,3,1],
  [3,1,1,1,2,3],[3,1,1,3,2,1],[3,3,1,1,2,1],[3,1,2,1,1,3],[3,1,2,3,1,1],
  [3,3,2,1,1,1],[3,1,4,1,1,1],[2,2,1,4,1,1],[4,3,1,1,1,1],[1,1,1,2,2,4],
  [1,1,1,4,2,2],[1,2,1,1,2,4],[1,2,1,4,2,1],[1,4,1,1,2,2],[1,4,1,2,2,1],
  [1,1,2,2,1,4],[1,1,2,4,1,2],[1,2,2,1,1,4],[1,2,2,4,1,1],[1,4,2,1,1,2],
  [1,4,2,2,1,1],[2,4,1,2,1,1],[2,2,1,1,1,4],[2,2,1,4,1,1],[2,1,1,1,2,4],
  [2,1,1,4,2,1],[2,1,2,1,1,4],[2,1,2,4,1,1],[2,1,4,1,1,2],[2,1,4,2,1,1],
  [4,1,1,2,1,2],[4,1,1,2,2,1],[4,2,1,1,1,2],[4,2,1,2,1,1],[2,1,2,1,4,1],
  [2,1,4,1,2,1],[4,1,2,1,2,1],[1,1,1,1,4,2],[1,1,1,2,4,1],[1,2,1,1,4,1],
  [1,1,4,1,1,2],[1,1,4,2,1,1],[4,1,1,1,1,2],[4,1,1,2,1,1],[1,1,2,1,1,4],
  [1,1,2,1,4,1],[1,2,1,1,1,4],[1,2,1,4,1,1],[1,4,1,1,1,2],[1,4,1,2,1,1],
  [1,1,1,2,2,3],[1,1,1,3,2,2],[1,3,1,1,2,2],[1,2,1,1,2,3],[1,1,2,1,1,3],
  [2,3,3,1,1,1,2], // STOP (7 elementos)
];

