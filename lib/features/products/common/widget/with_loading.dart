import 'package:flutter/material.dart';
import 'package:flutter_riverpod/src/core.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';

/// Runs an async action while showing a blocking loading dialog.
/// The dialog is always closed with `maybePop()` when possible.
///
/// Usage:
///   final result = await withLoading(context: context, action: () async => ...);
Future<T?> withLoadingOld<T>({
  //required BuildContext context,
  required Future<T> Function() action,
  String tag = '',
  bool barrierDismissible = false,
  required WidgetRef ref,
}) async {
  ref.read(initializingProvider.notifier).state = true;

  try {
    final result = await action();
    debugPrint('[withLoading] RESULT $result');
    // English comment: "Close the loading dialog"
    if (ref.context.mounted && ref.context.canPop()) {
      Navigator.of(ref.context).pop();
      //nav.pop();
    }
    ref.read(initializingProvider.notifier).state = false;
    return result;
  } catch (e) {
    debugPrint('[withLoading] ERROR $tag: $e');

    ref.read(initializingProvider.notifier).state = false;
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
