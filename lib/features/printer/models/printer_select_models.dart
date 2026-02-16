import 'dart:convert';

import 'package:flutter/material.dart';

enum PrinterConnType { bluetooth, wifi }

class PrinterConnConfig {
  final String id; // stable id
  final PrinterConnType type;
  final String name;

  // WiFi
  final String? ip;
  final int? port;

  // Bluetooth
  final String? btAddress; // MAC or device address string

  const PrinterConnConfig({
    required this.id,
    required this.type,
    required this.name,
    this.ip,
    this.port,
    this.btAddress,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'ip': ip,
    'port': port,
    'btAddress': btAddress,
  };

  factory PrinterConnConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConnConfig(
      id: json['id']?.toString() ?? '',
      type: (json['type']?.toString() == 'bluetooth')
          ? PrinterConnType.bluetooth
          : PrinterConnType.wifi,
      name: json['name']?.toString() ?? '',
      ip: json['ip']?.toString(),
      port: json['port'] is int ? json['port'] as int : int.tryParse('${json['port']}'),
      btAddress: json['btAddress']?.toString(),
    );
  }
}

class LabelProfile {
  final String id;
  final String name;
  final int copies;

  final double widthMm;
  final double heightMm;
  final double marginXmm;
  final double marginYmm;
  final int maxCharsPerLine;

  final int barcodeHeightMm;
  final int charactersToPrint; // 0 = full name
  final int barcodeHeight;
  final int barcodeWidth;
  final int barcodeNarrow;
  final int fontId;
  final int gapMm;



  const LabelProfile({
    required this.id,
    required this.name,
    required this.copies,
    required this.widthMm,
    required this.heightMm,
    required this.marginXmm,
    required this.marginYmm,
    required this.barcodeHeightMm,
    required this.charactersToPrint,
    required this.maxCharsPerLine,
    required this.barcodeHeight,
    required this.barcodeWidth,
    required this.barcodeNarrow,
    required this.fontId,
    required this.gapMm,


  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'copies': copies,
    'widthMm': widthMm,
    'heightMm': heightMm,
    'marginXmm': marginXmm,
    'marginYmm': marginYmm,
    'barcodeHeightMm': barcodeHeightMm,
    'charactersToPrint': charactersToPrint,
    'maxCharsPerLine': maxCharsPerLine,
    'barcodeHeight': barcodeHeight,
    'barcodeWidth': barcodeWidth,
    'fontId': fontId,
    'barcodeNarrow': barcodeNarrow,
    'gapMm' : gapMm,

  };

  factory LabelProfile.fromJson(Map<String, dynamic> json) {
    return LabelProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      copies: (json['copies'] is int) ? json['copies'] as int : int.tryParse('${json['copies']}') ?? 1,
      widthMm: (json['widthMm'] is num) ? (json['widthMm'] as num).toDouble() : double.tryParse('${json['widthMm']}') ?? 40,
      heightMm: (json['heightMm'] is num) ? (json['heightMm'] as num).toDouble() : double.tryParse('${json['heightMm']}') ?? 25,
      marginXmm: (json['marginXmm'] is num) ? (json['marginXmm'] as num).toDouble() : double.tryParse('${json['marginXmm']}') ?? 2,
      marginYmm: (json['marginYmm'] is num) ? (json['marginYmm'] as num).toDouble() : double.tryParse('${json['marginYmm']}') ?? 2,
      barcodeHeightMm: (json['barcodeHeightMm'] is int)
          ? json['barcodeHeightMm'] as int
          : int.tryParse('${json['barcodeHeightMm']}') ?? 12,
      charactersToPrint: (json['charactersToPrint'] is int)
          ? json['charactersToPrint'] as int
          : int.tryParse('${json['charactersToPrint']}') ?? 0,
      maxCharsPerLine: json['maxCharsPerLine'] ?? 22,
      barcodeHeight: json['barcodeHeight'] ?? 96,
      barcodeWidth: json['barcodeWidth'] ?? 3,
      barcodeNarrow: json['barcodeNarrow'] ?? 2,
      fontId: json['fontId'] ?? 2,
      gapMm: json['gapMm'] ?? 2,

    );
  }

}

class PrinterSelectStorageKeys {
  static const String printersList = 'printer_select_printers_list_v1';
  static const String selectedPrinterId = 'printer_select_selected_printer_id_v1';
  static const String labelProfilesList = 'label_profiles_list_v1';
  static const String selectedLabelProfileId = 'label_profiles_selected_id_v1';
}

/// English: Basic string normalize for barcode
String normalizeUpc(String v) => v.trim().replaceAll(RegExp(r'\s+'), '');

bool isAllDigits(String s) => RegExp(r'^\d+$').hasMatch(s);

bool isValidEAN13(String s) {
  if (s.length != 13 || !isAllDigits(s)) return false;
  int sum = 0;
  for (int i = 0; i < 12; i++) {
    final d = int.parse(s[i]);
    sum += (i % 2 == 0) ? d : (d * 3);
  }
  final check = (10 - (sum % 10)) % 10;
  return check == int.parse(s[12]);
}

