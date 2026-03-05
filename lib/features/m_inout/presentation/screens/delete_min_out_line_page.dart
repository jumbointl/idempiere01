import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/common/idempiere_rest_api.dart';
import '../../domain/entities/m_in_out.dart';
import '../../domain/entities/line.dart';
import '../../../products/domain/idempiere/response_async_value.dart';

import 'delete_data_page.dart';

typedef DeleteMInOutLineAction = Future<ResponseAsyncValue> Function(
    WidgetRef ref,
    MInOut mInOut,
    Line line,
    );

class DeleteMInOutLinePage extends DeleteDataPage {
  final MInOut mInOut;
  final Line line;

  /// English comment: "Optional custom delete logic with full context."
  final DeleteMInOutLineAction? customOnDelete;

  DeleteMInOutLinePage({
    super.key,
    required this.mInOut,
    required this.line,
    this.customOnDelete,
    required super.onResult,
  }) : super(
    modelName: 'm_inoutline',
    id: line.id,
    canDelete: mInOut.docStatus.id == 'DR',
    notAllowedMessage: 'You can only delete lines when DocStatus = DR.',
    title: 'Delete MInOut line',
    subtitle: _buildSubtitle(mInOut, line),
    message: _buildMessage(line),
    onDelete: (ref) async {
      // English comment: "If caller provided a custom delete, use it; otherwise use REST adapter"
      if (customOnDelete != null) {
        return customOnDelete(ref, mInOut, line);
      }
      return deleteDataByRESTAPIResponseAsyncValue(
        modelName: 'm_inoutline',
        id: line.id,
        ref: ref,
      );
    },
  );

  static String _buildSubtitle(MInOut mInOut, Line line) {
    final docNo = mInOut.documentNo ?? '';
    final lineNo = line.line?.toString() ?? '';
    final status = mInOut.docStatus.id ?? '' ;
    return 'Doc: $docNo   Line: $lineNo Status: $status';
  }

  static String _buildMessage(Line line) {
    final name = line.productName ?? '';
    final qty = line.movementQty?.toString() ?? '';
    final sku = line.sku ?? line.upc ?? '';
    return 'Product: $name\nSKU: $sku\nQty: $qty\n\nConfirm delete this line?';
  }
}