import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_net_printer/flutter_net_printer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/printer/pos/print_receipt_with_qr_bematech.dart';
import 'package:monalisa_app_001/features/printer/printer_utils.dart';
import 'package:monalisa_app_001/features/printer/zpl/old/zpl_label_printer_100x150.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import '../products/presentation/providers/common_provider.dart';
import '../products/presentation/screens/movement/provider/new_movement_provider.dart';
import '../shared/data/memory.dart';
import '../shared/data/messages.dart';
import 'cups_printer.dart';
import 'lite_ipp_print.dart';
import 'models/mo_printer.dart';
import 'movement_pdf_generator.dart';

// Definir el enum para los tipos de impresora


class PrinterState {
  final TextEditingController nameController;
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController typeController;
  final TextEditingController serverPortController;
  final TextEditingController serverIpController;


  static const int PRINTER_TYPE_POS_INT = 1;
  static const int PRINTER_TYPE_ZPL_INT = 2;
  static const int PRINTER_TYPE_TSPL_INT = 3;
  static const int PRINTER_TYPE_TPL__INT = 3;
  static const int PRINTER_TYPE_A4__INT = 4;
  static const int PRINTER_TYPE_LABEL__INT = 5;
  static const int PRINTER_TYPE_LASER__INT = 6;
  static const String PRINTER_TYPE_POS = 'POS';
  static const String PRINTER_TYPE_ZPL = 'ZPL';
  static const String PRINTER_TYPE_TSPL = 'TSPL';
  static const String PRINTER_TYPE_TPL = 'TPL';
  static const String PRINTER_TYPE_A4 = 'A4';
  static const String PRINTER_TYPE_LABEL = 'LABEL';
  static const String PRINTER_TYPE_LASER = 'LASER';
  static const String PRINTER_TYPE_BLUETOOTH_BLE = 'BLE';
  static const String PRINTER_TYPE_BLUETOOTH_NO_BLE = 'NO_BLE';
  static const String PRINTER_TYPE_NIIMBOT = 'NIIMBOT';



  PrinterState({
    required this.nameController,
    required this.ipController,
    required this.portController,
    required this.typeController,
    required this.serverPortController,
    required this.serverIpController,
  });
}

class PrinterScanNotifier extends StateNotifier<PrinterState>  {
  PrinterScanNotifier()
      : super(PrinterState(
    nameController: TextEditingController(),
    ipController: TextEditingController(),
    portController: TextEditingController(),
    typeController: TextEditingController(),
    serverPortController: TextEditingController(),
    serverIpController: TextEditingController(),
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
      serverPortController: state.serverPortController,
      serverIpController: state.serverIpController,
    );
  }
  bool isLaser(String type){
    return type == PrinterState.PRINTER_TYPE_LASER;
  }
  bool isPos(String type){
    return type == PrinterState.PRINTER_TYPE_POS;
  }
  bool isZpl(String type){
    return type == PrinterState.PRINTER_TYPE_ZPL;
  }
  bool isTspl(String type){
    return type == PrinterState.PRINTER_TYPE_TSPL;
  }
  bool isTpl(String type){
    return type == PrinterState.PRINTER_TYPE_TPL;
  }
  bool isA4(String type){
    return type == PrinterState.PRINTER_TYPE_A4;
  }
  bool isLabel(String type){
    return type == PrinterState.PRINTER_TYPE_LABEL;
  }
  Future<void> printMovementAndLinesToCupsPdf(WidgetRef ref) async {
    if (state.serverIpController.text.isEmpty ||
        state.nameController.text.isEmpty ||
        state.serverPortController.text.isEmpty) {
      showErrorMessage(ref.context, ref, Messages.ERROR_EMPTY_FIELDS);
      return;
    }

    final isPrinting = ref.read(isPrintingProvider.notifier);
    isPrinting.state = true;

    try {
      final movementAndLines = ref.read(movementAndLinesProvider);
      final image = await imageLogo;
      final pdfBytes = await generateMovementDocument(movementAndLines, image);

      final documentNo = movementAndLines.documentNo ?? 'document-mo';
      final port = state.serverPortController.text.trim();
      final ip = state.serverIpController.text.trim();
      final printerName = state.nameController.text.trim();

      bool res;
      if (port.startsWith('631')) {
        final cupsUrl = Memory.getUrlCupsServerWithPrinter(
          ip: ip,
          port: port,
          printerName: printerName,
        );

        res = await printPdfToCUPSDirect(
          ref,
          pdfBytes,
          cupsUrl,
          documentNo,
          LiteIppPrintOptions.PRINTER_ORIENTATION_LANDSCAPE,
        );

        if (ref.context.mounted) {
          res
              ? showSuccessMessage(ref.context, ref, Messages.PRINT_SUCCESS)
              : showErrorMessage(ref.context, ref, Messages.ERROR_CUPS_PRINT);
        }
      } else {
        final nodeUrl = Memory.getUrlNodeCupsServer(ip: ip, port: port);

        res = await sendPdfToNode(ref, pdfBytes, nodeUrl, printerName);

        if (ref.context.mounted) {
          res
              ? showSuccessMessage(ref.context, ref, '${Messages.PRINT_SUCCESS} $nodeUrl $printerName')
              : showErrorMessage(ref.context, ref, '${Messages.NETWORK_ERROR} $nodeUrl $printerName');
        }
      }

      await Future.delayed(const Duration(seconds: 1));
      debugPrint('Impresion finalizada');
    } catch (e, st) {
      debugPrint('printToCupsPdf ERROR: $e\n$st');
      if (ref.context.mounted) {
        showErrorMessage(ref.context, ref, 'Error: $e');
      }
    } finally {
      // ✅ pase lo que pase, se apaga el loading
      isPrinting.state = false;
    }
  }

