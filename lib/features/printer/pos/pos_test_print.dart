// pos_test_print.dart
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:image/image.dart' as img;
import 'package:monalisa_app_001/features/printer/pos/pos_logo_and_qr_with_aligment.dart';

import 'bematech_escpos.dart';
import 'pos_adjustment_values.dart';
import 'pos_text_utils.dart';

class PosWidthCandidate {
  final int colsBaseDelta; // 0 / -2 / -4 / -6 / -7
  final String label;
  const PosWidthCandidate(this.colsBaseDelta, this.label);
}

const widthCandidates = <PosWidthCandidate>[
  PosWidthCandidate(0,  '0 (baseline)'),
  PosWidthCandidate(-2, '-2'),
  PosWidthCandidate(-4, '-4'),
  PosWidthCandidate(-6, '-6'),
  PosWidthCandidate(-7, '-7'),
];

int baseColsForPaper(PaperSize p) {
  if (p == PaperSize.mm58) return 32;
  if (p == PaperSize.mm72) return 42;
  return 48; // mm80
}

const widthAdjSuggestions = <int>[0, -8, -16];

Future<PosPrintResult> printWidthTestTicket({
  required String ip,
  required int port,
  required String printerName,
  required PaperSize paperSize,
}) async {


  final profile = await CapabilityProfile.load();
  final gen = Generator(paperSize, profile);

  final baseCols = baseColsForPaper(paperSize);

  List<int> bytes = [];
  bytes += gen.reset();
  bytes += gen.text('TEST ANCHO POS', styles: const PosStyles(align: PosAlign.center, bold: true));
  bytes += gen.text('Impresora: $printerName', styles: const PosStyles(align: PosAlign.center));
  bytes += gen.text('Paper: ${paperSize.value}  baseCols=$baseCols', styles: const PosStyles(align: PosAlign.center));
  bytes += gen.hr();
  bytes += gen.text('Elige la opcion que NO se corta y llega al borde.');

  for (int i = 0; i < widthCandidates.length; i++) {
    final c = widthCandidates[i];
    final nCols = baseCols + c.colsBaseDelta;

    bytes += gen.text('OPCION ${i + 1}: cols=$nCols (adj=${c.colsBaseDelta})',
        styles: const PosStyles(bold: true));

    // regla + marcador
    final rule = '|${'-' * (nCols - 2)}|';
    bytes += gen.text(rule);
    bytes += gen.text(_markerLine(nCols));
    bytes += gen.hr();
  }

  bytes += gen.feed(2);
  bytes += gen.cut();


  final printer = PrinterNetworkManager(ip, port: port);
  final conn = await printer.connect();
  if (conn != PosPrintResult.success) return conn;

  final res = await printer.printTicket(bytes);
  await Future.delayed(const Duration(seconds: 1));
  printer.disconnect();


  return res;
}

String _markerLine(int nCols) {
  final buf = StringBuffer();
  for (int i = 1; i <= nCols; i++) {
    if (i == 1) {
      buf.write('1');
    } else if (i % 10 == 0) buf.write((i ~/ 10) % 10);
    else buf.write('.');
  }
  return buf.toString();
}



/// Test REAL header imagen (logo + QR) variando printWidthAdjustment.
/// Elegir el que NO corta borde derecho y QR completo.
Future<PaperSize?> pickPaperSizeDialog(BuildContext context) {
  return showDialog<PaperSize>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Seleccionar PaperSize'),
        content: const Text('Elige el tamaño real del papel para el test de header.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, PaperSize.mm58),
            child: const Text('58mm (384)'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, PaperSize.mm72),
            child: const Text('72mm (512)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, PaperSize.mm80),
            child: const Text('80mm (576)'),
          ),
        ],
      );
    },
  );
}

Future<PosPrintResult> printWidthAdjustmentHeaderTestTicket({
  required BuildContext context, // ✅ NUEVO
  required String ip,
  required int port,
  required String printerName,
  required PosAdjustmentValues baseAdj,
  required String logoAssetPath,
  required String qrData,
  required PaperSize paperSize,
}) async {

  final profile = await CapabilityProfile.load();
  final gen = Generator(paperSize, profile);

  List<int> bytes = [];
  bytes += gen.reset();

  bytes += gen.text(
    'TEST HEADER (LOGO+QR)',
    styles: const PosStyles(align: PosAlign.center, bold: true),
  );
  bytes += gen.text(
    'Impresora: $printerName',
    styles: const PosStyles(align: PosAlign.center),
  );
  bytes += gen.text(
    'Paper: ${paperSize == PaperSize.mm58 ? "58mm" : paperSize == PaperSize.mm72 ? "72mm" : "80mm"}',
    styles: const PosStyles(align: PosAlign.center),
  );
  bytes += gen.text(
    'Ajustando: printWidthAdjustment (dots)',
    styles: const PosStyles(align: PosAlign.center),
  );
  bytes += gen.hr();
  bytes += gen.text('Elige la opcion donde NO se corta el borde derecho.');

  for (int i = 0; i < widthAdjSuggestions.length; i++) {
    final wAdj = widthAdjSuggestions[i];

    final adj = baseAdj.copyWith(printWidthAdjustment: wAdj);

    final int imageWidth = BematechEscPos.imageWidthDots(adj);
    final String qrDebug = '$qrData|wAdj=$wAdj|w=$imageWidth|opt=${i + 1}';

    bytes += gen.text(
      'OPCION ${i + 1}: wAdj=$wAdj  widthDots=$imageWidth',
      styles: const PosStyles(bold: true),
    );

    final Uint8List headerBytes = await combineLogoAndQrCodeWithAlignment(
      logo: logoAssetPath,
      qrData: qrDebug,
      totalWidth: imageWidth,
      showBorderMarks: true,
    );

    final img.Image? headerImage = img.decodeImage(headerBytes);

    if (headerImage != null) {
      bytes += gen.image(headerImage);
      bytes += gen.feed(1);
    } else {
      bytes += gen.text('ERROR: no se pudo decodificar headerImage');
      bytes += gen.feed(1);
    }

    bytes += gen.hr();
  }

  bytes += gen.feed(2);
  bytes += gen.cut();

  final printer = PrinterNetworkManager(ip, port: port);
  final conn = await printer.connect();
  if (conn != PosPrintResult.success) return conn;

  final res = await printer.printTicket(bytes);
  await Future.delayed(const Duration(seconds: 1));
  printer.disconnect();
  return res;
}
/// Diagnóstico codepage: CP1252 vs CP858 vs CP850 vs UTF8(raw)
/// Imprime RAW para evitar el crash de gen.text() por €.

