


enum ZplTemplateMode { movement /*, shipping ... */ }

String zplTemplateModeToJson(ZplTemplateMode mode) => mode.name;

ZplTemplateMode zplTemplateModeFromJson(dynamic v) {
  return ZplTemplateMode.movement;
}



class ZplTemplate {
  final String id;
  final String templateFileName;
  final String zplTemplateDf;
  final String zplReferenceTxt;
  final ZplTemplateMode mode; // ✅ se mantiene
  final int rowPerpage;       // ✅ se mantiene
  final bool isDefault;       // ✅ NUEVO
  final DateTime createdAt;

  const ZplTemplate({
    required this.id,
    required this.templateFileName,
    required this.zplTemplateDf,
    required this.zplReferenceTxt,
    required this.mode,
    required this.rowPerpage,
    required this.isDefault,
    required this.createdAt,
  });

  ZplTemplate copyWith({
    String? id,
    String? templateFileName,
    String? zplTemplateDf,
    String? zplReferenceTxt,
    ZplTemplateMode? mode,
    int? rowPerpage,
    bool? isDefault,
    DateTime? createdAt,
  }) =>
      ZplTemplate(
        id: id ?? this.id,
        templateFileName: templateFileName ?? this.templateFileName,
        zplTemplateDf: zplTemplateDf ?? this.zplTemplateDf,
        zplReferenceTxt: zplReferenceTxt ?? this.zplReferenceTxt,
        mode: mode ?? this.mode,
        rowPerpage: rowPerpage ?? this.rowPerpage,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateFileName': templateFileName,
    'zplTemplateDf': zplTemplateDf,
    'zplReferenceTxt': zplReferenceTxt,
    'mode': mode.name,
    'rowPerpage': rowPerpage,
    'isDefault': isDefault, // ✅ NUEVO
    'createdAt': createdAt.toIso8601String(),
  };

  factory ZplTemplate.fromJson(Map<String, dynamic> json) {
    final modeStr = (json['mode'] ?? '').toString().trim();

    // ✅ Migración: category/product -> movement
    ZplTemplateMode parsedMode;
    switch (modeStr) {
      case 'movement':
        parsedMode = ZplTemplateMode.movement;
        break;
      case 'category':
      case 'product':
        parsedMode = ZplTemplateMode.movement;
        break;
      default:
        parsedMode = ZplTemplateMode.movement;
    }

    final isDefaultRaw = json['isDefault'];

    return ZplTemplate(
      id: (json['id'] ?? '').toString(),
      templateFileName: (json['templateFileName'] ?? '').toString(),
      zplTemplateDf: (json['zplTemplateDf'] ?? '').toString(),
      zplReferenceTxt: (json['zplReferenceTxt'] ?? '').toString(),
      mode: parsedMode,
      rowPerpage: int.tryParse((json['rowPerpage'] ?? '').toString()) ?? 6,
      isDefault: (isDefaultRaw is bool)
          ? isDefaultRaw
          : (isDefaultRaw?.toString().toLowerCase() == 'true'),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
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
class TokenItem {
  final String section;
  final String token;
  const TokenItem(this.section, this.token);
}
