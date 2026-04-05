import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';


import 'package:riverpod_printer/riverpod_printer.dart';

final copiesTempProvider = StateProvider<int>((ref) => 1);

enum PrinterConnTypeOld { bluetooth, wifi }

class PrinterConnConfig {
  final String id; // stable id
  final PrinterConnTypeOld type;
  final String name;

  // WiFi
  final String? ip;
  final int? port;

  // Bluetooth
  final String? btAddress; // MAC or device address string
  final String? lang;     // TSPL (or TPL alias normalized to TSPL)
  final String? typeText; // Bluetooth: PRINTER_TYPE_BLUETOOTH_BLE / PRINTER_BLUETOOTH_NO_BLE

  const PrinterConnConfig({
    required this.id,
    required this.type,
    required this.name,
    this.ip,
    this.port,
    this.btAddress,
    this.lang,
    this.typeText,

  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'ip': ip,
    'port': port,
    'btAddress': btAddress,
    'lang': lang,
    'typeText': typeText,
  };

  factory PrinterConnConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConnConfig(
      id: json['id']?.toString() ?? '',
      type: (json['type']?.toString() == 'bluetooth')
          ? PrinterConnTypeOld.bluetooth
          : PrinterConnTypeOld.wifi,
      name: json['name']?.toString() ?? '',
      ip: json['ip']?.toString(),
      port: json['port'] is int ? json['port'] as int : int.tryParse('${json['port']}'),
      btAddress: json['btAddress']?.toString(),
      lang: json['lang']?.toString() ?? 'TPL',
      typeText: json['typeText']?.toString() ?? '',
    );
  }

  String get printerInformationName {

    switch (type) {
      case PrinterConnTypeOld.bluetooth:
        return name.isEmpty ? 'No name' : name;
      case PrinterConnTypeOld.wifi:
        return name.isEmpty ? '${ip ?? 'No ip'}:${port ?? 'No port'}' : name;
    }
  }

  String get printerInformationAddress {
    switch (type) {
      case PrinterConnTypeOld.bluetooth:
        return btAddress ?? '';
      case PrinterConnTypeOld.wifi:
        return '${ip ?? 'No ip'}:${port ?? 'No port'}';
    }


  }
  String getPrinterInfoQRString(){

    switch (type) {
      case PrinterConnTypeOld.bluetooth:
        return 'BLUETOOTH*${name.isEmpty ? 'No name' : name}*${btAddress ?? 'No address'}*${lang ?? 'No lang'}*${typeText ?? 'No type'}';
      case PrinterConnTypeOld.wifi:
        return '${ip ?? 'No ip'}:${port ?? 'No port'}:${lang ?? 'No lang'}';
    '}';
    }
  }
}



class PrinterSelectStorageKeys {
  static const String printersList = 'printer_select_printers_list_v1';
  static const String selectedPrinterId = 'printer_select_selected_printer_id_v1';
  static const String labelProfilesList = 'label_profiles_list_v1';
  static const String selectedLabelProfileId = 'label_profiles_selected_id_v1';
}
/// English: TSPL dots conversion for 203dpi printers
int mmToDots(double mm) => (mm * 8).round();

