// print_receipt_with_qr_bematech.dart
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:barcode_image/barcode_image.dart' as img_barcode;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List, ByteData;
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:monalisa_app_001/features/printer/pos/pos_logo_and_qr_with_aligment.dart';
import 'package:monalisa_app_001/features/printer/pos/pos_text_utils.dart';
import 'package:monalisa_app_001/features/printer/pos/printer_action_notifier.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../products/common/messages_dialog.dart';
import '../../products/domain/idempiere/idempiere_movement_line.dart';
import '../../products/domain/idempiere/movement_and_lines.dart';
import '../../products/presentation/providers/common_provider.dart';
import '../../products/presentation/providers/product_provider_common.dart';
import '../../products/presentation/screens/movement/pos/movement_direct_print.dart';
import '../../shared/data/memory.dart';
import '../../shared/data/messages.dart';
import 'PosTicket.dart';
import 'bematech_escpos.dart';
import 'pos_adjustment_selector_sheet.dart';
import 'pos_adjustment_values.dart';

const int qrSize = 110;
const int rightMargin = 0;
const int barcodeWidthBase = 440;
const int maxCharacterBarcodeOneRow = 17;

/// ✅ Impresión para Bematech MP-4200 TH
/// - Usa selector de perfiles (GetStorage)
/// - Aplica CP850 via ESC t 2 (más confiable en Bematech)
/// - Ajusta ancho de imágenes con perfil (576 + adj)
Future<void> printReceiptWithQrWithBematech(
    WidgetRef ref,
    String ip,
    int port,
    MovementAndLines movementAndLines,
    ) async {
  if (ip.isEmpty || port == 0) return;
  debugPrint('printReceiptWithQrWithBematech');
  ref.read(isDialogShowedProvider.notifier).state = true ;
  ref.read(enableScannerKeyboardProvider.notifier).state = false ;
  final actual = ref.read(actionScanProvider);
  ref.read(actionScanProvider.notifier).state = Memory.ACTION_NO_SCAN_ACTION ;


  final PosAdjustmentValues? adj = await showPosAdjustmentSelectorSheet(
    context: ref.context,
    ref: ref,
    ip: ip,
    port: port,
    alwaysOpen: false,
  );

  ref.read(enableScannerKeyboardProvider.notifier).state = true ;
  ref.read(actionScanProvider.notifier).state = actual ;
  ref.read(isDialogShowedProvider.notifier).state = false ;
  if (adj == null) return;

  debugPrint('Model ${adj.machineModel}');
  debugPrint('Model ${adj.charactersPerLineAdjustment}');
  debugPrint('Model ${adj.charSet}');
  final int cols =
      BematechEscPos.baseCols(adj.paperSize) +
          adj.charactersPerLineAdjustment;



  final profile = await CapabilityProfile.load();
  final generator = Generator(adj.paperSize, profile);
  ///Code Page 0 CP437
  // Code Page 1 CP932
  // Code Page 2 CP850
  // Code Page 3 CP860
  // Code Page 4 CP863
  // Code Page 5 CP865
  // Code Page 6 Unknown
  // Code Page 7 Unknown
  // Code Page 8 Unknown
  // Code Page 11 CP851
  // Code Page 12 CP853
  // Code Page 13 CP857
  // Code Page 14 CP737
  // Code Page 15 ISO_8859-7
  // Code Page 16 CP1252
  // Code Page 17 CP866
  // Code Page 18 CP852
  // Code Page 19 CP858
  // Code Page 20 Unknown
  // Code Page 21 CP874
  // Code Page 22 Unknown
  // Code Page 23 Unknown
  // Code Page 24 Unknown
  // Code Page 25 Unknown
  // Code Page 26 Unknown
  // Code Page 30 TCVN-3-1
  // Code Page 31 TCVN-3-2
  // Code Page 32 CP720
  // Code Page 33 CP775
  // Code Page 34 CP855
  // Code Page 35 CP861
  // Code Page 36 CP862
  // Code Page 37 CP864
  // Code Page 38 CP869
  // Code Page 39 ISO_8859-2
  // Code Page 40 ISO_8859-15
  // Code Page 41 CP1098
  // Code Page 42 CP774
  // Code Page 43 CP772
  // Code Page 44 CP1125
  // Code Page 45 CP1250
  // Code Page 46 CP1251
  // Code Page 47 CP1253
  // Code Page 48 CP1254
  // Code Page 49 CP1255
  // Code Page 50 CP1256
  // Code Page 51 CP1257
  // Code Page 52 CP1258
  // Code Page 53 RK1048---------- HEADER ----------
  ///

  List<int> bytes = [];
  bytes += generator.reset();
 String codePage ='CP1252';
 switch (adj.charSet) {
   case PosCharSet.cp850:
     codePage = 'CP850';
     break;
   case PosCharSet.cp1252:
     codePage = 'CP1252';
     break;
   case PosCharSet.cp858:
     codePage = 'CP858';
     break;
   default:
     codePage = 'CP1252';
     break;
 }



  bytes += generator.setGlobalCodeTable(codePage);

  // ✅ Bematech: set CP850 (ESC t 2) si perfil dice cp850
  bytes += BematechEscPos.applyCharSet(adj);



  // Si quisieras intentar setGlobalCodeTable también:
  // if (adj.charSet == PosCharSet.cp1252) bytes += generator.setGlobalCodeTable('CP1252');
  // if (adj.charSet == PosCharSet.cp850) bytes += generator.setGlobalCodeTable('CP850');

  // ---------- LOGO + QR ----------
  final String qrData = movementAndLines.documentNumber;
  final String title = movementAndLines.documentMovementTitle;
  final String logo = movementAndLines.movementIcon;
  final int imageWidth = BematechEscPos.imageWidthDots(adj);

  final barData = '{B$qrData';
  final barcodeDocNo = Barcode.code128(barData.split(""));

  bytes += generator.barcode(
    barcodeDocNo,
    width: 1,
    height: 40,
    font: BarcodeFont.fontB,
    textPos: BarcodeText.below,
  );

  bytes += generator.feed(1);
  // ---------- DOCUMENT BARCODE (HEADER) ----------
  final Uint8List barcodeHeaderBytes = await combineBarcodeOnly(
    barcodeData: qrData,
    totalWidth: imageWidth,
    barcodeWidthBase : imageWidth-20,
  );

  final img.Image? barcodeHeaderImage =
  img.decodeImage(barcodeHeaderBytes);

  if (barcodeHeaderImage != null) {
    bytes += generator.image(barcodeHeaderImage);
    bytes += generator.feed(1);
  }



  final Uint8List headerBytes = await combineLogoAndQrCode(
    logo: logo,
    qrData: qrData,
    totalWidth: imageWidth,
  );
  final img.Image? headerImage = img.decodeImage(headerBytes);

  if (headerImage != null) {
    bytes += generator.image(headerImage);
    bytes += generator.feed(1);
  }

  // ---------- CABECERA ----------
  final String date = movementAndLines.movementDate ?? '';
  final String company = movementAndLines.cBPartnerID?.identifier ?? '';
  final String documentNumber = movementAndLines.documentNumber;
  final String documentStatus = movementAndLines.documentStatus;
  final String address = movementAndLines.cBPartnerLocationID?.identifier ?? '';
  final String description = movementAndLines.description ?? '';

  bytes += generator.row([
    PosColumn(text: '', width: 1),
    PosColumn(
      text: title,
      width: 10,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ),
    PosColumn(text: '', width: 1),
  ]);
  bytes += generator.feed(1);

  bytes += generator.row([
    PosColumn(text: date, width: 6, styles: const PosStyles(align: PosAlign.left)),
    PosColumn(text: '', width: 6, styles: const PosStyles(align: PosAlign.right)),
  ]);

  bytes += generator.row([
    PosColumn(text: documentStatus, width: 4, styles: const PosStyles(align: PosAlign.left)),
    PosColumn(
      text: documentNumber,
      width: 8,
      styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
    ),
  ]);

  addTextByMode(
    bytes: bytes,
    gen: generator,
    adj: adj,
    text: company,
  );

  addTextByMode(
    bytes: bytes,
    gen: generator,
    adj: adj,
    text: address,
  );

  print('description test hr 1 $cols');
  if (description.isNotEmpty) bytes += generator.text(description);
  bytes += generator.feed(1);
  //addHrSafeNormal(bytes: bytes, gen: generator, adj: adj, cols: cols);
  bytes += generator.hr(ch: '-',len: cols);

  // ---------- TABLA TITULOS ----------
  bytes += generator.row([
    PosColumn(text: 'UPC/SKU', width: 6, styles: const PosStyles(align: PosAlign.left)),
    PosColumn(text: 'HASTA/DESDE', width: 6, styles: const PosStyles(align: PosAlign.right)),
  ]);
  bytes += generator.row([
    PosColumn(text: 'ATTRIBUTO', width: 6, styles: const PosStyles(align: PosAlign.left)),
    PosColumn(text: 'CANTIDAD', width: 6, styles: const PosStyles(align: PosAlign.right)),
  ]);
  bytes += generator.row([
    PosColumn(text: 'LINEA/NOMBRE DE PRODUCTO', width: 7, styles: const PosStyles(align: PosAlign.left)),
    PosColumn(text: '', width: 5),
  ]);
  //addHrSafeNormal(bytes: bytes, gen: generator, adj: adj, cols: cols);
  bytes += generator.hr(ch: '-',len: cols);

  // ---------- DETALLE ----------
  final List<IdempiereMovementLine> rows = movementAndLines.movementLines ?? [];
  double totalItems = 0;

  for (int i = 0; i < rows.length; i++) {
    final line = rows[i];
    final double quantity = line.movementQty ?? 0;
    totalItems += quantity;

    final String quantityStr = Memory.numberFormatter0Digit.format(quantity);
    final String product = line.productNameWithLine;
    final String upc = line.uPC ?? '';
    final String sku = line.sKU ?? '';
    final String to = line.locatorToName ?? '';
    final String from = line.locatorFromName ?? '';
    final String atr = line.attributeName ?? '--';

    bytes += generator.row([
      PosColumn(text: upc, width: 5, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: to, width: 7, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: sku, width: 5, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: from, width: 7, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: atr, width: 5, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: '', width: 7),
    ]);
    final String productSafe = sanitizeForPos(product);
    bytes += generator.row([
      PosColumn(text: productSafe, width: 7, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
        text: quantityStr,
        width: 5,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
      ),
    ]);
    //addHrSafeNormal(bytes: bytes, gen: generator, adj: adj, cols: cols);
    if(i<rows.length-1) {
      bytes += generator.hr(ch: '-',len: cols);
    } else {
      bytes += generator.hr(ch: '=',len: cols,linesAfter: 1);
    }
  }
  int totalColWidth = 6;
  if(adj.paperSize!=PaperSize.mm80){
    totalColWidth = 7;
  }
  PosTextSize totalFontWidth = PosTextSize.size2;
  if(adj.paperSize==PaperSize.mm58) {
    totalFontWidth = PosTextSize.size1;
  }

  final String totalItemsString = Memory.numberFormatter0Digit.format(totalItems);
  bytes += generator.row([
    PosColumn(
      text: 'ITEMS TOTAL',
      width: totalColWidth,
      styles: PosStyles(align: PosAlign.left, height: PosTextSize.size2, width: totalFontWidth),
    ),
    PosColumn(
      text: totalItemsString,
      width: 12-totalColWidth,
      styles: PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: totalFontWidth),
    ),
  ]);

  bytes += generator.feed(1);

  // ---------- CONFIRMS (QR+BARCODE) ----------
  final confirms = movementAndLines.movementConfirms ?? [];
  if (confirms.isNotEmpty) {
    for (final movementConfirm in confirms) {
      String barcodeData = movementConfirm.documentNo ?? '';
      final String qr = movementConfirm.documentNo ?? '';

      if (barcodeData.length <= maxCharacterBarcodeOneRow) {
        final Uint8List imgBytes = await combineQrAndBarcode(
          qrData: qr,
          barcodeData: barcodeData,
          totalWidth: imageWidth,
        );
        final img.Image? combined = img.decodeImage(imgBytes);
        if (combined != null) {
          bytes += generator.image(combined);
          bytes += generator.feed(1);
        }
      } else {
        bytes += generator.qrcode(qr, size: QRSize.size5, cor: QRCorrection.L);
        bytes += generator.feed(1);

        // Code128 (Bematech suele ok)
        barcodeData = '{B$barcodeData';
        final barcode = Barcode.code128(barcodeData.split(""));


        bytes += generator.barcode(
          barcode,
          width: 1,
          height: 40,
          font: BarcodeFont.fontB,
          textPos: BarcodeText.below,
        );
        bytes += generator.feed(1);
      }
    }
  }

  // ---------- FOOTER ----------
  final now = DateTime.now();
  String datetime = now.toIso8601String().split('.').first.replaceAll('T', ' ');
  bytes += generator.text(datetime, styles: const PosStyles(align: PosAlign.center));

  bytes += generator.feed(5);
  bytes += generator.cut();

  await printPosTicket(ref, ip, port, bytes);
}

