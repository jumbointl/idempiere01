import 'dart:async';

import 'package:flutter/material.dart';

import '../../products/domain/idempiere/response_async_value.dart';

/// Resultado por item
class ZplSendItemResult {
  final int index;
  final bool ok;
  final String? error;

  const ZplSendItemResult({
    required this.index,
    required this.ok,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'ok': ok,
    'error': error,
  };
}


Future<void> showZplBatchResultDialog({
  required BuildContext context,
  required ResponseAsyncValue result,
}) async {
  final bool success = result.success;
  final String message = result.message ?? '';
  final List<dynamic> dataList =
  (result.data is List) ? result.data as List : [];

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                success ? 'Impresión completada' : 'Impresión con errores',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 12),

              // Lista scrollable
              Flexible(
                child: dataList.isEmpty
                    ? const Text('Sin detalles')
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: dataList.length,
                  itemBuilder: (_, index) {
                    final item = dataList[index] as Map<String, dynamic>;
                    final bool ok = item['ok'] == true;
                    final int idx = item['index'] ?? index;
                    final String? error = item['error'];

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        ok ? Icons.check : Icons.close,
                        color: ok ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      title: Text('Etiqueta #$idx'),
                      subtitle:
                      ok ? null : Text(error ?? 'Error desconocido'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}