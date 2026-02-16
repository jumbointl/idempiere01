import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'action_progress_state.dart';


class ActionProgressDialog extends ConsumerWidget {
  const ActionProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(actionProgressProvider);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 280,
            maxWidth: 420,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// -------- TITLE --------
              const Text(
                'Procesando documento...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              /// -------- MESSAGE --------
              Text(
                p.message.isEmpty ? 'Por favor espere...' : p.message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              /// -------- INDETERMINATE BAR (always moving) --------
              const LinearProgressIndicator(),

              const SizedBox(height: 14),

              /// -------- STEP PROGRESS BAR --------
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: p.value),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(value: value);
                },
              ),

              const SizedBox(height: 8),

              /// -------- STEP COUNTER --------
              Text(
                '${p.step} / ${p.totalSteps}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 4),

              /// -------- PERCENT --------
              Text(
                '${(p.value * 100).toStringAsFixed(0)} %',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



Future<void> showActionProgressDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true, // 👈 IMPORTANTE: definilo explícito y sé consistente
    builder: (dialogCtx) {
      // 👇 guardamos el context del dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(actionProgressProvider.notifier).markDialogOpened(dialogCtx);
      });

      return const ActionProgressDialog(); // tu widget
    },
  ).whenComplete(() {
    ref.read(actionProgressProvider.notifier).markDialogClosed();
  });
}



void closeProgressDialogSafe(WidgetRef ref) {
  try {
    final st = ref.read(actionProgressProvider);
    final dialogCtx = st.dialogContext;
    if (dialogCtx != null) {
      Navigator.of(dialogCtx).pop(); // ✅ cierra SIEMPRE ese dialog
      ref.read(actionProgressProvider.notifier).markDialogClosed();
      return;
    }

    // fallback
    if (ref.context.mounted) {
      Navigator.of(ref.context, rootNavigator: true).maybePop();
    }
  } catch (_) {}
}
