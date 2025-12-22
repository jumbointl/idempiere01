import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/new/template_zpl_utils.dart';

import '../../../../../../common/messages_dialog.dart';
import '../../printer_scan_notifier.dart';

Future<void> sendRibbonCommand({
  required BuildContext context,
  required WidgetRef ref,
  required bool useRibbon,
}) async {
  final printerState = ref.read(printerScanProvider);
  final ip = printerState.ipController.text.trim();
  final port =
      int.tryParse(printerState.portController.text.trim()) ?? 0;

  if (ip.isEmpty || port == 0) {
    showErrorMessage(
      context,
      ref,
      'Impresora no configurada (IP / Puerto)',
    );
    return;
  }

  final zpl = useRibbon
      ? '^XA\n^MTT\n^XZ' // CON ribbon
      : '^XA\n^MTD\n^XZ'; // SIN ribbon

  try {
    await sendZplBySocket(
      ip: ip,
      port: port,
      zpl: zpl,
    );

    if(context.mounted) {
      showSuccessMessage(
      context,
      ref,
      useRibbon
          ? 'Impresora configurada CON ribbon'
          : 'Impresora configurada SIN ribbon',
    );
    }
  } catch (e) {
    if(context.mounted) {
      showErrorMessage(
      context,
      ref,
      'Error al enviar comando ZPL: $e',
    );
    }
  }
}
