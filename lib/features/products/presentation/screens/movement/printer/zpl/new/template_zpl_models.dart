enum ZplTemplateMode { category, product }

String zplTemplateModeToJson(ZplTemplateMode mode) => mode.name;

ZplTemplateMode zplTemplateModeFromJson(dynamic v) {
  if (v == null) return ZplTemplateMode.category;
  final s = v.toString().toLowerCase();
  if (s == 'product') return ZplTemplateMode.product;
  return ZplTemplateMode.category;
}

class ZplTemplate {
  final String id;
  final String templateFileName; // "E:TEMPLATE_....ZPL"
  final String zplTemplateDf;    // DF (guardar en impresora)
  final String zplReferenceTxt;  // XF+FN (imprimir)
  final ZplTemplateMode mode;    // category/product
  final DateTime createdAt;

  const ZplTemplate({
    required this.id,
    required this.templateFileName,
    required this.zplTemplateDf,
    required this.zplReferenceTxt,
    required this.mode,
    required this.createdAt,
  });

  ZplTemplate copyWith({
    String? id,
    String? templateFileName,
    String? zplTemplateDf,
    String? zplReferenceTxt,
    ZplTemplateMode? mode,
    DateTime? createdAt,
  }) =>
      ZplTemplate(
        id: id ?? this.id,
        templateFileName: templateFileName ?? this.templateFileName,
        zplTemplateDf: zplTemplateDf ?? this.zplTemplateDf,
        zplReferenceTxt: zplReferenceTxt ?? this.zplReferenceTxt,
        mode: mode ?? this.mode,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateFileName': templateFileName,
    'zplTemplateDf': zplTemplateDf,
    'zplReferenceTxt': zplReferenceTxt,
    'mode': zplTemplateModeToJson(mode),
    'createdAt': createdAt.toIso8601String(),
  };

  factory ZplTemplate.fromJson(Map<String, dynamic> json) => ZplTemplate(
    id: (json['id'] ?? '').toString(),
    templateFileName: (json['templateFileName'] ?? '').toString(),
    zplTemplateDf: (json['zplTemplateDf'] ?? '').toString(),
    zplReferenceTxt: (json['zplReferenceTxt'] ?? '').toString(),
    mode: zplTemplateModeFromJson(json['mode']),
    createdAt:
    DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
        DateTime.now(),
  );
}
class CategoryAgg {
  final String categoryId;
  final String categoryName;
  final num totalQty;
  int? sequence;


  CategoryAgg({
    required this.categoryId,
    required this.categoryName,
    required this.totalQty,
    this.sequence,
  });

  CategoryAgg copyWith({num? totalQty}) => CategoryAgg(
    categoryId: categoryId,
    categoryName: categoryName,
    totalQty: totalQty ?? this.totalQty,
  );
}