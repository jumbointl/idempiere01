import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:riverpod_printer/riverpod_printer.dart';

import 'package:monalisapy_features/printer/models/printer_select_models.dart';

ProductLabelItem productToLabelItem(
    IdempiereProduct product, {
      required ProductLabelKind kind,
    }) {
  final String upc = normalizeUpc(product.uPC ?? '');
  final String sku = (product.sKU ?? '').trim();
  final String name = (product.name ?? '').trim();

  switch (kind) {
    case ProductLabelKind.simple:
      return ProductLabelItem(
        kind: ProductLabelKind.simple,
        title: sku.isNotEmpty ? sku : 'SKU',
        barcode: upc,
        sku: sku,
      );

    case ProductLabelKind.complete:
      return ProductLabelItem(
        kind: ProductLabelKind.complete,
        title: name.isNotEmpty ? name : 'NAME',
        subtitle: sku,
        barcode: upc,
        sku: sku,
      );
  }
}



PrinterDevice printerDeviceFromConnConfig(PrinterConnConfig printer) {
  if (printer.type == PrinterConnType.wifi) {
    return SocketPrinterDevice(
      id: printer.id,
      name: printer.name,
      type: PrinterType.label,
      language: PrinterLanguage.tspl,
      host: printer.ip ?? '',
      port: printer.port ?? 9100,
    );
  }

  return BluetoothPrinterDevice(
    id: printer.id,
    name: printer.name,
    type: PrinterType.label,
    language: PrinterLanguage.tspl,
    address: printer.btAddress ?? '',
  );
}

LocatorLabelItem locatorToLabelItem(
    String value, {
      required LocatorLabelKind kind,
    }) {
  return LocatorLabelItem(
    kind: kind,
    value: value.trim(),
  );
}