import 'dart:ui' as ui;
// Necesario para BarcodeWidget y BuildContext
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List, ByteData;
import 'dart:async';
// Para ui.Image, ui.PictureRecorder, etc.
import 'package:barcode_image/barcode_image.dart' as img_barcode;

final int imageWidth80mm = 576;
final int leftMargin = 20;
final int rightMargin = 0;
final int qrSize = 110;
final int barcodeWidth =440;


// Función para generar el QR como ui.Image
Future<ui.Image> generateQrImage(String data, double size) async {
  final qrPainter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: false,
  );
  return await qrPainter.toImage(size);
}

// Función principal para combinar
Future<Uint8List> combineQrAndBarcode(String qrData, String barcodeData) async {

  final int targetHeight = qrSize; // Altura objetivo para ambos

  // --- 1. Generar el QR Code (tu código existente funciona bien) ---
  // ... (código QR Painter a ui.Image a img.Image) ...
  final qrPainter = QrPainter(data: qrData, version: QrVersions.auto, gapless: false);
  final ui.Image qrUiImage = await qrPainter.toImage(targetHeight.toDouble());
  final ByteData? qrByteData = await qrUiImage.toByteData(format: ui.ImageByteFormat.png);
  final img.Image qrImage = img.decodeImage(qrByteData!.buffer.asUint8List())!;


  // --- 2. Generar el Barcode usando barcode_image ---
  // Crear una imagen 'img.Image' vacía donde dibujar el barcode
  int finalBarcodeWidth = barcodeWidth;
  if(barcodeData.length<8){
    finalBarcodeWidth = 250;
  }else if(barcodeData.length<10){
    finalBarcodeWidth = 280;
  } else if(barcodeData.length<14){
    finalBarcodeWidth = 320;
  }
  final img.Image barcodeImage = img.Image(width: finalBarcodeWidth, height: targetHeight, numChannels: 3);
  img.fill(barcodeImage, color: img.ColorRgb8(255, 255, 255)); // Fondo blanco
  final img.BitmapFont font = img.arial24;
  // Dibujar el Code 128 en la imagen usando el paquete barcode_image

  img_barcode.drawBarcode(
    barcodeImage,
    img_barcode.Barcode.code128(
      useCode128B: true,
    ), // Usa la simbología code128 del paquete barcode_image
    barcodeData,
    width: finalBarcodeWidth,
    height: targetHeight,
    font: font,
    textPadding: 5

  );

  // --- 3. Combinar las dos imágenes ---
  //final int spacing = 10;
  //final int totalWidth = qrImage.width + barcodeImage.width + spacing;
  final int totalWidth = imageWidth80mm;
  final img.Image mergedImage = img.Image(width: totalWidth, height: targetHeight, numChannels: 3);
  img.fill(mergedImage, color: img.ColorRgb8(255, 255, 255));

  img.compositeImage(mergedImage, qrImage, dstX: 0, dstY: 0);
  img.compositeImage(mergedImage, barcodeImage, dstX: totalWidth-barcodeImage.width-rightMargin, dstY: 0);

  // 4. Codificar la imagen combinada a bytes
  final Uint8List combinedImageBytes = Uint8List.fromList(img.encodePng(mergedImage));

  return combinedImageBytes;


}