bool isValidEAN8(String s) {
  if (s.length != 8 || !isAllDigits(s)) return false;
  int sum = 0;
  for (int i = 0; i < 7; i++) {
    final d = int.parse(s[i]);
    sum += (i % 2 == 0) ? (d * 3) : d;
  }
  final check = (10 - (sum % 10)) % 10;
  return check == int.parse(s[7]);
}

enum BarcodeSymbology { ean13, ean8, code128 }

BarcodeSymbology pickBarcodeType(String upc) {
  final v = normalizeUpc(upc);
  if (isValidEAN13(v)) return BarcodeSymbology.ean13;
  if (isValidEAN8(v)) return BarcodeSymbology.ean8;
  return BarcodeSymbology.code128;
}

/// English: TSPL dots conversion for 203dpi printers
int mmToDots(double mm) => (mm * 8).round();

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

  final mx = (profile.marginXmm * dotsPerMm).round();
  final my = (profile.marginYmm * dotsPerMm).round();

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
  int wide = profile.barcodeWidth;
  if (sym == BarcodeSymbology.code128 && normalized.length >= 15) {
    narrow = narrow-1;
    wide = wide-1;
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
  //int maxPerLine = (maxPerLineXMm * (profile.widthMm - profile.marginXmm)).floor();
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

String buildTsplProductLabelSmall({
  required String upc,
  required String sku,
  required LabelProfile profile,
}) {
  const int dotsPerMm = 8;

  final wDots = (profile.widthMm * dotsPerMm).round();
  final hDots = (profile.heightMm * dotsPerMm).round();

  final mx = (profile.marginXmm * dotsPerMm).round();
  final my = (profile.marginYmm * dotsPerMm).round();

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
  int narrow = 2;
  int wide = 2;
  if (sym == BarcodeSymbology.code128 && normalized.length >= 15) {
    narrow = 1;
    wide = 2;
  }

  // Helpers
  String clip(String s, int maxChars) =>
      (s.length <= maxChars) ? s : s.substring(0, maxChars);

  // Only one text line: SKU (kept short)
  final skuLine = safeSku.isEmpty ? '' : 'SKU: ${clip(safeSku, 28)}';

  // Layout
  final int lineH = 24;
  final int gap = profile.gapMm;

  // Put barcode near top, SKU below (or swap if you prefer)
  // We'll do barcode first (centered), then SKU at bottom.
  final int maxBarcodeH = (profile.barcodeHeightMm * dotsPerMm).round();
  final int barcodeH = (maxBarcodeH - 30).clamp(30, 90);

  // Center barcode (rough estimation)
  final approxBarcodeWidth = (sym == BarcodeSymbology.code128)
      ? (normalized.length * (narrow * 6) + 60)
      : (wDots * 70 ~/ 100);

  final xBarcode =
  ((wDots - approxBarcodeWidth) / 2).round().clamp(mx, wDots - mx);

  // y positions
  final int yBarcode = my.clamp(my, (hDots - barcodeH - (lineH + gap + 8)));
  final int ySku = (yBarcode + barcodeH + gap + 30).clamp(my, hDots - lineH - 6);

  final sb = StringBuffer();
  sb.writeln('SIZE ${profile.widthMm} mm,${profile.heightMm} mm');
  sb.writeln('GAP $gap mm,0 mm');
  sb.writeln('DENSITY 8');
  sb.writeln('SPEED 4');
  sb.writeln('DIRECTION 1');
  sb.writeln('REFERENCE 0,0');
  sb.writeln('CLS');

  // Barcode (human readable = 1)
  sb.writeln(
    'BARCODE $xBarcode,$yBarcode,"$barcodeTypeStr",$barcodeH,1,0,$narrow,$wide,"$normalized"',
  );

  // SKU below barcode
  if (skuLine.isNotEmpty) {
    sb.writeln('TEXT $mx,$ySku,"${profile.fontId}",0,1,1,"$skuLine"');
  }

  sb.writeln('PRINT 1,${profile.copies}');
  debugPrint(sb.toString());
  return sb.toString();
}


/// English: Get default profiles
LabelProfile defaultLabel40x25() => const LabelProfile(
  id: 'default_40x25',
  name: 'Default 40x25',
  copies: 1,
  widthMm: 40,
  heightMm: 25,
  marginXmm: 2,
  marginYmm: 2,
  barcodeHeightMm: 12,
  charactersToPrint: 0,
  maxCharsPerLine:  22,
  barcodeHeight: 50,
  barcodeNarrow: 2,
  barcodeWidth: 3,
  fontId: 1,
  gapMm: 2,



);

LabelProfile defaultLabel60x40() => const LabelProfile(
  id: 'default_60x40',
  name: 'Default 60x40',
  copies: 1,
  widthMm: 60,
  heightMm: 40,
  marginXmm: 2,
  marginYmm: 2,
  barcodeHeightMm: 18,
  charactersToPrint: 0,
  maxCharsPerLine: 35,
  barcodeHeight: 50,
  barcodeWidth: 3,
  barcodeNarrow: 2,
  fontId: 1,
  gapMm: 3,

);

String encodeListJson(List<Map<String, dynamic>> items) => jsonEncode(items);
List<Map<String, dynamic>> decodeListJson(String raw) {
  final v = jsonDecode(raw);
  if (v is List) return v.cast<Map<String, dynamic>>();
  return <Map<String, dynamic>>[];
}
