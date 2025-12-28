import 'package:flutter/material.dart';

enum BarcodeViewSection { document, products, locations }

class DocumentQrItem {
  final String title;
  final String code;
  final String subtitle;


  const DocumentQrItem({
    required this.title,
    required this.code,
    required this.subtitle,

  });
}

class BarcodeItem {
  final String code;     // UPC/EAN/Code128 data
  final String title;    // titulo o sku
  final String subtitle;
  final double? line;       // numero de linea
  // nombre producto / etc

  const BarcodeItem({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.line,
  });
}

class LocatorQrItem {
  final String locator;
  final String warehouse;
  final Color backgroundColor;

  const LocatorQrItem({
    required this.locator,
    required this.warehouse,
    required this.backgroundColor,
  });
}
