class Barcode {
  final int index;
  final String code;
  int repetitions;
  bool coloring = false;

  Barcode({
    required this.index,
    required this.code,
    required this.repetitions,
    required this.coloring,
  });

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
}
