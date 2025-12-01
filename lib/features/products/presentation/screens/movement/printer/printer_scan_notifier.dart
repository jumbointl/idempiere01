import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_net_printer/flutter_net_printer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/movement_provider.dart';
import '../pos/movement_direct_print.dart';
import 'cups_printer.dart';
import 'lite_ipp_print.dart';
import 'mo_printer.dart';
import 'movement_pdf_generator.dart';

// Definir el enum para los tipos de impresora


class PrinterState {
  final TextEditingController nameController;
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController typeController;

  static const int PRINTER_TYPE_POS = 1;
  static const int PRINTER_TYPE_ZPL = 2;
  static const int PRINTER_TYPE_TSPL = 3;
  static const int PRINTER_TYPE_TPL = 3;
  static const int PRINTER_TYPE_A4 = 4;


  PrinterState({
    required this.nameController,
    required this.ipController,
    required this.portController,
    required this.typeController,
  });
}

class PrinterScanNotifier extends StateNotifier<PrinterState>  {
  PrinterScanNotifier()
      : super(PrinterState(
    nameController: TextEditingController(),
    ipController: TextEditingController(),
    portController: TextEditingController(),
    typeController: TextEditingController(),
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
      typeController: state.typeController,
    );
  }
  bool isA4(String type){
    return type == 'A4';
  }
  Future<void> printToCupsPdf(WidgetRef ref) async {
    if(state.ipController.text.isEmpty || state.nameController.text.isEmpty
        || state.portController.text.isEmpty){
      showErrorMessage(ref.context, ref, Messages.ERROR_EMPTY_FIELDS);
      return;
    }

    ref.read(isPrintingProvider.notifier).state = true;
    MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
    final image = await imageLogo;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    String cupsServiceUrl = Memory.URL_CUPS_SERVER;
    String documentNo = movementAndLines.documentNo ?? 'document-mo';
    if(state.portController.text=='631'){
      cupsServiceUrl = Memory.getUrlCupsServerWithPrinter(state.ipController.text,
          state.portController.text,state.nameController.text);
      await printPdfToCUPSDirect(ref, pdfBytes, cupsServiceUrl,documentNo,LiteIppPrintOptions.PRINTER_ORIENTATION_LANDSCAPE);
    } else {
      cupsServiceUrl = Memory.getUrlNodeCupsServer(state.ipController.text,
          state.portController.text);
      await sendPdfToNode(ref,pdfBytes, cupsServiceUrl,state.nameController.text);
    }
    ref.read(isPrintingProvider.notifier).state = false;
  }