Future<void> printPosTicket(WidgetRef ref, String ip, int port, List<int> ticket) async {
  PosTicket ticketPrint = PosTicket( ip: ip, port: port, ticket: ticket);

  final act =ref.read(printTicketBySocketActionProvider);
  await act.setAndFire(ticketPrint);

  /*final printer = PrinterNetworkManager(ip, port: port);
  final connect = await printer.connect();

  if (connect == PosPrintResult.success) {
    await printer.printTicket(ticket);
    if (ref.context.mounted) {
      showSuccessMessage(ref.context, ref, Messages.PRINT_SUCCESS);
    }
    await Future.delayed(const Duration(seconds: 1));
    printer.disconnect();
  } else {
    if (ref.context.mounted) {
      showErrorMessage(ref.context, ref, Messages.ERROR_TIMEOUT);
    }
  }*/
}

Future<bool> printPosTicketNoRef(String ip, int port, List<int> ticket) async {
  final printer = PrinterNetworkManager(ip, port: port);
  final connect = await printer.connect();

  if (connect == PosPrintResult.success) {
    await printer.printTicket(ticket);
    await Future.delayed(const Duration(seconds: 1));
    printer.disconnect();
    return true;
  } else {
    return false;
  }
}

// --------------------- IMAGES ---------------------

