import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/printer/pos/sock_time_out_provider.dart';

Future<void> showSocketTimeoutSelectorDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  int current = ref.read(sockTimeOutInSecoundsProvider);

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Socket timeout (segundos)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Actual: $current s'),
                Slider(
                  value: current.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  label: '$current',
                  onChanged: (v) => setState(() => current = v.round()),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sugerencia: 6–8s para Wi-Fi inestable.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await saveSockTimeoutSeconds(ref, current);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}
