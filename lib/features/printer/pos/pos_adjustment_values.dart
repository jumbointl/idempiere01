enum PosCharSet { cp1252, cp850 }

class PosAdjustmentValues {
  final int id;
  final String machineModel;
  final int printWidthAdjustment;
  final int charactersPerLineAdjustment;

  /// Enum “amigable” para UI
  final PosCharSet charSet;

  /// ✅ NUEVO: valor real para ESC t n
  /// Ej: 2=CP850, 3=CP860, 16=CP1252-like (según firmware), 19=CP858
  final int? escTCodeTable;

  final bool isDefault;

  const PosAdjustmentValues({
    required this.id,
    required this.machineModel,
    required this.printWidthAdjustment,
    required this.charactersPerLineAdjustment,
    required this.charSet,
    this.escTCodeTable,
    required this.isDefault,
  });

  PosAdjustmentValues copyWith({
    int? id,
    String? machineModel,
    int? printWidthAdjustment,
    int? charactersPerLineAdjustment,
    PosCharSet? charSet,
    int? escTCodeTable,
    bool? isDefault,
  }) {
    return PosAdjustmentValues(
      id: id ?? this.id,
      machineModel: machineModel ?? this.machineModel,
      printWidthAdjustment: printWidthAdjustment ?? this.printWidthAdjustment,
      charactersPerLineAdjustment:
      charactersPerLineAdjustment ?? this.charactersPerLineAdjustment,
      charSet: charSet ?? this.charSet,
      escTCodeTable: escTCodeTable ?? this.escTCodeTable,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory PosAdjustmentValues.fromJson(Map<String, dynamic> json) {
    return PosAdjustmentValues(
      id: json['id'] ?? 0,
      machineModel: json['machineModel'] ?? '',
      printWidthAdjustment: json['printWidthAdjustment'] ?? 0,
      charactersPerLineAdjustment: json['charactersPerLineAdjustment'] ?? 0,
      charSet: PosCharSet.values.firstWhere(
            (e) => e.name == (json['charSet'] ?? 'cp1252'),
        orElse: () => PosCharSet.cp1252,
      ),
      escTCodeTable: json['escTCodeTable'], // ✅ NUEVO
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'machineModel': machineModel,
    'printWidthAdjustment': printWidthAdjustment,
    'charactersPerLineAdjustment': charactersPerLineAdjustment,
    'charSet': charSet.name,
    'escTCodeTable': escTCodeTable, // ✅ NUEVO
    'isDefault': isDefault,
  };
}
