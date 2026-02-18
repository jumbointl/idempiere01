import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/domain/models/label_profile.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../models/printer_select_models.dart';
import '../niimbot/niimbot_printer_helper.dart';
import 'label_printer_select_page.dart';

class ProductLabelPrinterSelectPage extends LabelPrinterSelectPage {
  const ProductLabelPrinterSelectPage({super.key, required super.dataToPrint});

  @override
  int get actionScanType => Memory.ACTION_FIND_PRINTER_BY_QR_WIFI_BLUETOOTH;

  @override
  String get pageTitle => 'Label Printer Select';

  @override
  String? validateDataToPrint() {
    final data = dataToPrint;
    if (data is! IdempiereProduct) {
      return 'dataToPrint must be IdempiereProduct.';
    }
    final upc = normalizeUpc(data.uPC ?? '');
    if (upc.isEmpty) return 'Product has empty UPC.';
    return null;
  }

  @override
  String buildTsplForData({
    required LabelProfile profile,
    required bool printSimpleData,
  }) {
    final data = dataToPrint as IdempiereProduct;

    final upc = normalizeUpc(data.uPC ?? '');
    final sku = (data.sKU ?? 'sku').trim();
    final name = (data.name ?? 'name').trim();

    if (printSimpleData) {
      return buildTsplProductLabelSimple(upc: upc, sku: sku, profile: profile);
    }
    return buildTsplProductLabel(upc: upc, sku: sku, name: name, profile: profile);
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
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: selectedPrinter == null
                ? null
                : () => onPrint(profile: profile40, printSimpleData: true),
            child: const Text('Print simple'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: selectedPrinter == null
                ? null
                : () => onPrint(profile: profile60, printSimpleData: false),
            child: const Text('Print complete'),
          ),
        ),
      ],
    );
  }
  Widget buildNiimbotProductWidget({
    required String name,
    required String sku,
    required String upc,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.black, fontSize: 22, height: 1.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text('SKU: $sku'),
            const SizedBox(height: 6),
            Text('UPC: $upc'),
            // Si querés barcode/QR REAL: lo metemos con `barcode_widget` o `qr_flutter`
          ],
        ),
      ),
    );
  }
  @override
  Future<bool> printDataToNiimbot({
    required BuildContext context,
    required PrinterConnConfig printer,
    required LabelProfile profile,
    required dynamic data,
  }) async {
    final mac = (printer.btAddress ?? '').trim();
    final upc = normalizeUpc(data.uPC ?? '');
    final sku = (data.sKU ?? '').trim();
    final name = (data.name ?? '').trim();

    final widgetToPrint = buildNiimbotProductWidget(name: name, sku: sku, upc: upc);
    final helper = NiimbotPrinterHelper();
    final ok = await helper.printLabelFromWidget(
      context: context,
      mac: mac,
      widthMm: profile.widthMm,
      heightMm: profile.heightMm,
      widget: widgetToPrint,
      // opcional: density/labelType por perfil si los agregás
    );

    return ok;
  }
}
