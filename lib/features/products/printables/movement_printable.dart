import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:monalisapy_features/printer/printable/pdf_printable.dart';
import 'package:monalisapy_features/printer/printable/pos_receipt_printable.dart';
import 'package:monalisapy_features/printer/printable/tspl_printable.dart';
import 'package:monalisapy_features/printer/printable/zpl_printable.dart';

import '../../printer/movement_pdf_generator.dart';
import '../../printer/pos/print_receipt_with_qr_bematech.dart';
import '../../printer/zpl/old/zpl_label_printer_100x150.dart';
import '../domain/idempiere/movement_and_lines.dart';

/// Adapts a [MovementAndLines] entity to the package's printable contracts.
/// Movement supports the full matrix: PDF (CUPS / share), POS receipt
/// (Bematech ESC/POS), ZPL labels and TSPL labels.
class MovementPrintable
    implements PdfPrintable, PosReceiptPrintable, ZplPrintable, TsplPrintable {
  final MovementAndLines movementAndLines;

  MovementPrintable(this.movementAndLines);

  @override
  String get documentNo => movementAndLines.documentNo ?? 'document-mo';

  @override
  String get pdfFilename => 'documento.pdf';

  @override
  IconData get dataPanelIcon => Symbols.receipt_long;

  @override
  String get dataPanelTitle =>
      'Movement Doc No ${movementAndLines.documentNo ?? ''}';

  @override
  String get dataPanelSubtitle => 'Date: ${movementAndLines.movementDate ?? ''}';

  @override
  Future<Uint8List> generatePdfBytes({required Uint8List logoBytes}) {
    return generateMovementDocument(movementAndLines, logoBytes);
  }

  @override
  Future<void> printPosReceipt(WidgetRef ref) {
    return printMovementReceiptWithQr(ref, movementAndLines);
  }

  @override
  Future<void> printZpl(WidgetRef ref) {
    return printMovementZplDirectOrConfigure(ref, movementAndLines);
  }

  @override
  Future<void> printTspl(WidgetRef ref) {
    return printMovementTsplDirectOrConfigure(ref, movementAndLines);
  }
}