Future<Uint8List> combineQrAndBarcode({
  required String qrData,
  required String barcodeData,
  required int totalWidth,
}) async {
  final int targetHeight = qrSize;

  // QR
  final qrPainter = QrPainter(data: qrData, version: QrVersions.auto, gapless: false);
  final ui.Image qrUi = await qrPainter.toImage(targetHeight.toDouble());
  final ByteData? qrByteData = await qrUi.toByteData(format: ui.ImageByteFormat.png);
  final img.Image qrImage = img.decodeImage(qrByteData!.buffer.asUint8List())!;

  // Barcode image
  int finalBarcodeWidth = barcodeWidthBase;
  if (barcodeData.length < 8) {
    finalBarcodeWidth = 250;
  } else if (barcodeData.length < 10) {
    finalBarcodeWidth = 280;
  } else if (barcodeData.length < 14) {
    finalBarcodeWidth = 320;
  }

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

  // Merge
  final img.Image merged =
  img.Image(width: totalWidth, height: targetHeight, numChannels: 3);
  img.fill(merged, color: img.ColorRgb8(255, 255, 255));

  img.compositeImage(merged, qrImage, dstX: 0, dstY: 0);
  img.compositeImage(
    merged,
    barcodeImage,
    dstX: totalWidth - barcodeImage.width - rightMargin,
    dstY: 0,
  );

  return Uint8List.fromList(img.encodePng(merged));
}

