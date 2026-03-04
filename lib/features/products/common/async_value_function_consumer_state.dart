import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/idempiere/response_async_value.dart';
import '../domain/idempiere/response_async_value_ui_model.dart';
// Adjust imports to match your project structure:
// - CommonConsumerState<T>
// - goHome() or navigation helpers
import '../presentation/widget/response_async_value_messages_card.dart';
import 'common_consumer_state.dart';

/// A reusable consumer state that handles a "confirm -> async -> show result -> OK" flow.
///
/// - Shows an initial confirm/cancel panel with a title + message.
/// - When confirm is pressed:
///   - blocks the UI
///   - shows a progress indicator
///   - awaits onConfirm() that returns ResponseAsyncValue
///   - unblocks UI
/// - Shows the result using ResponseAsyncValueMessagesCardAnimated
/// - Provides an OK button that calls onResult(result)
abstract class AsyncValueFunctionConsumerState<T extends ConsumerStatefulWidget>
    extends CommonConsumerState<T> {
  // ----- Required inputs (provided by subclasses) -----

  /// Title shown on the confirm panel.
  String get confirmTitle;

  /// Subtitle shown on the confirm panel (optional, can be empty string).
  String get confirmSubtitle;

  /// Message shown on the confirm panel.
  String get confirmMessage;

  /// Async action executed when user confirms.
  /// Must return a ResponseAsyncValue which will be shown as result.
  Future<ResponseAsyncValue> onConfirm(WidgetRef ref);

  /// Called after user presses OK on the result panel.
  void onResult(WidgetRef ref, ResponseAsyncValue result);

  /// Called when user presses Cancel on the confirm panel.
  /// Default behavior: goHome().
  void onCancel(WidgetRef ref) {
    goHome();
  }

  // ----- Optional UI customizations -----

  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) => null;

  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) => null;

  bool get showLeading => false;

  Widget? get leadingIcon => showLeading
      ? IconButton(
    onPressed: () => onCancel(ref),
    icon: const Icon(Icons.arrow_back),
  )
      : null;

  // ----- Internal state -----

  bool _isBlocking = false;
  ResponseAsyncValue? _result;

  bool get hasResult => _result != null;

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: hasResult
            ? buildResultPanel(context, ref, _result!)
            : buildConfirmPanel(context, ref),
      ),
    );

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: getAppBarBackgroundColor(context, ref),
            automaticallyImplyLeading: showLeading,
            leading: leadingIcon,
            title: getAppBarTitle(context, ref),
          ),
          body: body,
        ),

        // Screen blocker overlay while running confirm action
        if (_isBlocking) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          const Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ],
    );
  }

  Widget buildConfirmPanel(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              confirmTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (confirmSubtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                confirmSubtitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 10),
            Text(confirmMessage, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isBlocking ? null : () => onCancel(ref),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isBlocking ? null : () => handleConfirm(ref),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleConfirm(WidgetRef ref) async {
    // English comment: "Block the screen + show progress while executing async confirm"
    setState(() => _isBlocking = true);

    try {
      final result = await onConfirm(ref);

      // English comment: "Store result and show it"
      setState(() {
        _result = result;
        _isBlocking = false;
      });
    } catch (e) {
      // English comment: "Convert unexpected exception into an error-like ResponseAsyncValue"
      setState(() {
        _result = ResponseAsyncValue(
          success: false,
          isInitiated: true,
          message: e.toString(),
          data: null,
        );
        _isBlocking = false;
      });
    }
  }

  Widget buildResultPanel(BuildContext context, WidgetRef ref, ResponseAsyncValue result) {
    // English comment: "Map domain result into UI model and show animated messages card"
    final ui = mapResponseAsyncValueToUi(
      result: result,
      title: confirmTitle, // reuse confirm title, adjust if you want
      subtitle: confirmSubtitle.isEmpty ? 'Result' : confirmSubtitle,
      buttonLabel: 'OK',
      buttonIcon: Icons.check_circle_outline,
      onPressed: () => handleOk(ref, result),
    );

    return ResponseAsyncValueMessagesCardAnimated(ui: ui);
  }

  void handleOk(WidgetRef ref, ResponseAsyncValue result) {
    // English comment: "Call onResult and optionally reset internal state"
    onResult(ref, result);

    // If you want to return to confirm panel after OK, uncomment:
    // setState(() => _result = null);
  }
}