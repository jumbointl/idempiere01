import 'package:monalisapy_features/zpl_template/models/zpl_template.dart';

class CreateZplTemplateRequest {
  final ZplTemplateMode mode;
  final bool isForPrinter;
  final String content;
  final int rowsPerPage;
  final bool isDefault;

  // NEW
  final bool overwrite;

  const CreateZplTemplateRequest({
    required this.mode,
    required this.isForPrinter,
    required this.content,
    required this.rowsPerPage,
    required this.isDefault,
    this.overwrite = false,
  });
}
