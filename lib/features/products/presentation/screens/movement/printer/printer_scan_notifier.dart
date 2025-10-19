import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_net_printer/flutter_net_printer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/printer_type.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/messages.dart';
import '../provider/new_movement_provider.dart';

// Definir el enum para los tipos de impresora


class PrinterState {
  final TextEditingController nameController;
  final TextEditingController ipController;
  final TextEditingController portController;
  //final TextEditingController typeController;
  final PrinterType type;

  PrinterState({
    required this.nameController,
    required this.ipController,
    required this.portController,
    this.type = PrinterType.unknown,
  });
}

class PrinterScanNotifier extends StateNotifier<PrinterState> {
  PrinterScanNotifier()
      : super(PrinterState(
    nameController: TextEditingController(),
    ipController: TextEditingController(),
    portController: TextEditingController(),
  ));

  // Limpiar todos los controladores
  void clearControllers() {
    state.nameController.clear();
    state.ipController.clear();
    state.portController.clear();
    state = PrinterState(
      nameController: state.nameController,
      ipController: state.ipController,
      portController: state.portController,
      type: PrinterType.unknown,
    );
  }

  // Actualizar los controladores con el resultado del escaneo
  void updateFromScan(String qrData) {
    clearControllers(); // Limpiar antes de actualizar

    final parts = qrData.split(':');
    if (parts.length == 4) {
      final name = parts[0];
      final ip = parts[1];
      final port = int.tryParse(parts[2]) ?? 0;
      final typeString  = parts[3].toUpperCase();

      state.nameController.text = name;
      state.ipController.text = ip;
      state.portController.text = port.toString();

      // Convertir la cadena a un valor de enum
      final type  = PrinterType.values.firstWhere(
            (e) => e.name.toUpperCase() == typeString,
        orElse: () => PrinterType.unknown,
      );

      state = PrinterState(
        nameController: state.nameController,
        ipController: state.ipController,
        portController: state.portController,
        type: type,
      );


    } else {
      // Manejar formato incorrecto, puedes mostrar un SnackBar
      state.nameController.text = 'Formato de QR inválido';
    }
  }
  void setType(PrinterType? newType) {
    if (newType != null) {
      state = PrinterState(
        nameController: state.nameController,
        ipController: state.ipController,
        portController: state.portController,
        type: newType,
      );
    }
  }
  // Métodos para actualizar cada campo si se edita manualmente
  void setName(String newName) {
    state.nameController.text = newName;
  }
  void setIp(String newIp) {
    state.ipController.text = newIp;
  }
  void setPort(String newPort) {
    state.portController.text = newPort;
  }

  Future<void> printDirectly({required Uint8List bytes,required WidgetRef ref}) async {
    print('Intentando imprimir en ${state.ipController.text }:${state.portController.text} con tipo ${state.type}');

    // Usa la clase FlutterNetPrinter directamente.
    final printer = FlutterNetPrinter();
    int port = int.tryParse(state.portController.text) ?? 9100;
    switch(state.type) {
      case PrinterType.POS:
      case PrinterType.ZPL:
      case PrinterType.TSPL:
        // Lógica común para estos tipos si es necesario
        showWarningMessage(ref.context, ref, Messages.NOT_ENABLED);
        break;
      case PrinterType.A4:
        ref.read(printerProvider.notifier).setIp(state.ipController.text);
        ref.read(printerProvider.notifier).setPort(state.portController.text);
        ref.read(printerProvider.notifier).setName(state.nameController.text);
        ref.read(printerProvider.notifier).setType(PrinterType.A4);
        MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);

        ref.context.go(AppRouter.PAGE_PDF_MOVEMENT_AND_LINE, extra: movementAndLines);

      default:
    }

    try {
      // Usa el método connectToPrinter para establecer la conexión.
      final connectedDevice = await printer.connectToPrinter(
          state.ipController.text,
          port,
          timeout: const Duration(seconds: 5)
      );

      if (connectedDevice != null) {
        print('Conexión exitosa a la impresora.');
        // Usa el método printBytes para enviar los datos.
        await printer.printBytes(data: bytes);
        print('Datos de impresión enviados.');

        // El paquete no tiene un método de "desconexión" explícito,
        // ya que maneja la conexión por cada comando de impresión.
      } else {
        print('Error al conectar a la impresora.');
      }
    } catch (e) {
      print('Error al imprimir directamente: $e');
    }
  }


}

// Proveedor para acceder al Notifier
final printerProvider = StateNotifierProvider<PrinterScanNotifier, PrinterState>((ref) {
  return PrinterScanNotifier();
});
