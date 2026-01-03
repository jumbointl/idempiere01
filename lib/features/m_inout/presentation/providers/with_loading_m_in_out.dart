import 'package:flutter/material.dart';

/// Runs an async action while showing a blocking loading dialog.
/// The dialog is always closed with `maybePop()` when possible.
///
/// Usage:
///   final result = await withLoading(context: context, action: () async => ...);
Future<T?> withLoadingMInOut<T>({
  required BuildContext context,
  required Future<T> Function() action,
  String tag = '',
  bool barrierDismissible = false,
  //required WidgetRef ref,
}) async {
  // English comment: "Always use rootNavigator to avoid bottomSheet navigator mismatch"
  final nav = Navigator.of(context, rootNavigator: true);
  //ref.read(initializingProvider.notifier).state = true;
  _showScreenLoading(
    context,
    barrierDismissible: barrierDismissible,
  );

  try {
    final result = await action();
    // English comment: "Close the loading dialog"
    if (nav.canPop()) {
      nav.pop();
    }
    return result;
  } catch (e) {
    if (nav.canPop()) {
      nav.pop();
    }
    rethrow;
  }
}

void _showScreenLoading(
    BuildContext context, {
      bool barrierDismissible = false,
    }) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: true, // ✅ critical
    builder: (_) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
}



/*
3) Recomendación importante (para evitar un bug clásico)
No llames withLoading dos veces seguidas si la UX se vuelve “parpadeo” (abre/cierra/abre/cierra).
En esos casos, es mejor un solo withLoading que englobe toda la secuencia:
final result = await withLoading(
  context: context,
  tag: 'confirm-flow',
  action: () async {
    final mInOut = await mInOutNotifier.getMInOutAndLine(ref);
    final list = await mInOutNotifier.getMInOutConfirmList(mInOut.id!, ref);
    return (mInOut, list);
  },
);


 */
