import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_image/barcode_image.dart' as img_barcode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';


// Ajusta estos valores a tu gusto:
const int qrSize = 110; // px del QR y logo (logo se resizea a este ancho)
const int rightMargin = 6; // margen derecho (px) dentro del header
const int borderLSize = 12; // tamaño de la "L" en esquinas
const int borderStroke = 1; // grosor en px para líneas

/// ✅ TU combineLogoAndQrCode, pero mejorado:
/// - Usa logoAssetPath real
/// - QR pegado a la derecha con margen fijo
/// - Marcas de borde (líneas + esquinas) para ver recorte a simple vista
Future<Uint8List> combineLogoAndQrCodeWithAlignment({
  required String logo, // asset path
  required String qrData,
  required int totalWidth,
  bool? showBorderMarks,
}) async {
  // Logo desde asset path recibido
  final ByteData logoBytes = await rootBundle.load(logo);
  img.Image logoImage = img.decodeImage(logoBytes.buffer.asUint8List())!;
  logoImage = img.copyResize(logoImage, width: qrSize);

  // QR
  final qrPainter = QrPainter(
    data: qrData,
    version: QrVersions.auto,
    gapless: false,
  );
  final ui.Image qrUiImage = await qrPainter.toImage(qrSize.toDouble());
  final ByteData? qrByteData = await qrUiImage.toByteData(format: ui.ImageByteFormat.png);
  img.Image qrImage = img.decodeImage(qrByteData!.buffer.asUint8List())!;

  final int maxHeight = (logoImage.height > qrImage.height) ? logoImage.height : qrImage.height;

  final img.Image merged = img.Image(
    width: totalWidth,
    height: maxHeight,
    numChannels: 3,
  );

  // Fondo blanco
  img.fill(merged, color: img.ColorRgb8(255, 255, 255));

  // --- Marcas de borde (para detectar recorte) ---
  if(showBorderMarks==true)_drawBorderMarks(merged);

  // Logo a la izquierda
  img.compositeImage(
    merged,
    logoImage,
    dstX: 0,
    dstY: (maxHeight - logoImage.height) ~/ 2,
    blend: img.BlendMode.alpha,
  );

  // QR a la derecha (respetando margen)
  final int qrX = totalWidth - qrImage.width - rightMargin;
  img.compositeImage(
    merged,
    qrImage,
    dstX: qrX < 0 ? 0 : qrX,
    dstY: (maxHeight - qrImage.height) ~/ 2,
    blend: img.BlendMode.alpha,
  );

  return Uint8List.fromList(img.encodePng(merged));
}

void _drawBorderMarks(img.Image canvas) {
  final int w = canvas.width;
  final int h = canvas.height;

  final black = img.ColorRgb8(0, 0, 0);

  // líneas verticales izquierda/derecha
  for (int s = 0; s < borderStroke; s++) {
    img.drawLine(canvas, x1: 0 + s, y1: 0, x2: 0 + s, y2: h - 1, color: black);
    img.drawLine(canvas, x1: (w - 1) - s, y1: 0, x2: (w - 1) - s, y2: h - 1, color: black);
  }

  // "L" en esquinas (arriba izq)
  img.drawLine(canvas, x1: 0, y1: 0, x2: borderLSize, y2: 0, color: black);
  img.drawLine(canvas, x1: 0, y1: 0, x2: 0, y2: borderLSize, color: black);

  // arriba der
  img.drawLine(canvas, x1: w - 1, y1: 0, x2: w - 1 - borderLSize, y2: 0, color: black);
  img.drawLine(canvas, x1: w - 1, y1: 0, x2: w - 1, y2: borderLSize, color: black);

  // abajo izq
  img.drawLine(canvas, x1: 0, y1: h - 1, x2: borderLSize, y2: h - 1, color: black);
  img.drawLine(canvas, x1: 0, y1: h - 1, x2: 0, y2: h - 1 - borderLSize, color: black);

  // abajo der
  img.drawLine(canvas, x1: w - 1, y1: h - 1, x2: w - 1 - borderLSize, y2: h - 1, color: black);
  img.drawLine(canvas, x1: w - 1, y1: h - 1, x2: w - 1, y2: h - 1 - borderLSize, color: black);
}

/// Combines a single Code128 barcode into an image with fixed height
/// Used for header printing where ESC/POS native barcode is unreliable
Future<Uint8List> combineBarcodeOnly({
  required String barcodeData,
  required int totalWidth,
  required int barcodeWidthBase,
}) async {
  final int targetHeight = qrSize;

  // --- Calculate barcode width dynamically ---
  int finalBarcodeWidth = barcodeWidthBase;
  if (barcodeData.length < 8) {
    finalBarcodeWidth = 250;
  } else if (barcodeData.length < 10) {
    finalBarcodeWidth = 280;
  } else if (barcodeData.length < 14) {
    finalBarcodeWidth = 320;
  }
  debugPrint('finalBarcodeWidth: $finalBarcodeWidth');

  // --- Create barcode image ---
  final img.Image barcodeImage =
  img.Image(width: finalBarcodeWidth, height: targetHeight, numChannels: 3);
  img.fill(barcodeImage, color: img.ColorRgb8(255, 255, 255));

  img_barcode.drawBarcode(
    barcodeImage,
    img_barcode.Barcode.code128(useCode128B: true),
    barcodeData,
    width: finalBarcodeWidth,
    height: targetHeight,
    font: img.arial24,
    textPadding: 5,
  );

  // --- Create final canvas ---
  final img.Image merged =
  img.Image(width: totalWidth, height: targetHeight, numChannels: 3);
  img.fill(merged, color: img.ColorRgb8(255, 255, 255));

  // Center barcode horizontally
  final int x = ((totalWidth - barcodeImage.width) / 2).round();
  img.compositeImage(merged, barcodeImage, dstX: x, dstY: 0);

  return Uint8List.fromList(img.encodePng(merged));
}