  // Actualizar los controladores con el resultado del escaneo
  Future<void> updateFromScan(String qrData, WidgetRef ref) async {
    clearControllers(); // Limpiar antes de actualizar
    print('QR Data: $qrData');
    final parts = qrData.split(':');
    if (parts.length == 5) {
      var printer = ref.read(lastPrinterProvider.notifier);
      MOPrinter moPrinter = MOPrinter();

      final ip = parts[0];
      moPrinter.ip = ip;
      final port = int.tryParse(parts[1]) ?? 0;
      moPrinter.port = port.toString();
      final typeString  = parts[2].toUpperCase();
      moPrinter.type = typeString;
      final name = parts[3];
      moPrinter.name = name;
      //parts[4]='END' not used
      printer.state = MOPrinter();
      state.nameController.text = name;
      state.ipController.text = ip;
      state.portController.text = port.toString();
      state.typeController.text = typeString;


      state = PrinterState(
        nameController: state.nameController,
        ipController: state.ipController,
        portController: state.portController,
        typeController: state.typeController,
      );
      Future.delayed(const Duration(milliseconds:500), () {

      });
      if(state.typeController.text.startsWith('A4')) {
        printToCupsPdf(ref);
      } else if(state.typeController.text.startsWith('POS')){
        print('----------------------------POS');
        MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
        if(!movementAndLines.hasMovement || !movementAndLines.hasMovementLines) {
          if (ref.context.mounted) {
            showWarningMessage(ref.context, ref,
                '${Messages.MOVEMENT_NOT_FOUND} : ${state.nameController} at '
                    '${state.ipController.text}:${state.portController
                    .text} type ${state.typeController.text}');
          }
          return;
        }
        int port = int.tryParse(state.portController.text) ?? 9100;
        printReceiptWithQr(state.ipController.text, port, movementAndLines);
        /*ref.context.go(
          AppRouter.PAGE_MOVEMENT_PRINT_POS,
          extra: {
            'ip': state.ipController.text,
            'port': port,
            'movementAndLines': movementAndLines,
          },
        );*/
      } else if(state.typeController.text.startsWith('ZPL')){
        print('----------------------------ZPL');
        if(ref.context.mounted) {
          showWarningMessage(ref.context, ref, '${Messages.NOT_ENABLED} :${state.nameController} at '
              '${state.ipController.text}:${state.portController.text} type ${state.typeController.text}');
        }
      } else if(state.typeController.text.startsWith('TSPL')){
        print('----------------------------TSPL');
        if(ref.context.mounted) {
          showWarningMessage(ref.context, ref, '${Messages.NOT_ENABLED} :${state.nameController} at '
              '${state.ipController.text}:${state.portController.text} type- ${state.typeController.text}');
        }
      } else if(state.typeController.text.startsWith('TPL')){
        print('----------------------------TPL');
        if(ref.context.mounted) {
          showWarningMessage(ref.context, ref, '${Messages.NOT_ENABLED} ${state.typeController.text}');
        }
      } else {
        if(ref.context.mounted) {
          showErrorMessage(ref.context, ref, '${Messages.NOT_ENABLED} ${state.typeController.text}');
        }
      }
    } else {
      // Manejar formato incorrecto, puedes mostrar un SnackBar
      state.nameController.text = 'Formato de QR inválido';
      showErrorMessage(ref.context, ref, Messages.ERROR_QR_FORMAT);

    }
  }
  void setType(String newType) {
    state.typeController.text = newType;

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
    print('Intentando imprimir en ${state.ipController.text }:${state.portController.text} con tipo ${state.typeController.text}');

    // Usa la clase FlutterNetPrinter directamente.
    final printer = FlutterNetPrinter();
    int port = int.tryParse(state.portController.text) ?? 9100;
    switch(state.typeController.text) {
      case PrinterState.PRINTER_TYPE_POS:
      case PrinterState.PRINTER_TYPE_ZPL:
      case PrinterState.PRINTER_TYPE_TSPL:
        // Lógica común para estos tipos si es necesario
        showWarningMessage(ref.context, ref, Messages.NOT_ENABLED);
        break;
      case PrinterState.PRINTER_TYPE_A4:
        /*ref.read(printerProvider.notifier).setIp(state.ipController.text);
        ref.read(printerProvider.notifier).setPort(state.portController.text);
        ref.read(printerProvider.notifier).setName(state.nameController.text);
        ref.read(printerProvider.notifier).setType(PrinterState.PRINTER_TYPE_A4);*/
        MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
        final image = await imageLogo;
        final pdfBytes = await generateMovementDocument(movementAndLines, image);
        String cupsServiceUrl = Memory.URL_CUPS_SERVER;
        if(state.ipController.text.isNotEmpty && state.ipController.text != ''){
          cupsServiceUrl = Memory.getUrlCupsServerWithPrinter(state.ipController.text,
              state.portController.text,state.nameController.text);
        }

        String printerName = state.nameController.text =='' ? 'BR_HL_10003' : state.nameController.text;
        await sendPdfToNode(ref,pdfBytes, cupsServiceUrl,printerName,);


      default:
        if(ref.context.mounted) {
          showWarningMessage(ref.context, ref, Messages.NOT_ENABLED);
        }
      break;
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
  String get scannedData =>'${state.ipController.text}:${state.portController.text}:${state.typeController.text}:${state.nameController.text}:END';

  void printToPrinter(MOPrinter printer, WidgetRef ref) {
    state.nameController.text = printer.name!;
    state.ipController.text = printer.ip!;
    state.portController.text = printer.port!.toString();
    state.typeController.text = printer.type!;


    state = PrinterState(
      nameController: state.nameController,
      ipController: state.ipController,
      portController: state.portController,
      typeController: state.typeController,
    );
    if(state.typeController.text.startsWith('A4')) {
      printToCupsPdf(ref);
    } else if(state.typeController.text.startsWith('POS')){
      print('----------------------------POS');
      if(ref.context.mounted) {
        showWarningMessage(ref.context, ref, '${Messages.NOT_ENABLED} : ${state.nameController} at '
            '${state.ipController.text}:${state.portController.text} type ${state.typeController.text}');
      }
    } else if(state.typeController.text.startsWith('ZPL')){
      print('----------------------------ZPL');
      if(ref.context.mounted) {
        showWarningMessage(ref.context, ref, '${Messages.NOT_ENABLED} :${state.nameController} at '
            '${state.ipController.text}:${state.portController.text} type ${state.typeController.text}');
      }
    } else if(state.typeController.text.startsWith('TSPL')){
      print('----------------------------TSPL');
      if(ref.context.mounted) {
        showWarningMessage(ref.context, ref, '${Messages.NOT_ENABLED} :${state.nameController} at '
            '${state.ipController.text}:${state.portController.text} type- ${state.typeController.text}');
      }
    } else if(state.typeController.text.startsWith('TPL')){
      print('----------------------------TPL');
      if(ref.context.mounted) {
        showWarningMessage(ref.context, ref, '${Messages.NOT_ENABLED} ${state.typeController.text}');
      }
    } else {
      if(ref.context.mounted) {
        showErrorMessage(ref.context, ref, '${Messages.NOT_ENABLED} ${state.typeController.text}');
      }
    }

  }


}

// Proveedor para acceder al Notifier
final printerProvider = StateNotifierProvider<PrinterScanNotifier, PrinterState>((ref) {
  return PrinterScanNotifier();
});
