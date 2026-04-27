import 'dart:convert';

import 'package:monalisapy_features/zpl_template/models/zpl_template.dart';

class ZplPrintingTemplate {
  // Filters used to classify files by name
  static const String filterOfFileToPrinter = '_template_file_to_printer';
  static const String filterOfFileToFillData = '_file_to_fill_data';

  final String directory;

  // We store parsed templates (ZplTemplate JSON files)
  final List<ZplTemplate> templateFilesToPrinter;
  final List<ZplTemplate> filesCanUseToFillData;

  const ZplPrintingTemplate({
    required this.directory,
    this.templateFilesToPrinter = const [],
    this.filesCanUseToFillData = const [],
  });

  ZplPrintingTemplate copyWith({
    String? directory,
    List<ZplTemplate>? templateFilesToPrinter,
    List<ZplTemplate>? filesCanUseToFillData,
  }) {
    return ZplPrintingTemplate(
      directory: directory ?? this.directory,
      templateFilesToPrinter: templateFilesToPrinter ?? this.templateFilesToPrinter,
      filesCanUseToFillData: filesCanUseToFillData ?? this.filesCanUseToFillData,
    );
  }

  Map<String, dynamic> toJson() => {
    'directory': directory,
    'templateFilesToPrinter': templateFilesToPrinter.map((e) => e.toJson()).toList(),
    'filesCanUseToFillData': filesCanUseToFillData.map((e) => e.toJson()).toList(),
  };

  factory ZplPrintingTemplate.fromJson(Map<String, dynamic> json) {
    final dir = (json['directory'] ?? '').toString();

    final printerListRaw = json['templateFilesToPrinter'];
    final fillListRaw = json['filesCanUseToFillData'];

    final printerList = (printerListRaw is List)
        ? printerListRaw
        .whereType<Map>()
        .map((m) => ZplTemplate.fromJson(Map<String, dynamic>.from(m)))
        .toList()
        : <ZplTemplate>[];

    final fillList = (fillListRaw is List)
        ? fillListRaw
        .whereType<Map>()
        .map((m) => ZplTemplate.fromJson(Map<String, dynamic>.from(m)))
        .toList()
        : <ZplTemplate>[];

    return ZplPrintingTemplate(
      directory: dir,
      templateFilesToPrinter: printerList,
      filesCanUseToFillData: fillList,
    );
  }

  // Optional: useful for persistence as string
  String toJsonString() => jsonEncode(toJson());

  factory ZplPrintingTemplate.fromJsonString(String s) =>
      ZplPrintingTemplate.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
