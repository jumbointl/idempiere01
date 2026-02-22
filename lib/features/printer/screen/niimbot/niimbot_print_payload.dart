// ===============================
// niimbot_print_payload.dart
// ===============================
import 'package:flutter/foundation.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';


/// Qué tipo de etiqueta vas a imprimir con NIIMBOT.
enum NiimbotPayloadType {
  barcode,
  qr,
}

/// Config común de impresión NIIMBOT (niim_blue_flutter).
@immutable
class NiimbotPrintConfig {
  final int density; // 1..5 (depende del modelo)
  final int copies; // cantidad de copias
  final LabelType labelType; // withGaps / continuous, etc.
  final int totalPages; // normalmente 1
  final int statusPollIntervalMs;
  final int statusTimeoutMs;

  const NiimbotPrintConfig({
    this.density = 3,
    this.copies = 1,
    this.labelType = LabelType.withGaps,
    this.totalPages = 1,
    this.statusPollIntervalMs = 100,
    this.statusTimeoutMs = 8000,
  });
  /// TEST + CODE128 (ej: 1234567890123)
  factory NiimbotPrintConfig.default1PageGap() {
    return NiimbotPrintConfig(
      density : 3,
      copies : 1,
      labelType : LabelType.withGaps,
      totalPages : 1,
      statusPollIntervalMs : 100,
      statusTimeoutMs : 8000,
    );
  }
}

/// Tipos de LabelType de niim_blue_flutter.
/// (importante: este enum existe en el paquete; acá lo referenciamos)
/// import 'package:niim_blue_flutter/niim_blue_flutter.dart';
///
/// Si ya lo importás en tu archivo, borrá esta línea comentada:
/// enum LabelType { withGaps, continuous }

/// Datos que definen el contenido de una etiqueta NIIMBOT.
@immutable
class NiimbotPrintPayload {
  final NiimbotPayloadType type;

  /// Tamaño en pixeles para PrintPage(widthPx, heightPx).
  /// Para B1, un buen default es 8 px/mm:
  /// 50mm => 400px, 30mm => 240px.
  final int widthPx;
  final int heightPx;

  /// Texto principal
  final String text;

  /// Para barcode (code128 / ean13, etc.)
  final String? barcodeData;

  /// Para QR
  final String? qrData;

  /// Opciones UI simples (sin render widget)
  final int textFontSize; // relativo, depende del motor del paquete
  final bool textBold;

  /// Config del barcode
  final BarcodeEncoding barcodeEncoding;
  final int barcodeWidth;
  final int barcodeHeight;

  /// Config del QR
  final int qrSize;

  /// Margen/padding simple
  final int padding;

  /// Config de impresión (densidad, copias, labelType, timeouts)
  final NiimbotPrintConfig config;

  const NiimbotPrintPayload({
    required this.type,
    required this.widthPx,
    required this.heightPx,
    required this.text,
    required this.config,
    this.barcodeData,
    this.qrData,
    this.textFontSize = 28,
    this.textBold = true,
    this.barcodeEncoding = BarcodeEncoding.code128,
    this.barcodeWidth = 260,
    this.barcodeHeight = 70,
    this.qrSize = 140,
    this.padding = 12,
  });

  /// TEST + CODE128 (ej: 1234567890123)
  factory NiimbotPrintPayload.textBarcode({
    required int widthPx,
    required int heightPx,
    required String text,
    required String barcode,
    NiimbotPrintConfig config = const NiimbotPrintConfig(),
    BarcodeEncoding encoding = BarcodeEncoding.code128,
    int fontSize = 28,
    bool bold = true,
    int barcodeWidth = 260,
    int barcodeHeight = 70,
    int padding = 12,
  }) {
    return NiimbotPrintPayload(
      type: NiimbotPayloadType.barcode,
      widthPx: widthPx,
      heightPx: heightPx,
      text: text,
      barcodeData: barcode,
      config: config,
      barcodeEncoding: encoding,
      textFontSize: fontSize,
      textBold: bold,
      barcodeWidth: barcodeWidth,
      barcodeHeight: barcodeHeight,
      padding: padding,
    );
  }

  /// Texto + QR
  factory NiimbotPrintPayload.textQr({
    required int widthPx,
    required int heightPx,
    required String text,
    required String qr,
    NiimbotPrintConfig config = const NiimbotPrintConfig(),
    int fontSize = 28,
    bool bold = true,
    int qrSize = 140,
    int padding = 12,
  }) {
    return NiimbotPrintPayload(
      type: NiimbotPayloadType.qr,
      widthPx: widthPx,
      heightPx: heightPx,
      text: text,
      qrData: qr,
      config: config,
      textFontSize: fontSize,
      textBold: bold,
      qrSize: qrSize,
      padding: padding,
    );
  }

  /// Helper para el caso típico B1 50x30mm con 8 px/mm.
  static NiimbotPrintPayload test50x30TextBarcode({
    String text = 'TEST',
    String barcode = '1234567890123',
    int pixelsPerMm = 8, // B1 suele andar bien
    NiimbotPrintConfig config = const NiimbotPrintConfig(),
  }) {
    final w = 50 * pixelsPerMm; // 400
    final h = 30 * pixelsPerMm; // 240
    return NiimbotPrintPayload.textBarcode(
      widthPx: w,
      heightPx: h,
      text: text,
      barcode: barcode,
      config: config,
    );
  }
}

/// BarcodeEncoding de niim_blue_flutter.
/// (Este enum existe en el paquete; lo referenciás al importarlo)
/// import 'package:niim_blue_flutter/niim_blue_flutter.dart';
///
/// Si ya lo importás, no copies esto.
/// enum BarcodeEncoding { code128, ean13, qr /* ... */ }
