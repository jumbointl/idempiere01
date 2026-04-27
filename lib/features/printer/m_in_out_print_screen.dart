import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/printer/printer_scan_notifier.dart';
import 'package:monalisa_app_001/features/printer/printer_setup_screen.dart';
import 'package:printing/printing.dart';

import '../../config/theme/app_theme.dart';
import '../m_inout/domain/entities/m_in_out.dart';
import '../products/common/messages_dialog.dart';
import '../products/common/widget_utils.dart';
import '../products/presentation/providers/common_provider.dart';
import '../products/presentation/providers/product_provider_common.dart';
import '../shared/data/messages.dart';
import 'cups_printer.dart';
import 'm_in_out_pdf_generator.dart';

class MInOutPrintScreen extends PrinterSetupScreen {
  MInOutPrintScreen({super.key, super.dataToPrint, required super.oldAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return printerSetupScreenBody(context, ref, dataToPrint: dataToPrint);
  }

  @override
  Future<void> printPdf(WidgetRef ref, BuildContext context,
      {required bool direct}) async {
    final mInOut = dataToPrint as MInOut;
    final image = await imageLogo;
    final pdfBytes = await generateMInOutDocument(mInOut, image);
    direct
        ? ref
            .read(printerScanNotifierProvider.notifier)
            .printDirectly(bytes: pdfBytes, ref: ref)
        : await Printing.sharePdf(bytes: pdfBytes, filename: 'documento.pdf');
  }

  @override
  Widget getPrintPanel(WidgetRef ref, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: compactElevatedButton(
            label: Messages.SHARE,
            backgroundColor: themeColorPrimary,
            onPressed: () async {
              await printPdf(ref, context, direct: false);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: compactElevatedButton(
            label: Messages.PRINT,
            backgroundColor: (ref.read(lastPrinterProvider.notifier).state !=
                    null
                ? Colors.green
                : themeColorPrimary),
            onPressed: () async {
              printFromCurrentSetup(ref, context, dataToPrint);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: compactElevatedButton(
            label: 'PREVIEW',
            backgroundColor: themeColorPrimary,
            onPressed: () async {
              // ZPL preview is not implemented for MInOut yet.
              showWarningCenterToast(context, Messages.NOT_IMPLEMENTED_YET);
            },
          ),
        ),
      ],
    );
  }
}