/*
/// English: Build TSPL command for product label (center barcode, 2mm margins)
String buildTsplProductLabel({
  required String upc,
  required String sku,
  required String name,
  required LabelProfile profile,
}) {
  const int dotsPerMm = 8;

  final wDots = (profile.widthMm * dotsPerMm).round();
  final hDots = (profile.heightMm * dotsPerMm).round();

  final mx = (profile.marginLeftMm * dotsPerMm).round();
  final my = (profile.marginTopMm * dotsPerMm).round();

  // Sanitize
  final safeName = name.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
  final safeSku = sku.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();

  // charactersToPrint: 0 = all
  final int charLimit = profile.charactersToPrint;
  final String nameToPrint =
  (charLimit <= 0 || safeName.length <= charLimit)
      ? safeName
      : safeName.substring(0, charLimit);

  // Barcode
  final normalized = normalizeUpc(upc);
  final sym = pickBarcodeType(normalized);

  final barcodeTypeStr = switch (sym) {
    BarcodeSymbology.ean13 => 'EAN13',
    BarcodeSymbology.ean8 => 'EAN8',
    BarcodeSymbology.code128 => '128',
  };

  // Module widths
  int narrow = profile.barcodeNarrow;
  int wide = profile.barcodeWide;
  if (sym == BarcodeSymbology.code128 && normalized.length >= 15) {
    narrow = narrow>1 ? narrow-1 : 1;
    wide = wide>1 ? wide-1 :1;
  }

  // Helpers
  String clip(String s, int maxChars) =>
      (s.length <= maxChars) ? s : s.substring(0, maxChars);

  /// Split the text into 2 lines trying to avoid cutting words.
  /// Rules:
  /// - target cut at `maxPerLine`
  /// - if there's a space at maxPerLine, cut at maxPerLine.
  /// - else search backward for a space up to -5 chars
  /// - else cut exactly at maxPerLine-1 and add _ to the first line
  (String, String) split2LinesSmart(String text, int maxPerLine) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return ('', '');

    if (t.length <= maxPerLine) return (t, '');

    int cut;

    // Case 1: exact position is space
    if (maxPerLine < t.length && t[maxPerLine] == ' ') {
      cut = maxPerLine;
    } else {
      int? backCut;

      // Search backward up to 5 positions
      for (int delta = 1; delta <= 5; delta++) {
        final idx = maxPerLine - delta;
        if (idx > 0 && idx < t.length && t[idx] == ' ') {
          backCut = idx;
          break;
        }
      }

      if (backCut != null) {
        cut = backCut;
      } else {
        // Force cut and mark continuation
        cut = maxPerLine - 1;
        final l1 = '${t.substring(0, cut).trim()}_';
        final rest = t.substring(cut).trim();
        final l2 = clip(rest, maxPerLine).trim();
        return (l1, l2);
      }
    }

    final l1 = t.substring(0, cut).trim();
    final rest = t.substring(cut).trim();
    final l2 = clip(rest, maxPerLine).trim();

    return (l1, l2);
  }


  // NAME in 2 lines with smart split based on label width
  //const double maxPerLineXMm = 0.55;
  //int maxPerLine = (maxPerLineXMm * (profile.widthMm - profile.marginLeftMm)).floor();
  int maxPerLine = profile.maxCharsPerLine;

  if (maxPerLine < profile.maxCharsPerLine) {
    maxPerLine = profile.maxCharsPerLine;
  }

  final limitedName = clip(nameToPrint, maxPerLine * 2);
  final (line1, line2) = split2LinesSmart(limitedName, maxPerLine);

  // SKU after name (1 line)
  final skuLine = safeSku.isEmpty ? '' : 'SKU: ${clip(safeSku, 28)}';

  // --- Layout (3 lines top) ---
  final int lineH = 24;
  final int gap = profile.gapMm;

  // Barcode height (larger)3;

  final int yName1 = my;
  final int yName2 = yName1 + lineH + gap;
  final int ySku = yName2 + lineH + gap;

  // Barcode height (smaller)
  //final int maxBarcodeH = (profile.barcodeHeightMm * dotsPerMm).round();
  final int barcodeH = profile.barcodeHeight; // (maxBarcodeH - 30).clamp(35, 110);

  // Barcode Y below text
  final int minBarcodeY = ySku + lineH + 6;
  final int yBarcode = minBarcodeY.clamp(my + 30, hDots - barcodeH - 10);

  // Center barcode (rough estimation)
  final approxBarcodeWidth = (sym == BarcodeSymbology.code128)
      ? (normalized.length * (narrow * 6) + 60)
      : (wDots * 70 ~/ 100);

  final xBarcode =
  ((wDots - approxBarcodeWidth) / 2).round().clamp(mx, wDots - mx);

  final sb = StringBuffer();
  sb.writeln('SIZE ${profile.widthMm} mm,${profile.heightMm} mm');
  sb.writeln('GAP $gap mm,0 mm');
  sb.writeln('DENSITY 8');
  sb.writeln('SPEED 4');
  sb.writeln('DIRECTION 1');
  sb.writeln('REFERENCE 0,0');
  sb.writeln('CLS');

  if (line1.isNotEmpty) {
    sb.writeln('TEXT $mx,$yName1,"${profile.fontId}",0,1,1,"$line1"');
  }
  debugPrint('line1: ${line1.length}');
  if (line2.isNotEmpty) {
    sb.writeln('TEXT $mx,$yName2,"${profile.fontId}",0,1,1,"$line2"');
  }

  if (skuLine.isNotEmpty) {
    sb.writeln('TEXT $mx,$ySku,"${profile.fontId}",0,1,1,"$skuLine"');
  }

  sb.writeln(
    'BARCODE $xBarcode,$yBarcode,"$barcodeTypeStr",$barcodeH,1,0,$narrow,$wide,"$normalized"',
  );

  sb.writeln('PRINT 1,${profile.copies}');
  debugPrint(sb.toString());
  return sb.toString();
}

String buildTsplProductLabelSimple({
  required String upc,
  required String sku,
  required LabelProfile profile,
}) {
  const int dotsPerMm = 8;

  final wDots = (profile.widthMm * dotsPerMm).round();
  final hDots = (profile.heightMm * dotsPerMm).round();

  final mx = (profile.marginLeftMm * dotsPerMm).round();
  final my = (profile.marginTopMm * dotsPerMm).round();

  // Sanitize
  final safeSku = sku.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();

  // Barcode
  final normalized = normalizeUpc(upc);
  final sym = pickBarcodeType(normalized);

  final barcodeTypeStr = switch (sym) {
    BarcodeSymbology.ean13 => 'EAN13',
    BarcodeSymbology.ean8 => 'EAN8',
    BarcodeSymbology.code128 => '128',
  };

  // Module widths
  int narrow = profile.barcodeNarrow;
  int wide = profile.barcodeWide;
  if (sym == BarcodeSymbology.code128 && normalized.length >= 15) {
    narrow = profile.barcodeNarrow > 1 ? profile.barcodeNarrow - 1 : 1;
    wide = profile.barcodeWide > 1 ? profile.barcodeWide - 1 : 1;
  }

  // Helpers
  String clip(String s, int maxChars) =>
      (s.length <= maxChars) ? s : s.substring(0, maxChars);

  // Only one text line: SKU (kept short)
  final skuLine = safeSku.isEmpty ? '' : 'SKU: ${clip(safeSku, 28)}';

  // Layout
  final int lineH = 24;
  final int gapMm = profile.gapMm;
  final int gapDots = (gapMm * dotsPerMm).round();

  final int barcodeH = profile.barcodeHeight;

  // Center barcode (rough estimation)
  final approxBarcodeWidth = (sym == BarcodeSymbology.code128)
      ? (normalized.length * (narrow * 6) + 60)
      : (wDots * 70 ~/ 100);

  final xBarcode =
  ((wDots - approxBarcodeWidth) / 2).round().clamp(mx, wDots - mx);

  final int ySku = my;
  final int yBarcodeDesired = ySku + lineH + gapDots + 10;

  // Clamp barcode so it fits inside label
  final int yBarcodeMax = hDots - barcodeH - my;
  final int yBarcode = yBarcodeDesired.clamp(my, yBarcodeMax);

  final sb = StringBuffer();
  sb.writeln('SIZE ${profile.widthMm} mm,${profile.heightMm} mm');
  sb.writeln('GAP ${profile.gapMm} mm,0 mm');
  sb.writeln('DENSITY 8');
  sb.writeln('SPEED 4');
  sb.writeln('DIRECTION 1');
  sb.writeln('REFERENCE 0,0');
  sb.writeln('CLS');

  if (skuLine.isNotEmpty) {
    sb.writeln('TEXT $mx,$ySku,"${profile.fontId}",0,1,1,"$skuLine"');
  }

  sb.writeln(
    'BARCODE $xBarcode,$yBarcode,"$barcodeTypeStr",$barcodeH,1,0,$narrow,$wide,"$normalized"',
  );

  sb.writeln('PRINT 1,${profile.copies}');
  debugPrint(sb.toString());
  return sb.toString();
}
*/



