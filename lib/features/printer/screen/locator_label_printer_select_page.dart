import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/printer/screen/riverpod_printer_adapter.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';
import 'package:riverpod_printer/riverpod_printer.dart';

import '../../products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisapy_features/printer/models/printer_select_models.dart';
import 'label_printer_select_page.dart';

class LocatorLabelPrinterSelectPage extends LabelPrinterSelectPage {
  const LocatorLabelPrinterSelectPage({
    super.key,
    required super.dataToPrint,
  });

  int get minProfileWidth => 40;
  int get minProfileHeight => 30;

  @override
  int get actionScanType => Memory.ACTION_FIND_PRINTER_BY_QR_WIFI_BLUETOOTH;

  @override
  String get pageTitle => 'Locator Label Printer';

  @override
  String? validateDataToPrint() {
    final data = dataToPrint;
    if (data is! IdempiereLocator) {
      return 'dataToPrint must be IdempiereLocator.';
    }

    final String value = (data.value ?? '').trim();
    if (value.isEmpty) {
      return 'Locator value is empty.';
    }

    return null;
  }

  @override
  Future<PrintResult> executePrintJob({
    required BuildContext context,
    required WidgetRef ref,
    required LabelProfile profile,
    required bool printSimpleData,
    required PrinterConnConfig selectedPrinter,
    required int copies,
  }) async {
    final IdempiereLocator locator = dataToPrint as IdempiereLocator;
    final String value = (locator.value ?? '').trim();

    final LocatorLabelKind kind =
    printSimpleData ? LocatorLabelKind.barcode : LocatorLabelKind.qr;

    final LocatorLabelItem item = LocatorLabelItem(
      kind: kind,
      value: value,
    );

    final LabelProfile profileWithCopies = profile.copyWith(copies: copies);

    final PrintJob<LocatorLabelItem> job = PrintJob<LocatorLabelItem>(
      document: LocatorLabelPrintable(
        documentTitle: 'Locator Labels',
        items: <LocatorLabelItem>[item],
      ),
      labelProfile: profileWithCopies,
      printer: printerDeviceFromConnConfig(selectedPrinter),
      printerType: PrinterType.label,
      printerLanguage: PrinterLanguage.tspl,
    );

    final PrintExecutor executor = ref.read(printExecutorProvider);
    return executor.execute(job);
  }

  @override
  Widget buildPrintingPanel({
    required BuildContext context,
    required WidgetRef ref,
    required PrinterConnConfig? selectedPrinter,
    required LabelProfile profile40,
    required LabelProfile profile60,
    required Future<void> Function({
    required LabelProfile profile,
    required bool printSimpleData,
    }) onPrint,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: ElevatedButton(
            onPressed: selectedPrinter == null
                ? null
                : () => onPrint(
              profile: profile40,
              printSimpleData: true,
            ),
            child: const Text('Locator barcode'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: selectedPrinter == null
                ? null
                : () => onPrint(
              profile: profile40,
              printSimpleData: false,
            ),
            child: const Text('Locator QR'),
          ),
        ),
      ],
    );
  }

  @override
  String checkLabelSize(
      WidgetRef ref,
      LabelProfile profile, {
        required bool printSimpleData,
      }) {
    if (profile.heightMm < minProfileHeight ||
        profile.widthMm < minProfileWidth) {
      return 'Profile size is too small. Minimum: ${minProfileWidth}x${minProfileHeight}mm';
    }

    return '';
  }
}