class Barcode {
  final int index;
  final String code;
  int repetitions;
  bool coloring;

  Barcode({
    required this.index,
    required this.code,
    required this.repetitions,
    required this.coloring,
  });

  // ------------------------
  // copyWith
  // ------------------------
  Barcode copyWith({
    int? index,
    String? code,
    int? repetitions,
    bool? coloring,
  }) {
    return Barcode(
      index: index ?? this.index,
      code: code ?? this.code,
      repetitions: repetitions ?? this.repetitions,
      coloring: coloring ?? this.coloring,
    );
  }

  // ------------------------
  // toJson
  // ------------------------
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'code': code,
      'repetitions': repetitions,
      'coloring': coloring,
    };
  }

  // ------------------------
  // fromJson
  // ------------------------
  factory Barcode.fromJson(Map<String, dynamic> json) {
    return Barcode(
      index: json['index'] is int
          ? json['index']
          : int.tryParse(json['index'].toString()) ?? 0,
      code: json['code']?.toString() ?? '',
      repetitions: json['repetitions'] is int
          ? json['repetitions']
          : int.tryParse(json['repetitions'].toString()) ?? 0,
      coloring: json['coloring'] == true,
    );
  }
}
