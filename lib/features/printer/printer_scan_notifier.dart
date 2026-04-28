import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_net_printer/flutter_net_printer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisapy_features/printer/helpers/printer_utils.dart';
import 'package:monalisapy_features/printer/printable/pdf_printable.dart';
import 'package:monalisapy_features/printer/printable/pos_receipt_printable.dart';
import 'package:monalisapy_features/printer/printable/printable.dart';
import 'package:monalisapy_features/printer/printable/tspl_printable.dart';
import 'package:monalisapy_features/printer/printable/zpl_printable.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import '../products/presentation/providers/common_provider.dart';
import '../shared/data/memory.dart';
import '../shared/data/messages.dart';
import 'package:monalisapy_features/printer/helpers/lite_ipp_print.dart';
import 'package:monalisapy_features/printer/models/mo_printer.dart';
import 'cups_printer.dart';

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
  /// Dispatcher: route a print job to the right CUPS handler. The job
  /// must implement [PdfPrintable] — the host wraps its business entity in
  /// a printable so this layer stays type-agnostic.
  Future<void> printToCupsPdf(WidgetRef ref, dynamic data) async {
    if (data is PdfPrintable) {
      return printPdfPrintableToCupsPdf(ref, data);
    }
    if (ref.context.mounted) {
      showWarningCenterToast(ref.context, Messages.NOT_IMPLEMENTED_YET);
    }
  }

  /// Generic CUPS PDF dispatcher driven by [PdfPrintable]. Pulls bytes
  /// and document number from the printable abstraction so it works for
  /// any host type (MInOut, Movement, or future entities).
  Future<void> printPdfPrintableToCupsPdf(
      WidgetRef ref, PdfPrintable printable) async {
    if (state.serverIpController.text.isEmpty ||
        state.nameController.text.isEmpty ||
        state.serverPortController.text.isEmpty) {
      showErrorMessage(ref.context, ref, Messages.ERROR_EMPTY_FIELDS);
      return;
    }

    final isPrinting = ref.read(isPrintingProvider.notifier);
    isPrinting.state = true;

    try {
      final image = await imageLogo;
      final pdfBytes = await printable.generatePdfBytes(logoBytes: image);

      final documentNo = printable.documentNo;
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
              ? showSuccessMessage(ref.context, ref,
                  '${Messages.PRINT_SUCCESS} $nodeUrl $printerName')
              : showErrorMessage(ref.context, ref,
                  '${Messages.NETWORK_ERROR} $nodeUrl $printerName');
        }
      }

      await Future.delayed(const Duration(seconds: 1));
      debugPrint('Impresion finalizada (${printable.runtimeType})');
    } catch (e, st) {
      debugPrint('printPdfPrintableToCupsPdf ERROR: $e\n$st');
      if (ref.context.mounted) {
        showErrorMessage(ref.context, ref, 'Error: $e');
      }
    } finally {
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
    if (dataToPrint is PdfPrintable) {
      printToCupsPdf(ref, dataToPrint);
      return;
    }
    if (ref.context.mounted) {
      showWarningCenterToast(ref.context, Messages.NOT_IMPLEMENTED_YET);
    }
  }

  Future<void> printPOSByDataType(WidgetRef ref, {dynamic dataToPrint}) async {
    if (dataToPrint is PosReceiptPrintable) {
      await dataToPrint.printPosReceipt(ref);
      return;
    }
    if (ref.context.mounted) {
      showWarningCenterToast(ref.context, Messages.NOT_IMPLEMENTED_YET);
    }
  }


  void printZplDirectOrConfigureByDataType(WidgetRef ref,
      dynamic dataToPrint) {
    if (dataToPrint is ZplPrintable) {
      dataToPrint.printZpl(ref);
      return;
    }
    if (ref.context.mounted) {
      showWarningCenterToast(ref.context, Messages.NOT_IMPLEMENTED_YET);
    }
  }

  void printTsplDirectOrConfigureByDataType(WidgetRef ref,
      dynamic dataToPrint) {
    if (dataToPrint is TsplPrintable) {
      dataToPrint.printTspl(ref);
      return;
    }
    if (ref.context.mounted) {
      showWarningCenterToast(ref.context, Messages.NOT_IMPLEMENTED_YET);
    }
  }
  /// Dispatcher used by [printDirectly] when the printer is A4/LASER and
  /// the document body must be generated as PDF and pushed to a CUPS-style
  /// sink. The host wraps its entity in a [PdfPrintable] so this layer
  /// stays type-agnostic.
  Future<void> sendPdfDirectByDataType(WidgetRef ref, dynamic data) async {
    if (data is PdfPrintable) {
      await sendPdfPrintableDirect(ref, data);
      return;
    }
    if (ref.context.mounted) {
      showWarningCenterToast(ref.context, Messages.NOT_IMPLEMENTED_YET);
    }
  }

  /// A4/LASER direct sender driven by [PdfPrintable]. Pulls the bytes from
  /// the abstraction.
  Future<void> sendPdfPrintableDirect(
      WidgetRef ref, PdfPrintable printable) async {
    final image = await imageLogo;
    final pdfBytes = await printable.generatePdfBytes(logoBytes: image);

    String cupsServiceUrl = Memory.URL_CUPS_SERVER;
    if (state.serverPortController.text.isNotEmpty &&
        state.serverIpController.text != '' &&
        state.nameController.text != '') {
      cupsServiceUrl = Memory.getUrlCupsServerWithPrinter(
        ip: state.serverPortController.text,
        port: state.serverPortController.text,
        printerName: state.nameController.text,
      );
    }
    final printerName = state.nameController.text == ''
        ? 'BR_HL_10003'
        : state.nameController.text;
    await sendPdfToNode(ref, pdfBytes, cupsServiceUrl, printerName);
  }

  Future<void> printDirectly({required Uint8List bytes,required WidgetRef ref,dynamic dataToPrint}) async {
    print('Intentando imprimir en ${state.ipController.text }:${state.portController.text} con tipo ${state.typeController.text}');

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
        await sendPdfDirectByDataType(ref, dataToPrint);
        break;

      default:
        if(ref.context.mounted) {
          showWarningMessage(ref.context, ref, Messages.NOT_ENABLED);
        }
        break;
    }

    await sendBytesDirectByDataType(
      ref: ref,
      bytes: bytes,
      port: port,
      data: dataToPrint,
    );
  }

  /// Raw-bytes leg of [printDirectly] (TCP socket via FlutterNetPrinter).
  /// The [data] is only used to tag log lines with the printable type.
  Future<void> sendBytesDirectByDataType({
    required WidgetRef ref,
    required Uint8List bytes,
    required int port,
    required dynamic data,
  }) async {
    final label = data is Printable ? data.runtimeType.toString() : 'unknown';
    await _sendBytesViaNetPrinter(bytes: bytes, port: port, label: label);
  }

  /// Shared transport: opens a FlutterNetPrinter session against the printer
  /// IP currently in [state] and writes [bytes]. The [label] only tags log
  /// lines so we can tell printable types apart in console output.
  Future<void> _sendBytesViaNetPrinter({
    required Uint8List bytes,
    required int port,
    required String label,
  }) async {
    final printer = FlutterNetPrinter();
    try {
      final connectedDevice = await printer.connectToPrinter(
        state.ipController.text,
        port,
        timeout: const Duration(seconds: 5),
      );

      if (connectedDevice != null) {
        print('[$label] Conexión exitosa a la impresora.');
        await printer.printBytes(data: bytes);
        print('[$label] Datos de impresión enviados.');
      } else {
        print('[$label] Error al conectar a la impresora.');
      }
    } catch (e) {
      print('[$label] Error al imprimir directamente: $e');
    }
  }




}





// Proveedor para acceder al Notifier
final printerScanNotifierProvider = StateNotifierProvider<PrinterScanNotifier, PrinterState>((ref) {
  return PrinterScanNotifier();
});
