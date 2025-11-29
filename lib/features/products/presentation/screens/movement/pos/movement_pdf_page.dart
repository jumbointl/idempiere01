// movement_pdf_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import 'print_controller.dart';

class MovementPdfPage extends ConsumerStatefulWidget {
  // Puedes pasar args por GoRouter (params o extra). Aquí lo dejo por constructor.
  final String ip;
  final int port;
  final MovementAndLines data;

  const MovementPdfPage({
    super.key,
    required this.ip,
    required this.port,
    required this.data,
  });

  @override
  ConsumerState<MovementPdfPage> createState() => _MovementPdfPageState();
}

class _MovementPdfPageState extends ConsumerState<MovementPdfPage> {
  @override
  void initState() {
    super.initState();
    // Inicializa el controller, lo que genera el PDF
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(printControllerProvider.notifier).init(
        ip: widget.ip,
        port: widget.port,
        data: widget.data,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncPdf = ref.watch(printControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista previa del movimiento'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: asyncPdf.when(
              data: (bytes) {
                // Usa PdfPreview para mostrar lo que vamos a imprimir
                return PdfPreview(
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  build: (format) async {
                    // Si ya lo tenemos generado, úsalo; si no, regenera
                    if (bytes != null) return bytes;
                    final regenerated =
                    await ref.read(printControllerProvider.notifier).build();
                    return regenerated ?? Uint8List(0);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error generando PDF: $e'),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('Reimprimir'),
                      onPressed: () async {
                        try {
                          await ref.read(printControllerProvider.notifier).printToSocket();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enviado a la impresora.')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al imprimir: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