Future<PosPrintResult> printDiagCodepageTicket({
  required String ip,
  required int port,
  required String printerName,
  required PaperSize paperSize,
  required PosAdjustmentValues adj,
}) async {



  final profile = await CapabilityProfile.load();
  final gen = Generator(paperSize, profile);

  List<int> bytes = [];
  bytes += gen.reset();
  bytes += gen.text('DIAG CODEPAGE', styles: const PosStyles(align: PosAlign.center, bold: true));
  bytes += gen.text('Impresora: $printerName', styles: const PosStyles(align: PosAlign.center));
  bytes += gen.hr();
  addTextByMode(
    bytes: bytes,
    gen: gen,
    adj: adj, // PosAdjustmentValues actual
    text: 'Tip: elige el bloque SIN cuadritos y con € correcto.',
  );

  // Helper: imprime un bloque en modo RAW (n específico)
  void block(String title, int escTN, {required bool utf8Raw}) {
    bytes += gen.hr();
    addTextByMode(
      bytes: bytes,
      gen: gen,
      adj: adj,
      text: title,
      styles: const PosStyles(bold: true),
    );


    final lines = <String>[
      'Espanol: Nino, pinata, cancion',
      'Acentos: á é í ó ú ü ñ',
      'Portugues: Sao Joao, Acucar, Coracao',
      'Acentos: á â ã à é ê í ó ô õ ú ç',
      'Moneda: R\$ €  | Simbolos: º ª',
    ];

    for (final s in lines) {
      if (utf8Raw) {
        addRawUtf8Line(bytes, s);
      } else {
        // si escTN es 2 (CP850) sanitiza € -> EUR
        final safe = (escTN == 2) ? sanitizeForCp850(s) : sanitizeForCp858Or1252(s);
        addRawLatin1Line(bytes, safe, escTN: escTN);
      }
    }
  }

  block('OPCION 1: CP850 (ESC t 2)  [sin €]', 2, utf8Raw: false);
  block('OPCION 2: CP858 (ESC t 5)  [CP850 + €]', 5, utf8Raw: false);
  block('OPCION 3: CP1252-like (ESC t 16)', 16, utf8Raw: false);
  block('OPCION 4: UTF8 (ESC t 8) RAW', 8, utf8Raw: true);

  bytes += gen.feed(2);
  bytes += gen.cut();

  final printer = PrinterNetworkManager(ip, port: port);
  final conn = await printer.connect();
  if (conn != PosPrintResult.success) return conn;

  final res = await printer.printTicket(bytes);
  await Future.delayed(const Duration(seconds: 1));
  printer.disconnect();
  return res;
}


Future<PosPrintResult> printPaperSizeColsTestTicket({
  required String ip,
  required int port,
  required String printerName,
}) async {
  final profile = await CapabilityProfile.load();

  // Usamos mm80 solo como "canvas" para generar bytes; el ancho real lo decide la impresora/papel.
  final gen = Generator(PaperSize.mm80, profile);

  final colsList = <int>[32, 42, 48];

  List<int> bytes = [];
  bytes += gen.reset();

  // Títulos solo ASCII -> seguro
  bytes += gen.text('TEST PAPER (COLS)',
      styles: const PosStyles(align: PosAlign.center, bold: true));
  bytes += gen.text('Printer: $printerName',
      styles: const PosStyles(align: PosAlign.center));
  bytes += gen.text('Elige el bloque que NO se corta.',
      styles: const PosStyles(align: PosAlign.center));
  bytes += gen.hr();

  for (int i = 0; i < colsList.length; i++) {
    final cols = colsList[i];

    bytes += gen.text('OPCION ${i + 1}: COLS=$cols',
        styles: const PosStyles(bold: true));

    // marco izquierdo/derecho para ver corte
    final rule = '|${'-' * (cols - 2)}|';
    bytes += gen.text(rule);

    // línea con marcadores (1 y decenas) para ver el borde derecho
    bytes += gen.text(_markerLine(cols));

    // línea “relleno” hasta el borde derecho
    bytes += gen.text('|${'X' * (cols - 2)}|');

    bytes += gen.hr();
  }

  bytes += gen.text('Resultado esperado:',
      styles: const PosStyles(bold: true));
  bytes += gen.text('32 = 58mm, 42 = 72mm, 48 = 80mm');

  bytes += gen.feed(2);
  bytes += gen.cut();

  final printer = PrinterNetworkManager(ip, port: port);
  final conn = await printer.connect();
  if (conn != PosPrintResult.success) return conn;

  final res = await printer.printTicket(bytes);
  await Future.delayed(const Duration(milliseconds: 600));
  printer.disconnect();
  return res;
}




