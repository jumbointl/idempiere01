import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:monalisapy_features/printer/printable/pdf_printable.dart';
import 'package:monalisapy_features/printer/printable/pos_receipt_printable.dart';

import '../../printer/m_in_out_pdf_generator.dart';
import '../../printer/pos/print_receipt_with_qr_bematech.dart';
import '../../shared/data/messages.dart';
import '../domain/entities/m_in_out.dart';

/// Adapts an [MInOut] entity to the package's printable contracts so the
/// printer screen and dispatcher do not need to know about MInOut directly.
class MInOutPrintable implements PdfPrintable, PosReceiptPrintable {
  final MInOut mInOut;

  MInOutPrintable(this.mInOut);

  @override
  String get documentNo => mInOut.documentNo ?? 'document-mio';

  @override
  String get pdfFilename => 'documento.pdf';

  @override
  IconData get dataPanelIcon => Symbols.receipt_long;

  @override
  String get dataPanelTitle {
    final type = (mInOut.isSoTrx == true) ? 'Shipment' : 'Receipt';
    final docKind = mInOut.cDocTypeId?.identifier ?? type;
    return '$docKind Doc No ${mInOut.documentNo ?? ''}';
  }

  @override
  String get dataPanelSubtitle {
    final date = mInOut.movementDate != null
        ? mInOut.movementDate!.toIso8601String().substring(0, 10)
        : '';
    return '${Messages.DATE}: $date';
  }

  @override
  Future<Uint8List> generatePdfBytes({required Uint8List logoBytes}) {
    return generateMInOutDocument(mInOut, logoBytes);
  }

  @override
  Future<void> printPosReceipt(WidgetRef ref) {
    return printMInOutReceiptWithQr(ref, mInOut);
  }
}
