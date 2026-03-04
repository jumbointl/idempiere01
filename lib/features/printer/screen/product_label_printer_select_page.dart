import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/domain/models/label_profile.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../models/printer_select_models.dart';
import 'label_printer_select_page.dart';

class ProductLabelPrinterSelectPage extends LabelPrinterSelectPage {

  const ProductLabelPrinterSelectPage({super.key, required super.dataToPrint});

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

  @override
  String checkLabelSize(WidgetRef ref, LabelProfile profile, {required bool printSimpleData})  {
    if(printSimpleData){
      if(profile.heightMm<minProfileProductSimpleHeight || profile.widthMm<minProfileProductSimpleWidth){
        String msg = 'Profile, Profile size is too small. Minimum: ${minProfileProductSimpleWidth}x${minProfileProductSimpleHeight}mm';
        return msg ;
      }
    } else {
      if(profile.heightMm<minProfileProductCompleteHeight || profile.widthMm<minProfileProductCompleteWidth){
        String msg =  'Profile, Profile size is too small. Minimum: ${minProfileProductCompleteWidth}x${minProfileProductCompleteHeight}mm';
        return msg ;

      }
    }
    return '';
  }
}
