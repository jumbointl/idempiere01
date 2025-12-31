import '../../../printer/zpl/new/models/zpl_template.dart';
import 'zpl_printing_template.dart';

class ZplPrintingTemplateMovement extends ZplPrintingTemplate {
  const ZplPrintingTemplateMovement({
    super.directory = 'movement',
    super.templateFilesToPrinter = const [],
    super.filesCanUseToFillData = const [],
  });

  @override
  ZplPrintingTemplateMovement copyWith({
    String? directory,
    List<ZplTemplate>? templateFilesToPrinter,
    List<ZplTemplate>? filesCanUseToFillData,
  }) {
    return ZplPrintingTemplateMovement(
      directory: directory ?? this.directory,
      templateFilesToPrinter: templateFilesToPrinter ?? this.templateFilesToPrinter,
      filesCanUseToFillData: filesCanUseToFillData ?? this.filesCanUseToFillData,
    );
  }

  factory ZplPrintingTemplateMovement.fromJson(Map<String, dynamic> json) {
    final base = ZplPrintingTemplate.fromJson(json);
    return ZplPrintingTemplateMovement(
      directory: base.directory,
      templateFilesToPrinter: base.templateFilesToPrinter,
      filesCanUseToFillData: base.filesCanUseToFillData,
    );
  }

}
