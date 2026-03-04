import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';

class LocatorZplTemplate {
  static const String COPIES_VALUE = 'COPIES_VALUE';
  static const String LOCATOR_VALUE = 'LOCATOR_VALUE';

  // IDs recomendados (para poder detectar "default" fácil)
  static const String kDefaultId = 'default_locator_100x40_v1';

  final String id;
  final String name;
  final String templateFilename; // Ej: "WHLabel.ZPL" o "E:WHLabel.ZPL"
  final bool isDefault;
  final String size; // Ej: "100x40mm"
  final String sentenceToSendToPrinter; // sentencia ^XA ... ^XZ que define el template (DF)
  final int printingIntervalMs; // sentencia ^XA ... ^XZ que define el template (DF)

  const LocatorZplTemplate({
    required this.id,
    required this.name,
    required this.templateFilename,
    required this.isDefault,
    required this.size,
    required this.sentenceToSendToPrinter,
    required this.printingIntervalMs,
  });

  LocatorZplTemplate copyWith({
    String? id,
    String? name,
    String? templateFilename,
    bool? isDefault,
    String? size,
    String? sentenceToSendToPrinter,
    int? printingInterval,
  }) {
    return LocatorZplTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      templateFilename: templateFilename ?? this.templateFilename,
      isDefault: isDefault ?? this.isDefault,
      size: size ?? this.size,
      sentenceToSendToPrinter: sentenceToSendToPrinter ?? this.sentenceToSendToPrinter,
      printingIntervalMs: printingInterval ?? printingIntervalMs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'templateFilename': templateFilename,
    'isDefault': isDefault,
    'size': size,
    'sentenceToSendToPrinter': sentenceToSendToPrinter,
    'printingIntervalMs': printingIntervalMs,
  };

  factory LocatorZplTemplate.fromJson(Map<String, dynamic> json) {
    return LocatorZplTemplate(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      templateFilename: (json['templateFilename'] ?? '').toString(),
      isDefault: (json['isDefault'] is bool)
          ? json['isDefault'] as bool
          : (json['isDefault'].toString().toLowerCase() == 'true'),
      size: (json['size'] ?? '').toString(),
      sentenceToSendToPrinter: (json['sentenceToSendToPrinter'] ?? '').toString(),
      printingIntervalMs: (json['printingIntervalMs'] ?? 0) as int,
    );
  }

  // -----------------------------
  // ✅ DEFAULT TEMPLATE FACTORY
  // -----------------------------
  static LocatorZplTemplate getDefaultTemplate() {
    const defaultName = 'Label Locator 100mmx40mm';
    const defaultFileName = 'Loc10x4.ZPL'; // lo guardamos como nombre simple
    const defaultSize = '100x40mm';

    // Esta sentencia es para "guardar" (DF) el template en la impresora.
    // NOTA:
    // - ^PW800 ^LL320 asume 8 dots/mm -> 100mm=800 dots, 40mm=320 dots
    // - Texto arriba, barcode debajo
    // - ^BCN,100,N,N,N => NO imprime texto humano debajo del barcode
    const defaultSentence = '''
^XA
^DFE:$defaultFileName^FS
^PW800
^LL320
^CI28
^LH0,0
^FO30,90
^A0N,50,50
^FN1^FS
^FO30,160
^BY2,2,100
^BCN,100,N,N,N
^FN1^FS
^XZ
''';

    return const LocatorZplTemplate(
      id: kDefaultId,
      name: defaultName,
      templateFilename: defaultFileName,
      isDefault: true,
      size: defaultSize,
      sentenceToSendToPrinter: defaultSentence,
      printingIntervalMs: 1,
    );
  }

  // -----------------------------
  // Helpers
  // -----------------------------
  /// Normaliza para usar en ^XF:
  /// - Si ya tiene "E:" / "R:" / "A:" etc, lo deja.
  /// - Si no tiene ":", asume "E:".
  /// - Si trae ".ZPL", para ^XF podés usar con o sin extensión; acá lo dejamos SIN extensión por defecto.
  String _xfRefFromFilename(String filename) {
    var f = filename.trim();
    if (f.isEmpty) return '';

    // Si viene "WHLabel.ZPL" -> base "WHLabel"
    // Si viene "E:WHLabel.ZPL" -> base "E:WHLabel"
    final hasDevice = f.contains(':');
    String device = 'E:';
    String body = f;

    if (hasDevice) {
      final parts = f.split(':');
      device = '${parts.first}:';
      body = parts.sublist(1).join(':');
    }

    // quitar extensión
    if (body.toUpperCase().endsWith('.ZPL')) {
      body = body.substring(0, body.length - 4);
    }

    return hasDevice ? '$device$body' : 'E:$body';
  }

  // -----------------------------
  // ✅ Runtime print sentence
  // -----------------------------
  /// Imprime usando el template almacenado:
  /// ^XFE:WHLabel^FS
  /// ^FN1^FD<locator>^FS
  String getSentenceToZplPrinter(IdempiereLocator locator) {
    if (templateFilename.trim().isEmpty) return '';

    final locatorValue = (locator.value ?? locator.identifier ?? '').trim();
    if (locatorValue.isEmpty) return '';


    final xfRef = _xfRefFromFilename(templateFilename);
    if (xfRef.isEmpty) return '';

    final sentence = '''
^XA
^XF$xfRef^FS
^CI28
^FN1^FD$locatorValue^FS
^XZ
''';

    return sentence;
  }
}