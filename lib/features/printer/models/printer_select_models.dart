import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';

final copiesTempProvider = StateProvider<int>((ref) => 1);

enum PrinterConnType { bluetooth, wifi }

class PrinterConnConfig {
  final String id;
  final PrinterConnType type;
  final String name;

  final String? ip;
  final int? port;

  final String? btAddress;
  final String? lang;
  final String? typeText;

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
          ? PrinterConnType.bluetooth
          : PrinterConnType.wifi,
      name: json['name']?.toString() ?? '',
      ip: json['ip']?.toString(),
      port: json['port'] is int
          ? json['port'] as int
          : int.tryParse('${json['port']}'),
      btAddress: json['btAddress']?.toString(),
      lang: json['lang']?.toString() ?? 'TSPL',
      typeText: json['typeText']?.toString() ?? '',
    );
  }

  String get printerInformationName {
    switch (type) {
      case PrinterConnType.bluetooth:
        return name.isEmpty ? 'No name' : name;
      case PrinterConnType.wifi:
        return name.isEmpty ? '${ip ?? 'No ip'}:${port ?? 'No port'}' : name;
    }
  }

  String get printerInformationAddress {
    switch (type) {
      case PrinterConnType.bluetooth:
        return btAddress ?? '';
      case PrinterConnType.wifi:
        return '${ip ?? 'No ip'}:${port ?? 'No port'}';
    }
  }

  String getPrinterInfoQRString() {
    switch (type) {
      case PrinterConnType.bluetooth:
        return 'BLUETOOTH*${name.isEmpty ? 'No name' : name}*${btAddress ?? 'No address'}*${lang ?? 'No lang'}*${typeText ?? 'No type'}';
      case PrinterConnType.wifi:
        return '${ip ?? 'No ip'}:${port ?? 'No port'}:${lang ?? 'No lang'}';
    }
  }
}

class PrinterSelectStorageKeys {
  static const String printersList = 'printer_select_printers_list_v1';
  static const String selectedPrinterId = 'printer_select_selected_printer_id_v1';
  static const String labelProfilesList = 'label_profiles_list_v1';
  static const String selectedLabelProfileId = 'label_profiles_selected_id_v1';
}

String encodeListJson(List<Map<String, dynamic>> items) => jsonEncode(items);

List<Map<String, dynamic>> decodeListJson(String raw) {
  final dynamic v = jsonDecode(raw);
  if (v is List) {
    return v.cast<Map<String, dynamic>>();
  }
  return <Map<String, dynamic>>[];
}