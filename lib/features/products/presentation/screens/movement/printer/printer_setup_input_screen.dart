import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../provider/products_home_provider.dart';
import '../../movement/printer/mo_printer.dart';
import 'printer_scan_notifier.dart';

class PrinterSetupInputScreen extends ConsumerStatefulWidget {
  const PrinterSetupInputScreen({super.key});

  @override
  ConsumerState<PrinterSetupInputScreen> createState() => _PrinterSetupInputScreenState();
}

class _PrinterSetupInputScreenState extends ConsumerState<PrinterSetupInputScreen> {

  void _savePrinter(WidgetRef ref, BuildContext context) {
    final printerState = ref.read(printerProvider);

    if (printerState.ipController.text.isEmpty ||
        printerState.portController.text.isEmpty ||
        printerState.typeController.text.isEmpty) {
      showWarningMessage(context, ref, Messages.ERROR_SAVE_PRINTER);
      return;
    }

    final printer = MOPrinter()
      ..name = printerState.nameController.text
      ..ip = printerState.ipController.text
      ..port = printerState.portController.text
      ..type = printerState.typeController.text
      ..serverIp = printerState.serverIpController.text
      ..serverPort = printerState.serverPortController.text;

    // Guardar como última impresora
    ref.read(lastPrinterProvider.notifier).state = printer;
    // Activar flag de "imprimir directo con última impresora" si lo usas
    ref.read(directPrintWithLastPrinterProvider.notifier).update((state) => true);

    showSuccessMessage(context, ref, Messages.SAVED);
    Navigator.of(context).pop(); // Volver a la pantalla anterior
  }

  @override
  Widget build(BuildContext context) {
    final printerState = ref.watch(printerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Messages.PRINTER_MANUAL_SETUP, // crea este texto en Messages si no existe
          style: TextStyle(fontSize: themeFontSizeNormal),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                Messages.ENTER_PRINTER_DATA, // otro texto para Messages
                style: TextStyle(
                  fontSize: themeFontSizeNormal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: TextField(
                      controller: printerState.ipController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Messages.IP,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: TextField(
                      controller: printerState.portController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Messages.PORT,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: TextField(
                      controller: printerState.nameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: Messages.NAME,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: TextField(
                      controller: printerState.typeController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: Messages.TYPE,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: TextField(
                      controller: printerState.serverIpController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: Messages.SERVER,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 1,
                    child: TextField(
                      controller: printerState.serverPortController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: Messages.SERVER_PORT,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColorPrimary,
                ),
                onPressed: () => _savePrinter(ref, context),
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  Messages.SAVE,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