Future<Uint8List> combineLogoAndQrCode({required String logo, required String qrData}) async {
  // --- 1. Cargar y decodificar el Logo ---
  final ByteData logoBytes = await rootBundle.load('assets/images/monalisa_logo_movement.jpg');
  img.Image logoImage = img.decodeImage(logoBytes.buffer.asUint8List())!;

  // Opcional: Redimensionar el logo si es muy grande. Ejemplo: 100px de ancho.
  logoImage = img.copyResize(logoImage, width: qrSize);

  // --- 2. Generar y decodificar el QR Code ---


  final qrPainter = QrPainter(
    data: qrData,
    version: QrVersions.auto,
    gapless: false,
  );

  // Convertir el QrPainter a ui.Image
  final ui.Image qrUiImage = await qrPainter.toImage(qrSize.toDouble());

  // Convertir ui.Image a formato img.Image (paquete 'image')
  final ByteData? qrByteData = await qrUiImage.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List qrUint8List = qrByteData!.buffer.asUint8List();
  img.Image qrImage = img.decodeImage(qrUint8List)!;
  // --- 3. Combinar las dos imágenes usando compositeImage ---

  // Calcular las dimensiones de la nueva imagen combinada
  //final int totalWidth = logoImage.width + qrImage.width + 10; // Añadir un pequeño margen
  final int totalWidth = imageWidth80mm; // Añadir un pequeño margen
  final int maxHeight = logoImage.height > qrImage.height ? logoImage.height : qrImage.height;

  // Crear un nuevo lienzo (fondo blanco)
  final img.Image mergedImage = img.Image(width: totalWidth, height: maxHeight, numChannels: 3);
  img.fill(mergedImage, color: img.ColorRgb8(255, 255, 255));

  // Copiar el logo a la izquierda (x: 0, y: centrado verticalmente)
  img.compositeImage(
    mergedImage,
    logoImage,
    dstX: 0,
    dstY: (maxHeight - logoImage.height) ~/ 2, // Centrado vertical
    blend: img.BlendMode.alpha, // Modo de mezcla normal
  );

  // Copiar el QR a la derecha (x: ancho del logo + margen, y: centrado verticalmente)
  img.compositeImage(
    mergedImage,
    qrImage,
    //dstX: logoImage.width + 10, // Posición después del logo + margen
    dstX: totalWidth - qrImage.width-rightMargin, // Posición después del logo + margen
    dstY: (maxHeight - qrImage.height) ~/ 2, // Centrado vertical
    blend: img.BlendMode.alpha,
  );

  // 4. Codificar la imagen combinada a bytes
  final Uint8List combinedImageBytes = Uint8List.fromList(img.encodePng(mergedImage));

  return combinedImageBytes;

}

/// Convierte bytes PNG/JPG a ZPL ^GFA (inline).
/// - 203dpi (8 dots/mm): etiqueta 100mm => 800 dots.
/// - threshold: más alto => imprime más negro.
/// - invert: si sale invertido, pon true.
String pngBytesToZplGfa(
    Uint8List bytes, {
      int? targetWidthDots,
      int? targetHeightDots,
      int threshold = 170,
      bool invert = false,
    }) {
  img.Image? image = img.decodeImage(bytes);
  if (image == null) {
    throw Exception('pngBytesToZplGfa: decodeImage = null');
  }

  // Resize opcional
  if (targetWidthDots != null || targetHeightDots != null) {
    final w = targetWidthDots ?? image.width;
    final h = targetHeightDots ?? (image.height * (w / image.width)).round();
    image = img.copyResize(
      image,
      width: w,
      height: h,
      interpolation: img.Interpolation.average,
    );
  }

  final width = image.width;
  final height = image.height;

  final bytesPerRow = ((width + 7) ~/ 8);
  final totalBytes = bytesPerRow * height;
  final out = Uint8List(totalBytes);

  int outIndex = 0;

  for (int y = 0; y < height; y++) {
    int bit = 7;
    int currentByte = 0;

    for (int x = 0; x < width; x++) {
      final p = image.getPixel(x, y); // Pixel (image v4+)

      final r = p.r;
      final g = p.g;
      final b = p.b;

      // luminancia (0 = negro, 255 = blanco aprox)
      final lum = (0.299 * r + 0.587 * g + 0.114 * b);

      // En ZPL: bit 1 = punto negro impreso
      bool isBlack = lum < threshold;
      if (invert) isBlack = !isBlack;

      if (isBlack) {
        currentByte |= (1 << bit);
      }

      bit--;
      if (bit < 0) {
        out[outIndex++] = currentByte;
        currentByte = 0;
        bit = 7;
      }
    }

    // Si la fila no terminó justo en un byte, escribe el byte parcial
    if (bit != 7) {
      out[outIndex++] = currentByte;
    }
  }

  // HEX
  final hex = StringBuffer();
  for (final b in out) {
    hex.write(b.toRadixString(16).padLeft(2, '0').toUpperCase());
  }

  // ^GFA,totalBytes,bytesUsados,bytesPorFila,DATA
  return '^GFA,$totalBytes,$totalBytes,$bytesPerRow,${hex.toString()}';
}


