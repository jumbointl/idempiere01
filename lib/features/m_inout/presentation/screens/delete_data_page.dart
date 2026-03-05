import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/common/async_value_function_consumer_state.dart';
import '../../../products/common/idempiere_rest_api.dart';
import '../../../products/domain/idempiere/response_async_value.dart';
import '../../../products/domain/idempiere/response_async_value_ui_model.dart';
import '../../../products/presentation/widget/response_async_value_messages_card.dart';

typedef DeleteDataAction = Future<ResponseAsyncValue> Function(WidgetRef ref);
typedef DeleteResultAction = void Function(WidgetRef ref, ResponseAsyncValue result);

/// Generic delete page with confirm/cancel -> async delete -> result -> OK flow.
class DeleteDataPage extends ConsumerStatefulWidget {
  final String modelName;
  final int? id;

  final String title;
  final String subtitle;
  final String message;

  /// English comment: "If false, confirm is not allowed and page shows an error card."
  final bool canDelete;
  final String? notAllowedMessage;

  /// English comment: "Optional custom delete action. If null, uses REST generic delete adapter."
  final DeleteDataAction onDelete;

  /// English comment: "Executed after user presses OK on result panel."
  final DeleteResultAction onResult;

  const DeleteDataPage({
    super.key,
    required this.modelName,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.canDelete,
    this.notAllowedMessage,
    DeleteDataAction? onDelete,
    required this.onResult,
  }) : onDelete = onDelete ?? _defaultDelete;

  static Future<ResponseAsyncValue> _defaultDelete(WidgetRef ref) async {
    // English comment:
    // "This default is never called directly because we need modelName/id;
    // subclasses must pass onDelete or rely on DeleteDataPageState default builder."
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'Delete action not configured',
    );
  }

  @override
  ConsumerState<DeleteDataPage> createState() => _DeleteDataPageState();
}

class _DeleteDataPageState extends AsyncValueFunctionConsumerState<DeleteDataPage> {
  @override
  String get confirmTitle => widget.title;

  @override
  String get confirmSubtitle => widget.subtitle;

  @override
  String get confirmMessage => widget.message;

  @override
  Future<ResponseAsyncValue> onConfirm(WidgetRef ref) async {
    // English comment: "Block delete when rule says it's not allowed"
    if (!widget.canDelete) {
      return ResponseAsyncValue(
        success: false,
        isInitiated: true,
        data: null,
        message: widget.notAllowedMessage ?? 'Delete not allowed',
      );
    }

    // English comment: "If caller provided custom action, run it"
    if (widget.onDelete != DeleteDataPage._defaultDelete) {
      return widget.onDelete(ref);
    }

    // English comment: "Fallback: use generic REST delete adapter"
    return deleteDataByRESTAPIResponseAsyncValue(
      modelName: widget.modelName,
      id: widget.id,
      ref: ref,
    );
  }

  @override
  void onResult(WidgetRef ref, ResponseAsyncValue result) {

    // English comment: "Execute external callback"
    widget.onResult(ref, result);

    // English comment: "Close this page and return result"
    if (context.mounted) {
      Navigator.of(context).pop(result);
    }
  }
  @override
  void onCancel(WidgetRef ref) {
    goHome();
  }

  @override
  Widget buildConfirmPanel(BuildContext context, WidgetRef ref) {
    // English comment: "If not allowed, show an immediate error card with OK"
    if (!widget.canDelete) {
      final ui = ResponseAsyncValueUiModel(
        state: ResponseUiState.error,
        title: widget.title,
        subtitle: widget.subtitle,
        message: widget.notAllowedMessage ?? 'Delete not allowed',
        backgroundColor: Colors.red[200]!,
        borderColor: Colors.red,
        icon: Icons.lock,
        buttonLabel: 'OK',
        buttonIcon: Icons.check_circle_outline,
        onPressed: () => goHome(),
      );

      return ResponseAsyncValueMessagesCardAnimated(ui: ui);
    }

    return super.buildConfirmPanel(context, ref);
  }

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) {
    throw UnimplementedError();
  }
}