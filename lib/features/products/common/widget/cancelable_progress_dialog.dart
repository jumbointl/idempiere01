import 'dart:async';
import 'package:flutter/material.dart';

Future<({
void Function(int) update,
bool Function() isCancelled,
void Function() close,
})> showCancelableProgressDialog({
  required BuildContext context,
  required int total,
  String title = 'Generando PDF…',
}) async {
  int current = 0;
  bool cancelled = false;

  // English comment: "Completer used to ensure the dialog is built before returning"
  final ready = Completer<void>();

  late void Function(void Function()) setStateDialog;
  bool hasSetState = false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          setStateDialog = setState;
          hasSetState = true;

          // English comment: "Signal that dialog is ready (first build)"
          if (!ready.isCompleted) ready.complete();

          final text = 'Página $current/$total';
          final value = total > 0 ? current / total : null;

          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: value),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cancelled = true;
                  setState(() {});
                },
                child: const Text('CANCELAR'),
              ),
            ],
          );
        },
      );
    },
  );

  // ✅ Wait until the dialog has been built at least once
  await ready.future;

  void update(int page) {
    current = page;
    if (!hasSetState) return; // extra safety
    setStateDialog(() {});
  }

  bool isCancelled() => cancelled;

  void close() {
    // English comment: "Close the dialog route"
    Navigator.of(context, rootNavigator: true).pop();
  }

  return (update: update, isCancelled: isCancelled, close: close);
}
