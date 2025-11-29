// movement_pos_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import 'pos_print_controller.dart';

class MovementPosPage extends ConsumerStatefulWidget {
  final String ip;
  final int port;
  final MovementAndLines data;

  const MovementPosPage({
    super.key,
    required this.ip,
    required this.port,
    required this.data,
  });

  @override
  ConsumerState<MovementPosPage> createState() => _MovementPosPageState();
}

class _MovementPosPageState extends ConsumerState<MovementPosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posPrintControllerProvider.notifier).init(
        ip: widget.ip,
        port: widget.port,
        data: widget.data,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncBytes = ref.watch(posPrintControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Movimiento (ESC/POS)'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: _PreviewText(m: widget.data),
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
                      onPressed: asyncBytes.isLoading
                          ? null
                          : () async {
                        try {
                          await ref.read(posPrintControllerProvider.notifier).printToSocket();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enviado a impresora (ESC/POS).')),
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
                      onPressed: () => context.pop(),
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

class _PreviewText extends StatelessWidget {
  final MovementAndLines m;
  const _PreviewText({required this.m});

  @override
  Widget build(BuildContext context) {
    final totalItems = (m.movementLines ?? [])
        .fold<double>(0.0, (acc, e) => acc + (e.movementQty ?? 0.0));

    final lines = m.movementLines ?? const <IdempiereMovementLine>[];
    final buffer = StringBuffer()
      ..writeln(m.documentMovementTitle)
      ..writeln(m.movementDate ?? '')
      ..writeln('MONALISA S.A.')
      ..writeln(m.documentStatus)
      ..writeln(m.documentNumber)
      ..writeln('Av. Monseñor Rodriguez')
      ..writeln('C/ Av. Carlos Antonio López, CDE')
      ..writeln('Actualizacion de existencias')
      ..writeln('');

    for (final e in lines) {
      buffer
        ..writeln('— ${e.uPC ?? '-'} / ${e.sKU ?? '-'}   |   ${e.locatorToName} ← ${e.locatorFromName}')
        ..writeln('   ${e.productNameWithLine}  |  ${e.attributeName ?? '-'}   |   ${e.movementQtyString}');
    }

    buffer
      ..writeln('')
      ..writeln('ITEMS TOTAL ${totalItems.toStringAsFixed(3)}');

    return Text(buffer.toString());
  }
}
