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
  LabelProfile copyWith({
    String? id,
    String? name,
    int? copies,
    double? widthMm,
    double? heightMm,
    double? marginXmm,
    double? marginYmm,
    int? barcodeHeightMm,
    int? charactersToPrint,
    int? maxCharsPerLine,
    int? barcodeHeight,
    int? barcodeWidth,
    int? barcodeNarrow,
    int? fontId,
    int? gapMm,
  }) {
    return LabelProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      copies: copies ?? this.copies,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      marginXmm: marginXmm ?? this.marginXmm,
      marginYmm: marginYmm ?? this.marginYmm,
      barcodeHeightMm: barcodeHeightMm ?? this.barcodeHeightMm,
      charactersToPrint: charactersToPrint ?? this.charactersToPrint,
      maxCharsPerLine: maxCharsPerLine ?? this.maxCharsPerLine,
      barcodeHeight: barcodeHeight ?? this.barcodeHeight,
      barcodeWidth: barcodeWidth ?? this.barcodeWidth,
      barcodeNarrow: barcodeNarrow ?? this.barcodeNarrow,
      fontId: fontId ?? this.fontId,
      gapMm: gapMm ?? this.gapMm,
    );
  }
}