import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/printer/screen/riverpod_printer_adapter.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';
import 'package:riverpod_printer/riverpod_printer.dart';

import 'label_printer_select_page.dart';

class ProductLabelPrinterSelectPage extends LabelPrinterSelectPage {
  const ProductLabelPrinterSelectPage({
    super.key,
    required super.dataToPrint,
  });

  @override
  int get actionScanType => Memory.ACTION_FIND_PRINTER_BY_QR_WIFI_BLUETOOTH;

  int get minProfileProductCompleteWidth => 40;
  int get minProfileProductCompleteHeight => 30;
  int get minProfileProductSimpleWidth => 30;
  int get minProfileProductSimpleHeight => 20;

  @override
  String get pageTitle => 'Label Printer Select';

  @override
  String? validateDataToPrint() {
    final data = dataToPrint;
    if (data is! IdempiereProduct) {
      return 'dataToPrint must be IdempiereProduct.';
    }

    final String upc = normalizeUpc(data.uPC ?? '');
    if (upc.isEmpty) {
      return 'Product has empty UPC.';
    }

    return null;
  }

  @override
  Future<PrintResult> executePrintJob({
    required BuildContext context,
    required WidgetRef ref,
    required LabelProfile profile,
    required bool printSimpleData,
    required PrinterDevice selectedPrinter,
    required int copies,
  }) async {
    final IdempiereProduct product = dataToPrint as IdempiereProduct;

    final ProductLabelKind kind =
    printSimpleData ? ProductLabelKind.simple : ProductLabelKind.complete;

    final ProductLabelItem item = productToLabelItem(
      product,
      kind: kind,
    );

    final LabelProfile profileWithCopies = profile.copyWith(copies: copies);

    final PrintJob<ProductLabelItem> job = PrintJob<ProductLabelItem>(
      document: ProductLabelPrintable(
        documentTitle: 'Product Labels',
        items: <ProductLabelItem>[item],
      ),
      labelProfile: profileWithCopies,
      printer: selectedPrinter,
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
    required PrinterDevice? selectedPrinter,
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
            child: const Text('Print simple'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: selectedPrinter == null
                ? null
                : () => onPrint(
              profile: profile60,
              printSimpleData: false,
            ),
            child: const Text('Print complete'),
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
    if (printSimpleData) {
      if (profile.heightMm < minProfileProductSimpleHeight ||
          profile.widthMm < minProfileProductSimpleWidth) {
        return 'Profile size is too small. Minimum: ${minProfileProductSimpleWidth}x${minProfileProductSimpleHeight}mm';
      }
    } else {
      if (profile.heightMm < minProfileProductCompleteHeight ||
          profile.widthMm < minProfileProductCompleteWidth) {
        return 'Profile size is too small. Minimum: ${minProfileProductCompleteWidth}x${minProfileProductCompleteHeight}mm';
      }
    }

    return '';
  }
}