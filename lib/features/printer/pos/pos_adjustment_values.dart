import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

enum PosCharSet { cp1252, cp850, cp858, utf8 }

/// Cómo enviar texto:
/// - generator: gen.text (rápido, pero puede tirar excepción si hay chars raros)
/// - rawLatin1: manda bytes Latin1 con ESC t n (seguro si sanitizas)
/// - rawUtf8: manda utf8.encode con ESC t 8 (para unicode real)
enum PosTextMode { generator, rawLatin1, rawUtf8 }

class PosAdjustmentValues {
  final int id;
  final String machineModel;

  /// Ajuste de ancho útil (dots) para imágenes/header (puede ser 0, -8, -16...)
  final int printWidthAdjustment;

  /// Ajuste “cols” en texto (ej: 0, -2, -4, -6, -7…)
  final int charactersPerLineAdjustment;

  /// ✅ NUEVO: tamaño de papel (mm58 / mm72 / mm80)
  final PaperSize paperSize;

  /// Enum “amigable” para UI
  final PosCharSet charSet;

  /// Valor real para ESC t n (según firmware)
  /// Ej: 2=CP850, 5=CP858, 8=UTF8, 16=CP1252-like (tu caso)
  final int? escTCodeTable;

  /// ✅ NUEVO: modo de envío de texto
  final PosTextMode textMode;

  final bool isDefault;

  const PosAdjustmentValues({
    required this.id,
    required this.machineModel,
    required this.printWidthAdjustment,
    required this.charactersPerLineAdjustment,
    required this.paperSize,
    required this.charSet,
    this.escTCodeTable,
    required this.textMode,
    required this.isDefault,
  });

  PosAdjustmentValues copyWith({
    int? id,
    String? machineModel,
    int? printWidthAdjustment,
    int? charactersPerLineAdjustment,
    PaperSize? paperSize,
    PosCharSet? charSet,
    int? escTCodeTable,
    PosTextMode? textMode,
    bool? isDefault,
  }) {
    return PosAdjustmentValues(
      id: id ?? this.id,
      machineModel: machineModel ?? this.machineModel,
      printWidthAdjustment: printWidthAdjustment ?? this.printWidthAdjustment,
      charactersPerLineAdjustment:
      charactersPerLineAdjustment ?? this.charactersPerLineAdjustment,
      paperSize: paperSize ?? this.paperSize,
      charSet: charSet ?? this.charSet,
      escTCodeTable: escTCodeTable ?? this.escTCodeTable,
      textMode: textMode ?? this.textMode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory PosAdjustmentValues.fromJson(Map<String, dynamic> json) {
    PaperSize parsePaper(dynamic v) {
      final s = (v ?? 'mm80').toString();
      if (s == 'mm58') return PaperSize.mm58;
      if (s == 'mm72') return PaperSize.mm72;
      return PaperSize.mm80;
    }

    PosTextMode parseTextMode(dynamic v) {
      final s = (v ?? 'rawLatin1').toString();
      return PosTextMode.values.firstWhere(
            (e) => e.name == s,
        orElse: () => PosTextMode.rawLatin1,
      );
    }

    return PosAdjustmentValues(
      id: json['id'] ?? 0,
      machineModel: json['machineModel'] ?? '',
      printWidthAdjustment: json['printWidthAdjustment'] ?? 0,
      charactersPerLineAdjustment: json['charactersPerLineAdjustment'] ?? 0,
      paperSize: parsePaper(json['paperSize']),
      charSet: PosCharSet.values.firstWhere(
            (e) => e.name == (json['charSet'] ?? 'cp1252'),
        orElse: () => PosCharSet.cp1252,
      ),
      escTCodeTable: json['escTCodeTable'],
      textMode: parseTextMode(json['textMode']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'machineModel': machineModel,
    'printWidthAdjustment': printWidthAdjustment,
    'charactersPerLineAdjustment': charactersPerLineAdjustment,
    'paperSize': paperSize == PaperSize.mm58
        ? 'mm58'
        : paperSize == PaperSize.mm72
        ? 'mm72'
        : 'mm80',
    'charSet': charSet.name,
    'escTCodeTable': escTCodeTable,
    'textMode': textMode.name,
    'isDefault': isDefault,
  };
}
