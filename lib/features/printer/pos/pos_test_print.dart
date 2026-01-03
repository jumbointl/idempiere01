// pos_test_print.dart
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:image/image.dart' as img;
import 'package:monalisa_app_001/features/printer/pos/pos_logo_and_qr_with_aligment.dart';
import 'bematech_escpos.dart';
import 'pos_adjustment_values.dart';

class PosWidthCandidate {
  final int dots; // 576 / 552 / 528
  final String label;
  final int suggestedCharsAdj; // 0 / -2 / -4
  const PosWidthCandidate(this.dots, this.label, this.suggestedCharsAdj);
}

const candidates80mm = <PosWidthCandidate>[
  PosWidthCandidate(576, '80mm (576 dots)', 0),
  PosWidthCandidate(552, '76mm (552 dots)', -2),
  PosWidthCandidate(528, '73.5mm (528 dots)', -4),
];

const widthAdjSuggestions = <int>[0, -8, -16];

Future<PosPrintResult> printWidthTestTicket({
  required String ip,
  required int port,
  required String printerName,
}) async {
  final profile = await CapabilityProfile.load();
  final gen = Generator(PaperSize.mm80, profile);

  List<int> bytes = [];
  bytes += gen.reset();
  bytes += gen.text(
    'TEST ANCHO POS',
    styles: const PosStyles(align: PosAlign.center, bold: true),
  );
  bytes += gen.text(
    'Impresora: $printerName',
    styles: const PosStyles(align: PosAlign.center),
  );
  bytes += gen.hr();
  bytes += gen.text('Elige la opcion que NO se corta y llega al borde.');

  const candidates80mm = <_PosWidthCandidate>[
    _PosWidthCandidate(576, '80mm (576 dots)', 0),
    _PosWidthCandidate(552, '76mm (552 dots)', -2),
    _PosWidthCandidate(528, '73.5mm (528 dots)', -4),
  ];

  const cols = [48, 46, 44];

  for (int i = 0; i < candidates80mm.length; i++) {
    final c = candidates80mm[i];
    final nCols = cols[i];

    bytes += gen.text('OPCION ${i + 1}: ${c.label}', styles: const PosStyles(bold: true));
    final rule = '|' + ('-' * (nCols - 2)) + '|';
    bytes += gen.text(rule);
    bytes += gen.text(_markerLine(nCols));
    bytes += gen.text('Cols=$nCols  sugerido charsAdj=${c.suggestedCharsAdj}');
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

/// ✅ TEST REAL para tu caso (header imagen):
/// Imprime 3 headers (logo + QR) variando baseAdj.printWidthAdjustment.
///
/// Vas a elegir el que:
/// - NO corta la línea derecha
/// - y el QR no se recorta
Future<PosPrintResult> printWidthAdjustmentHeaderTestTicket({
  required String ip,
  required int port,
  required String printerName,
  required PosAdjustmentValues baseAdj,
  required String logoAssetPath, // ej: 'assets/images/monalisa_logo_movement.jpg'
  required String qrData,
}) async {
  final profile = await CapabilityProfile.load();
  final gen = Generator(PaperSize.mm80, profile);

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
    'Ajustando: printWidthAdjustment (dots)',
    styles: const PosStyles(align: PosAlign.center),
  );
  bytes += gen.hr();
  bytes += gen.text('Elige la opcion donde NO se corta el borde derecho.');

  for (int i = 0; i < widthAdjSuggestions.length; i++) {
    final wAdj = widthAdjSuggestions[i];

    final adj = baseAdj.copyWith(printWidthAdjustment: wAdj);

    // Tu ancho real en dots, con ajuste aplicado
    final int imageWidth = BematechEscPos.imageWidthDots(adj);

    // Debug dentro del QR, así también queda trazabilidad al escanear
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

Future<PosPrintResult> printCharsetTestTicket({
  required String ip,
  required int port,
}) async {
  final profile = await CapabilityProfile.load();
  final gen = Generator(PaperSize.mm80, profile);

  List<int> bytes = [];
  bytes += gen.reset();
  bytes += gen.text('TEST CHARSET', styles: const PosStyles(align: PosAlign.center, bold: true));
  bytes += gen.text('Elige el bloque que se vea CORRECTO');
  bytes += gen.hr();

  bytes += _charsetBlock(gen, title: 'CP850 (recomendado Bematech)', set: PosCharSet.cp850);
  bytes += gen.hr();
  bytes += _charsetBlock(gen, title: 'CP1252', set: PosCharSet.cp1252);

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

List<int> _charsetBlock(Generator gen, {required String title, required PosCharSet set}) {
  final b = <int>[];

  // Bematech suele obedecer mejor ESC t n que setGlobalCodeTable
  if (set == PosCharSet.cp850) {
    b.addAll([0x1B, 0x74, 0x02]); // ESC t 2
  } else {
    b.addAll(gen.setGlobalCodeTable('CP1252'));
  }

  b.addAll(gen.text('BLOQUE $title', styles: const PosStyles(bold: true)));
  b.addAll(gen.text('Espanol: Niño, piñata, canción'));
  b.addAll(gen.text('Acentos: á é í ó ú ü ñ'));
  b.addAll(gen.text('Português: São João, Açúcar, Coração'));
  b.addAll(gen.text('Acentos: á â ã à é ê í ó ô õ ú ç'));
  b.addAll(gen.text(r'Simbolos: R$  $  %  &  #  @  ( )  -  /  +  :  ;'));
  b.addAll(gen.text('Especiales: º  ª  ç  Ç  ñ  Ñ'));

  return b;
}

String _markerLine(int nCols) {
  final buf = StringBuffer();
  for (int i = 1; i <= nCols; i++) {
    if (i == 1) {
      buf.write('1');
    } else if (i % 10 == 0) {
      buf.write((i ~/ 10) % 10);
    } else {
      buf.write('.');
    }
  }
  return buf.toString();
}



class _PosWidthCandidate {
  final int dots;
  final String label;
  final int suggestedCharsAdj;
  const _PosWidthCandidate(this.dots, this.label, this.suggestedCharsAdj);
}