Future<Uint8List> combineLogoAndQrCode({
  required String logo,
  required String qrData,
  required int totalWidth,
}) async {
  // Logo local (tu asset)
  final ByteData logoBytes = await rootBundle.load('assets/images/monalisa_logo_movement.jpg');
  img.Image logoImage = img.decodeImage(logoBytes.buffer.asUint8List())!;
  logoImage = img.copyResize(logoImage, width: qrSize);

  // QR
  final qrPainter = QrPainter(data: qrData, version: QrVersions.auto, gapless: false);
  final ui.Image qrUiImage = await qrPainter.toImage(qrSize.toDouble());
  final ByteData? qrByteData = await qrUiImage.toByteData(format: ui.ImageByteFormat.png);
  img.Image qrImage = img.decodeImage(qrByteData!.buffer.asUint8List())!;

  final int maxHeight = logoImage.height > qrImage.height ? logoImage.height : qrImage.height;
  final img.Image merged =
  img.Image(width: totalWidth, height: maxHeight, numChannels: 3);
  img.fill(merged, color: img.ColorRgb8(255, 255, 255));

  img.compositeImage(
    merged,
    logoImage,
    dstX: 0,
    dstY: (maxHeight - logoImage.height) ~/ 2,
    blend: img.BlendMode.alpha,
  );
  img.compositeImage(
    merged,
    qrImage,
    dstX: totalWidth - qrImage.width - rightMargin,
    dstY: (maxHeight - qrImage.height) ~/ 2,
    blend: img.BlendMode.alpha,
  );

  return Uint8List.fromList(img.encodePng(merged));
}


String sanitizeForPos(String input) {
  var s = input;

  // 1) Reemplazos comunes “problemáticos” → equivalentes simples
  const map = {
    // guiones raros
    '\u2010': '-', // hyphen
    '\u2011': '-', // non-breaking hyphen
    '\u2012': '-', // figure dash
    '\u2013': '-', // en dash  ← TU CASO
    '\u2014': '-', // em dash
    '\u2212': '-', // minus sign

    // comillas “inteligentes”
    '\u2018': "'", // left single quote
    '\u2019': "'", // right single quote
    '\u201C': '"', // left double quote
    '\u201D': '"', // right double quote

    // puntos suspensivos
    '\u2026': '...',

    // espacio duro
    '\u00A0': ' ',

    // bullets
    '\u2022': '*',
  };

  map.forEach((k, v) => s = s.replaceAll(k, v));

  // 2) (Opcional) Normalizar algunos símbolos sueltos que también dan guerra
  // Ej: º ª € dependiendo del encoder/tabla
  // s = s.replaceAll('€', 'EUR');

  // 3) Filtro final: eliminar cualquier cosa que aún no quepa en latin1
  // (así nunca más te tira exception)
  final sb = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    try {
      latin1.encode(ch);
      sb.write(ch);
    } catch (_) {
      sb.write('?'); // o '' para eliminar
    }
  }
  return sb.toString();
}

