import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_net_printer/flutter_net_printer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/printer_utils.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/zpl/zpl_label_printer_100x150.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/common_provider.dart';
import '../pos/movement_direct_print.dart';
import '../provider/new_movement_provider.dart';
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

  Future<void> printToCupsPdf(WidgetRef ref) async {
    if(state.serverIpController.text.isEmpty || state.nameController.text.isEmpty
        || state.serverPortController.text.isEmpty){
      showErrorMessage(ref.context, ref, Messages.ERROR_EMPTY_FIELDS);
      return;
    }

    ref.read(isPrintingProvider.notifier).state = true;
    MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
    final image = await imageLogo;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    String cupsServiceUrl = Memory.URL_CUPS_SERVER;
    String documentNo = movementAndLines.documentNo ?? 'document-mo';
    if(state.serverPortController.text.startsWith('631')){
      cupsServiceUrl = Memory.getUrlCupsServerWithPrinter(ip :state.serverIpController.text,
          port:state.serverPortController.text,
        printerName:state.nameController.text);
      await printPdfToCUPSDirect(ref, pdfBytes, cupsServiceUrl,documentNo,LiteIppPrintOptions.PRINTER_ORIENTATION_LANDSCAPE);
    } else {
      cupsServiceUrl = Memory.getUrlNodeCupsServer(ip:state.serverIpController.text,
          port: state.serverPortController.text);
      await sendPdfToNode(ref,pdfBytes, cupsServiceUrl,state.nameController.text);
    }
    ref.read(isPrintingProvider.notifier).state = false;
  }

  // Actualizar los controladores con el resultado del escaneo
  Future<void> updateFromScan(String qrData, WidgetRef ref) async {
    clearControllers(); // Limpiar antes de actualizar
    print('QR Data: $qrData');
    final parts = qrData.split(':');
    if (parts.length >=3 ) {
      var printer = ref.read(lastPrinterProvider.notifier);
      MOPrinter moPrinter = MOPrinter();

      final ip = parts[0];
      moPrinter.ip = ip;
      final port = int.tryParse(parts[1]) ?? 0;
      moPrinter.port = port.toString();
      final typeString  = parts[2].toUpperCase();
      moPrinter.type = typeString;


      printer.state = MOPrinter();

      state.ipController.text = ip;
      state.portController.text = port.toString();
      state.typeController.text = typeString;
      if(parts.length>3){
        final name = parts[3];
        moPrinter.name = name;
        state.nameController.text = name;
      }
      if(parts.length>4){
        final serverIp = parts[4];
        moPrinter.serverIp = serverIp;
        state.serverIpController.text = serverIp;
      }
      if(parts.length>5){
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
      Future.delayed(const Duration(milliseconds:500), () {

      });

      if(state.typeController.text.startsWith(PrinterState.PRINTER_TYPE_LASER) ||
          state.typeController.text.startsWith(PrinterState.PRINTER_TYPE_A4)) {
        if(state.serverIpController.text.isEmpty || state.serverPortController.text.isEmpty
            || state.nameController.text.isEmpty){
          if (ref.context.mounted) {
            showWarningMessage(ref.context, ref, Messages.ERROR_SERVER);
            return ;

          }
        }

        printToCupsPdf(ref);
      } else if(state.typeController.text.startsWith(PrinterState.PRINTER_TYPE_POS)){
        print('----------------------------POS is type = POS? ${isPos(state.typeController.text)}');
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
        printReceiptWithQr(ref,state.ipController.text, port, movementAndLines);
      } else if(state.typeController.text.startsWith('ZPL') ||
              state.typeController.text.startsWith('LABEL') ){
        print('----------------------------ZPL');
        /*if(ref.context.mounted) {
          showWarningMessage(ref.context, ref, '${Messages.NOT_ENABLED} :${state.nameController} at '
              '${state.ipController.text}:${state.portController.text} type ${state.typeController.text}');
        }*/
        MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
        printZplDirectOrConfigure(ref,movementAndLines);

      } else if(state.typeController.text.startsWith('TSPL') || state.typeController.text.startsWith('TPL')){
        print('----------------------------TSPL');
        MovementAndLines movementAndLines = ref.read(movementAndLinesProvider);
        printTsplDirectOrConfigure(ref,movementAndLines);
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
      case PrinterState.PRINTER_TYPE_POS_INT:
      case PrinterState.PRINTER_TYPE_ZPL_INT:
      case PrinterState.PRINTER_TYPE_TSPL_INT:
        // Lógica común para estos tipos si es necesario
        showWarningMessage(ref.context, ref, Messages.NOT_ENABLED);
        break;
      case PrinterState.PRINTER_TYPE_A4__INT:
      case PrinterState.PRINTER_TYPE_LASER__INT:

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
      serverPortController: state.serverPortController,
      serverIpController: state.serverIpController,
    );
    if(state.typeController.text.startsWith(PrinterState.PRINTER_TYPE_LASER)) {
      printToCupsPdf(ref);
    } else if(state.typeController.text.startsWith(PrinterState.PRINTER_TYPE_POS)){
      print('----------------------------POS');
      if(ref.context.mounted) {
        showWarningMessage(ref.context, ref, '${Messages.NOT_ENABLED} : ${state.nameController} at '
            '${state.ipController.text}:${state.portController.text} type ${state.typeController.text}');
      }
    } else if(state.typeController.text.startsWith(PrinterState.PRINTER_TYPE_LABEL)){
      print('----------------------------LABEL');
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


  Future<void> printLabelTspl100x150NoLogo({
    required String ip,
    required int port,
    required dynamic movementAndLines, // tu MovementAndLines real
    required int rowsPerLabel,         // productos por etiqueta
    required int rowPerProductName,    // 1 o 2
    required int marginX,              // dots (203dpi => 8 dots/mm)
    required int marginY,              // dots
  }) async {
    // =============================
    // FÍSICO (203 dpi = 8 dots/mm)
    // =============================
    const int dotsPerMm = 8;
    const int labelWmm = 100;
    const int labelHmm = 150;
    const int gapMm = 3;

    // Restar 7mm al ancho de impresión: 7mm*8 = 56 dots
    const int reduceMm = 7;
    final int reduceDots = reduceMm * dotsPerMm; // 56

    // Label en dots
    final int pw = labelWmm * dotsPerMm; // 800
    final int ll = labelHmm * dotsPerMm; // 1200
    final int usableWidth = pw - reduceDots; // 744 (=93mm)

    // Header compacto: 25mm
    final int headerHeight = 25 * dotsPerMm; // 200
    // TableHeader: 10mm
    final int tableHeaderHeight = 10 * dotsPerMm; // 80
    // Footer: 10mm
    final int footerHeight = 10 * dotsPerMm; // 80

    // QR: 20mm aprox
    final int qrSize = 20 * dotsPerMm; // 160
    const int qrGap = 12; // separación QR->texto (dots)

    String safe(String s) => s
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('"', "'")
        .trim();

    // =============================
    // DATOS HEADER
    // =============================
    final String qrData = safe(movementAndLines.documentNumber ?? '');
    final String documentNumber = safe(movementAndLines.documentNumber ?? '');
    final String date = safe(movementAndLines.movementDate ?? '');
    final String documentStatus = safe(movementAndLines.documentStatus ?? '');
    final String company = safe(movementAndLines.cBPartnerID?.identifier ?? '');
    final String title = safe(movementAndLines.documentMovementTitle ?? '');

    // =============================
    // LINES
    // =============================
    final List<dynamic> lines =
    (movementAndLines.movementLines ?? const <dynamic>[]) as List<dynamic>;

    final int totalPages =
    lines.isEmpty ? 1 : ((lines.length + rowsPerLabel - 1) ~/ rowsPerLabel);

    // Socket
    final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

    for (int page = 0; page < totalPages; page++) {
      final int start = page * rowsPerLabel;
      final int end = min<int>(start + rowsPerLabel, lines.length);
      final List<dynamic> slice = lines.isEmpty ? <dynamic>[] : lines.sublist(start, end);

      final sb = StringBuffer();

      // =============================
      // TSPL SETUP
      // =============================
      sb.writeln('SIZE $labelWmm mm,$labelHmm mm');
      sb.writeln('GAP $gapMm mm,0 mm');
      sb.writeln('DENSITY 12');   // ajusta 8..15 según etiqueta
      sb.writeln('SPEED 4');      // ajusta si necesitas
      sb.writeln('DIRECTION 1');  // 1 normal
      sb.writeln('REFERENCE 0,0');
      sb.writeln('CLS');

      // =========================================================
      // HEADER TSPL (25mm) - QR IZQUIERDA + TEXTOS DERECHA
      // =========================================================
      final int qrX = marginX;
      final int qrY = marginY;

      // QRCODE x,y,ECC,cell,mode,rotation,"data"
      // cell=6 suele dar tamaño cercano a 20mm (depende versión/encoding)
      // si te queda más grande/pequeño: sube/baja cell 5..7
      sb.writeln('QRCODE $qrX,$qrY,L,6,A,0,"$qrData"');

      // Área de texto a la derecha del QR dentro del ancho usable (744)
      final int textX = marginX + qrSize + qrGap;
      final int textW = usableWidth - qrSize - qrGap; // 744-160-12 = 572

      // Fila 1: documentNumber (derecha, grande)
      // BLOCK x,y,width,height,font,rotation,xmul,ymul,space,align,"text"
      // align: 0 left, 1 center, 2 right
      sb.writeln(
          'BLOCK $textX,${marginY + 4},$textW,40,"0",0,2,2,0,2,"$documentNumber"'
      );

      // Fila 2: date (center) + status (right)
      final int halfW = (textW / 2).round();
      sb.writeln(
          'BLOCK $textX,${marginY + 56},$halfW,30,"0",0,1,1,0,1,"$date"'
      );
      sb.writeln(
          'BLOCK ${textX + halfW},${marginY + 56},$halfW,30,"0",0,1,1,0,2,"$documentStatus"'
      );

      // Fila 3: company (derecha)
      sb.writeln(
          'BLOCK $textX,${marginY + 88},$textW,30,"0",0,1,1,0,2,"$company"'
      );

      // Fila 4: title (derecha)
      sb.writeln(
          'BLOCK $textX,${marginY + 120},$textW,34,"0",0,1,1,0,2,"$title"'
      );

      // Línea separadora header->tabla
      sb.writeln('BAR $marginX,${marginY + headerHeight - 2},$usableWidth,2');

      // =========================================================
      // TABLE HEADER (10mm)
      // =========================================================
      int y = marginY + headerHeight + 8;

      sb.writeln('TEXT $marginX,$y,"0",0,1,1,"UPC/SKU"');
      sb.writeln('TEXT ${marginX + usableWidth - 260},$y,"0",0,1,1,"HASTA/DESDE"');
      y += 24;
      sb.writeln('TEXT $marginX,$y,"0",0,1,1,"ATTRIBUTO"');
      sb.writeln('TEXT ${marginX + usableWidth - 200},$y,"0",0,1,1,"CANTIDAD"');

      final int yTableEnd = marginY + headerHeight + tableHeaderHeight;
      sb.writeln('BAR $marginX,$yTableEnd,$usableWidth,2');

      // =========================================================
      // BODY
      // =========================================================
      y = yTableEnd + 10;

      const int linePitch = 32;
      final int nameLines = rowPerProductName.clamp(1, 2);

      for (final r in slice) {
        final upc = safe(r.uPC ?? '');
        final sku = safe(r.sKU ?? '');
        final to = safe(r.locatorToName ?? '');
        final from = safe(r.locatorFromName ?? '');
        final atr = safe(r.attributeName ?? '--');
        final product = safe(r.productNameWithLine ?? '');
        final qty = ((r.movementQty as num?)?.toInt() ?? 0).toString();

        // Col derecha (to/from) alineada a la derecha con BLOCK
        final int rightBlockX = marginX + usableWidth - 420;

        // UPC + TO
        sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$upc"');
        sb.writeln('BLOCK $rightBlockX,$y,420,30,"0",0,1,1,0,2,"$to"');
        y += linePitch;

        // SKU + FROM
        sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$sku"');
        sb.writeln('BLOCK $rightBlockX,$y,420,30,"0",0,1,1,0,2,"$from"');
        y += linePitch;

        // ATR
        sb.writeln('TEXT $marginX,$y,"0",0,1,1,"$atr"');
        y += linePitch;

        // PRODUCT (1 o 2 líneas) + QTY grande derecha
        // Reservamos 160 dots para qty grande
        final int productW = usableWidth - 160;

        // Alto del bloque product: 1 línea ~32, 2 líneas ~64
        final int productH = linePitch * nameLines;

        sb.writeln(
            'BLOCK $marginX,$y,$productW,$productH,"0",0,1,1,0,0,"$product"'
        );

        sb.writeln(
            'BLOCK ${marginX + usableWidth - 140},${y - 6},140,60,"0",0,2,2,0,2,"$qty"'
        );

        y += productH;

        // separador
        sb.writeln('BAR $marginX,$y,$usableWidth,1');
        y += 10;
      }

      // =========================================================
      // FOOTER (10mm) - solo page count a la derecha (como tu versión)
      // =========================================================
      final int yFooterLine = ll - marginY - footerHeight;
      final int yFooterText = yFooterLine + 20;

      sb.writeln('BAR $marginX,$yFooterLine,$usableWidth,2');
      sb.writeln(
          'BLOCK ${marginX + usableWidth - 120},$yFooterText,120,30,"0",0,1,1,0,2,"${page + 1}/$totalPages"'
      );

      // Imprime 1 etiqueta
      sb.writeln('PRINT 1,1');

      socket.add(utf8.encode(sb.toString()));
    }

    await socket.flush();
    await socket.close();
  }

}





// Proveedor para acceder al Notifier
final printerScanProvider = StateNotifierProvider<PrinterScanNotifier, PrinterState>((ref) {
  return PrinterScanNotifier();
});
