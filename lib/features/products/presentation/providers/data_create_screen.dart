import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// English: Close behavior for create screens
enum DataCreateCloseMode {
  closeOnly, // Close just this screen/modal
  custom, // Delegate to subclass (navigation, etc.)
}

/// English:
/// Base screen for "create" flows. It standardizes:
/// - AppBar with close button
/// - PopScope behavior
/// - Basic layout
abstract class DataCreateScreen extends ConsumerStatefulWidget {
  final DataCreateCloseMode closeMode;

  const DataCreateScreen({
    super.key,
    this.closeMode = DataCreateCloseMode.closeOnly,
  });
}

abstract class DataCreateScreenState<T extends DataCreateScreen>
    extends ConsumerState<T> {
  // ---------- Abstract API ----------
  String get title;

  /// English: Main body content
  Widget buildBody(BuildContext context, WidgetRef ref);

  /// English: Called when the user closes/back
  void onClose(BuildContext context, WidgetRef ref);

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => onClose(context, ref),
        ),
      ),
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, __) => onClose(context, ref),
          child: buildBody(context, ref),
        ),
      ),
    );
  }
}
