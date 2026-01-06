import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/printer/pos/print_ticket_by_socket_action_provider.dart';
import 'package:monalisa_app_001/features/printer/pos/sock_time_out_provider.dart';

Future<void> showPrinterRaw9100DiagnosticDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String ip,
  required int port,
}) async {
  final timeoutSec = ref.read(sockTimeOutInSecoundsProvider);

  String text = 'Diagnóstico RAW 9100\n'
      'IP: $ip\n'
      'Port: $port\n'
      'Timeout: ${timeoutSec}s\n\n'
      'Ejecutando...\n';

  bool isPrinting = false;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future.microtask(() async {
            if (!text.contains('Ejecutando...')) return;

            final swAll = Stopwatch()..start();

            final probe = await probeWithRetries(
              host: ip,
              port: port,
              retries: 2,
              timeout: Duration(seconds: timeoutSec.clamp(1, 30)),
              retryDelay: const Duration(milliseconds: 300),
            );

            String sendResult = '';
            if (probe.ok) {
              final err = await rawSend9100(
                host: ip,
                port: port,
                bytes: const <int>[0x0A], // 1 byte LF
                timeout: Duration(seconds: timeoutSec),
              );
              sendResult = (err == null)
                  ? 'RAW send: OK (1 byte LF)\n'
                  : 'RAW send: FAIL -> $err\n';
            }

            swAll.stop();

            setState(() {
              text = 'Diagnóstico RAW 9100\n'
                  'IP: $ip\n'
                  'Port: $port\n'
                  'Timeout: ${timeoutSec}s\n\n'
                  'TCP probe: ${probe.ok ? "OK" : "FAIL"}\n'
                  '${probe.message}\n\n'
                  '${probe.ok ? sendResult : ""}'
                  'Total: ${swAll.elapsedMilliseconds}ms\n';
            });
          });

          Future<void> doPrintMiniTicket() async {
            setState(() => isPrinting = true);

            final miniBytes = buildMiniTestTicketBytes(
              ip: ip,
              port: port,
              timeoutSec: timeoutSec,
            );

            final err = await rawSend9100(
              host: ip,
              port: port,
              bytes: miniBytes,
              timeout: Duration(seconds: timeoutSec),
            );

            setState(() => isPrinting = false);

            if (!ctx.mounted) return;

            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  err == null
                      ? 'Mini ticket enviado (RAW OK)'
                      : 'Falló mini ticket: $err',
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }

          return AlertDialog(
            title: const Text('Diagnóstico impresora (RAW 9100)'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: SelectableText(text),
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copiar'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Diagnóstico copiado al portapapeles'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              TextButton.icon(
                icon: isPrinting
                    ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.receipt_long),
                label: Text(isPrinting ? 'Imprimiendo...' : 'Imprimir mini ticket'),
                onPressed: isPrinting ? null : doPrintMiniTicket,
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    },
  );
}