  Future<void> updateFromScan(
      String qrData,
      WidgetRef ref, {
        dynamic dataToPrint// ✅ nuevo
      }) async {
    clearControllers();
    debugPrint('QR Data: $qrData');

    final parts = qrData.split(':');
    if (parts.length >= 3) {
      var printer = ref.read(lastPrinterProvider.notifier);
      MOPrinter moPrinter = MOPrinter();

      final ip = parts[0];
      moPrinter.ip = ip;

      final port = int.tryParse(parts[1]) ?? 0;
      moPrinter.port = port.toString();

      final typeString = parts[2].toUpperCase();
      moPrinter.type = typeString;

      printer.state = MOPrinter();

      state.ipController.text = ip;
      state.portController.text = port.toString();
      state.typeController.text = typeString;

      if (parts.length > 3) {
        final name = parts[3];
        moPrinter.name = name;
        state.nameController.text = name;
      }
      if (parts.length > 4) {
        final serverIp = parts[4];
        moPrinter.serverIp = serverIp;
        state.serverIpController.text = serverIp;
      }
      if (parts.length > 5) {
        final serverPort = parts[5];
        moPrinter.serverPort = serverPort;
        state.serverPortController.text = serverPort;
      }

      savePrinterToStorage(ref, moPrinter);

      state = PrinterState(
        nameController: state.nameController,
        ipController: state.ipController,
        portController: state.portController,
        typeController: state.typeController,
        serverPortController: state.serverPortController,
        serverIpController: state.serverIpController,
      );

      if (dataToPrint==null) {
        if (ref.context.mounted) {
          showSuccessMessage(ref.context, ref, 'Impresora agregada: ${moPrinter.name ?? ''} ${moPrinter.ip}:${moPrinter.port}');
        }
        return;
      }

      if (state.typeController.text.startsWith(PrinterState.PRINTER_TYPE_LASER) ||
          state.typeController.text.startsWith(PrinterState.PRINTER_TYPE_A4)) {
        if (state.serverIpController.text.isEmpty ||
            state.serverPortController.text.isEmpty ||
            state.nameController.text.isEmpty) {
          if (ref.context.mounted) {
            showWarningMessage(ref.context, ref, Messages.ERROR_SERVER);
            return;
          }
        }
        printPdfByDataType(ref, dataToPrint);



      } else if (state.typeController.text.startsWith(PrinterState.PRINTER_TYPE_POS)) {


        printPOSByDataType(ref, dataToPrint: dataToPrint);

      } else if (state.typeController.text.startsWith('ZPL') ||
          state.typeController.text.startsWith('LABEL')) {

        printZplDirectOrConfigureByDataType(ref, dataToPrint);


      } else if (state.typeController.text.startsWith('TSPL') ||
          state.typeController.text.startsWith('TPL')) {
        printTsplDirectOrConfigureByDataType(ref, dataToPrint);

      } else {
        if (ref.context.mounted) {
          showErrorMessage(ref.context, ref, '${Messages.NOT_ENABLED} ${state.typeController.text}');
        }
      }
    } else {
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


  String get scannedData =>'${state.ipController.text}:${state.portController.text}:${state.typeController.text}:${state.nameController.text}:END';




  void printPdfByDataType(WidgetRef ref, dataToPrint) {
    if (dataToPrint is MovementAndLines) {
      printMovementAndLinesToCupsPdf(ref);
    }
    if(ref.context.mounted) {
      String message = Messages.NOT_IMPLEMENTED_YET;
      showWarningCenterToast(ref.context, message);
    }
  }

  Future<void> printPOSByDataType(WidgetRef ref, {dynamic dataToPrint}) async {
    if(dataToPrint is MovementAndLines){
      await printMovementReceiptWithQr(ref, dataToPrint);
    }
    if(ref.context.mounted) {
      String message = Messages.NOT_IMPLEMENTED_YET;
      showWarningCenterToast(ref.context, message);
    }
  }


  void printZplDirectOrConfigureByDataType(WidgetRef ref,
      dynamic dataToPrint) {
    if(dataToPrint is MovementAndLines) {
      printMovementZplDirectOrConfigure(ref, dataToPrint);
      return;
    }
    if(dataToPrint is List<IdempiereLocator>) {
      printListLocatorZplDirectOrConfigure(ref, dataToPrint);
      return;
    }
    if(ref.context.mounted) {
      String message = Messages.NOT_IMPLEMENTED_YET;
      showWarningCenterToast(ref.context, message);
    }

  }

  void printTsplDirectOrConfigureByDataType(WidgetRef ref,
      dynamic dataToPrint) {

    if(dataToPrint is MovementAndLines) {
      printMovementTsplDirectOrConfigure(ref, dataToPrint);
    }
    if(ref.context.mounted) {
      String message = Messages.NOT_IMPLEMENTED_YET;
      showWarningCenterToast(ref.context, message);
    }

  }
  Future<void> printDirectly({required Uint8List bytes,required WidgetRef ref,dynamic dataToPrint}) async {
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
      case PrinterState.PRINTER_TYPE_LASER:

        MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
        final image = await imageLogo;
        final pdfBytes = await generateMovementDocument(movementAndLines, image);
        String cupsServiceUrl = Memory.URL_CUPS_SERVER;
        if(state.serverPortController.text.isNotEmpty && state.serverIpController.text != ''
            && state.nameController.text != ''){
          cupsServiceUrl = Memory.getUrlCupsServerWithPrinter(ip:state.serverPortController.text,
              port:state.serverPortController.text, printerName:state.nameController.text);
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




}





// Proveedor para acceder al Notifier
final printerScanNotifierProvider = StateNotifierProvider<PrinterScanNotifier, PrinterState>((ref) {
  return PrinterScanNotifier();
});