/// English: Get default profiles
LabelProfile defaultLabel30x20() => const LabelProfile(
  id: 'default_30x20',
  name: 'Default 30x20',
  copies: 1,
  widthMm: 30,
  heightMm: 20,
  marginLeftMm: 2,
  marginTopMm: 2,
  barcodeHeightMm: 12,
  charactersToPrint: 0,
  maxCharsPerLine:  16,
  barcodeHeight: 50,
  barcodeNarrow: 2,
  barcodeWide: 3,
  fontId: 1,
  gapMm: 3,



);
LabelProfile defaultLabel40x15() => const LabelProfile(
  id: 'default_40x15',
  name: 'Default 40x15',
  copies: 1,
  widthMm: 40,
  heightMm: 15,
  marginLeftMm: 2,
  marginTopMm: 2,
  barcodeHeightMm: 12,
  charactersToPrint: 0,
  maxCharsPerLine:  18,
  barcodeHeight: 50,
  barcodeNarrow: 2,
  barcodeWide: 3,
  fontId: 1,
  gapMm: 3,



);

LabelProfile defaultLabel40x25() => const LabelProfile(
  id: 'default_40x25',
  name: 'Default 40x25',
  copies: 1,
  widthMm: 40,
  heightMm: 25,
  marginLeftMm: 2,
  marginTopMm: 2,
  barcodeHeightMm: 12,
  charactersToPrint: 0,
  maxCharsPerLine:  22,
  barcodeHeight: 50,
  barcodeNarrow: 2,
  barcodeWide: 3,
  fontId: 1,
  gapMm: 2,



);

LabelProfile defaultLabel60x40() => const LabelProfile(
  id: 'default_60x40',
  name: 'Default 60x40',
  copies: 1,
  widthMm: 60,
  heightMm: 40,
  marginLeftMm: 2,
  marginTopMm: 2,
  barcodeHeightMm: 18,
  charactersToPrint: 0,
  maxCharsPerLine: 35,
  barcodeHeight: 50,
  barcodeWide: 3,
  barcodeNarrow: 2,
  fontId: 1,
  gapMm: 3,

);
LabelProfile defaultLabel50x30() => const LabelProfile(
  id: 'default_50x30',
  name: 'Default 50x30',
  copies: 1,
  widthMm: 50,
  heightMm: 30,
  marginLeftMm: 2,
  marginTopMm: 2,
  barcodeHeightMm: 18,
  charactersToPrint: 0,
  maxCharsPerLine: 26,
  barcodeHeight: 50,
  barcodeWide: 3,
  barcodeNarrow: 2,
  fontId: 2,
  gapMm: 3,

);

String encodeListJson(List<Map<String, dynamic>> items) => jsonEncode(items);
List<Map<String, dynamic>> decodeListJson(String raw) {
  final v = jsonDecode(raw);
  if (v is List) return v.cast<Map<String, dynamic>>();
  return <Map<String, dynamic>>[];
}
