import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/mo_printer.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../products_home_provider.dart';
import '../provider/new_movement_provider.dart';
import 'cups_printer.dart';
import 'movement_pdf_generator.dart';
import 'printer_scan_notifier.dart';

class PrinterSetupScreen extends ConsumerStatefulWidget {
  final String argument;
  MovementAndLines movementAndLines;

  PrinterSetupScreen({
    super.key,
    required this.movementAndLines,
    required this.argument,
  });

  @override
  _PrinterSetupScreenState createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends ConsumerState<PrinterSetupScreen> {
  // El FocusNode es esencial para que KeyboardListener funcione.
  final FocusNode _focusNode = FocusNode();
  late MovementAndLines movementAndLines;
  late var actionScan;
  final int actionTypeInt = Memory.ACTION_FIND_PRINTER_BY_QR;
  int movementId = -1;
  String scannedData='';
  late var isPrinting;

  String get cupsPrinterName {
    return 'BR_HL_10003';
  }


  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Manejador del evento de teclado
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Escuchar solo el evento KeyDown para evitar duplicados
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        // Cuando se presiona Enter, procesamos los datos acumulados
        if (scannedData.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 100), () {
            print('Escaneado: $scannedData');
            ref.read(printerProvider.notifier).updateFromScan(scannedData, ref);
            // Limpiar los datos escaneados para el próximo escaneo
            scannedData = '';
          });
        }
        // Devolver handled para evitar que el evento se propague
        return KeyEventResult.handled;
      } else if (event.logicalKey.keyLabel.isNotEmpty && event.character != null) {
        // Acumular los caracteres de las teclas presionadas
        scannedData += event.character!;
        return KeyEventResult.handled;
      }
    }
    // Devolver ignored para permitir que el evento continúe propagándose
    return KeyEventResult.ignored;
  }


  // Iniciar escaneo con cámara
  Future<void> _startCameraScan(BuildContext context, WidgetRef ref) async {
    if (await Permission.camera.request().isGranted) {
       if(ref.context.mounted){
         String? result= await SimpleBarcodeScanner.scanBarcode(
           ref.context,
           barcodeAppBar: BarcodeAppBar(
             appBarTitle: Messages.SCANNING,
             centerTitle: false,
             enableBackButton: true,
             backButtonIcon: Icon(Icons.arrow_back_ios),
           ),
           isShowFlashIcon: true,
           delayMillis: 300,
           cameraFace: CameraFace.back,
         );
         if (result != null) {
           Future.delayed(const Duration(milliseconds: 100), () {
           });
           print('Escaneado: $result');
           ref.read(printerProvider.notifier).updateFromScan(result,ref);
         } else {
           if(ref.context.mounted) showWarningMessage(ref.context, ref, Messages.ERROR_SCAN);
         }
       }

    } else {
      if(ref.context.mounted){
        showWarningMessage(ref.context, ref, Messages.ERROR_CAMERA_PERMISSION);
      }

    }
  }



  Future<void> printPdf(WidgetRef ref, {required bool direct}) async {
    MovementAndLines movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    final image = await imageLogo;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    direct ?  ref.read(printerProvider.notifier).printDirectly(bytes: pdfBytes,ref: ref)
        : await Printing.sharePdf(bytes: pdfBytes, filename: 'documento.pdf');
  }
/*  Future<void> printPdfToCUPS(WidgetRef ref) async {
    MovementAndLines movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    final image = await imageLogo;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    final cupsServiceUrl = Memory.URL_CUPS_SERVER;
    String printerName = cupsPrinterName;
    await sendPdfToNode(ref,pdfBytes, cupsServiceUrl,printerName,);
  }*/
  Future<void> openPrintDialog(WidgetRef ref,) async{
    MovementAndLines movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    final image = await imageLogo;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        // No necesitas llamar a generateDocument aquí, ya tienes los bytes
        return pdfBytes;
      },
    );
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //_focusNode.requestFocus();
      Future.delayed(Duration(milliseconds: 50), () {
        movementAndLines = ref.read(movementAndLinesProvider.notifier).state ;
        print('movementAndLines: ${movementAndLines.documentNo ?? '--null'}');
        if(!widget.movementAndLines.hasMovement){
          widget.movementAndLines = movementAndLines;

        }

        /*var printerState = ref.read(printerProvider);
        String ip = printerState.ipController.text.trim();
        String port = printerState.portController.text.trim();
        String type = printerState.typeController.text.trim();
        String name = printerState.nameController.text.trim();
        if(ip.isEmpty || port.isEmpty || type.isEmpty || name.isEmpty){
           return;
        }
        MOPrinter printer = MOPrinter(name: name,ip: ip,port: port,type: type);
        askForPrint(ref,printer);*/

      });
    });
  }

  @override
  Widget build(BuildContext context) {
    movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));

    isPrinting = ref.watch(isPrintingProvider.notifier);
    actionScan = ref.watch(actionScanProvider.notifier);
    movementId = movementAndLines.id ?? -1;
    final printerState = ref.watch(printerProvider);

    // El FocusNode debe ser solicitado explícitamente después de que el widget se construya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    return KeyboardListener(
      focusNode: _focusNode, // Usar un FocusNode separado para el listener
      onKeyEvent: (event) => _handleKeyEvent(_focusNode, event),
      child: Scaffold(

        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading:IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async =>
              {
                popScopeAction(context, ref),

              }
            //
          ),
          title: Text(Messages.SELECT_A_PRINTER),
        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {

            if (didPop) {
              return;
            }
            popScopeAction(context, ref);
          },
          child: isPrinting.state ? LinearProgressIndicator() : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startCameraScan(context, ref),
                    icon: const Icon(Icons.camera),
                    label: Text(Messages.OPEN_CAMERA),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: TextField(
                          controller: printerState.ipController,
                          enabled: false,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: Messages.IP),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: TextField(
                          enabled: false,
                          keyboardType: TextInputType.number,
                          controller: printerState.portController,
                          decoration: InputDecoration(labelText: Messages.PORT),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: TextField(
                          controller: printerState.nameController,
                          enabled: false,
                          keyboardType: TextInputType.none,
                          decoration:  InputDecoration(labelText: Messages.NAME),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: TextField(
                          enabled: false,
                          keyboardType: TextInputType.text,
                          controller: printerState.typeController,
                          decoration: InputDecoration(labelText: Messages.TYPE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: TextField(
                          controller: printerState.serverIpController,
                          enabled: false,
                          keyboardType: TextInputType.none,
                          decoration:  InputDecoration(labelText: Messages.SERVER),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: TextField(
                          enabled: false,
                          keyboardType: TextInputType.none,
                          controller: printerState.serverPortController,
                          decoration: InputDecoration(labelText: Messages.SERVER_PORT),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /*ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ref.read(directPrintWithLastPrinterProvider.notifier).state
                          ? Colors.green
                          : null,
                    ),
                    onPressed: () async {
                       savePrinter(ref);
                    },
                    child: Text(Messages.DIRECT_PRINT),
                  ),*/
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ref.read(lastPrinterProvider.notifier).state != null
                          ? Colors.green
                          : null,
                    ),
                    onPressed: () async {
                      String ip = printerState.ipController.text.trim();
                      String port = printerState.portController.text.trim();
                      String type = printerState.typeController.text.trim();
                      String name = printerState.nameController.text.trim();
                      String serverIp = printerState.serverIpController.text.trim();
                      String serverPort = printerState.serverPortController.text.trim();

                      if(ip.isEmpty || port.isEmpty || type.isEmpty){
                        showWarningMessage(context, ref, Messages.ERROR_SAVE_PRINTER);
                        return;
                      }
                      String qrData = '$ip:$port:$type';
                      if(name.isNotEmpty) {
                        name = '$ip:$port:$type';
                        qrData = '$qrData:$name';
                      }

                      if(serverIp.isNotEmpty){
                        qrData = '$qrData:$serverIp';
                      }
                      if(serverPort.isNotEmpty){
                        qrData = '$qrData:$serverPort';
                      }
                      print('QR Data: $qrData');
                      ref.read(printerProvider.notifier).updateFromScan(qrData, ref);
                    },
                    child: Text(Messages.PRINT),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      openPrintDialog(ref);
                    },
                    child: Text(Messages.SELECT_A_PRINTER),
                  ),
                  /*ElevatedButton(
                    onPressed: () async {
                      showWarningMessage(context, ref, Messages.NOT_ENABLED);
                      //to do
                      //await printPdf(ref, direct: true);
                    },
                    child: Text('POS/LABEL'),
                  ),*/
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: () async { await printPdf(ref, direct: false); },
                      child: Text(Messages.SHARE)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void savePrinter(WidgetRef ref) {

    final printerState = ref.read(printerProvider);
    if(printerState.nameController.text.isEmpty || printerState.ipController.text.isEmpty
        || printerState.portController.text.isEmpty || printerState.typeController.text.isEmpty){
      showWarningMessage(ref.context, ref, Messages.ERROR_SAVE_PRINTER);
      return;
    }
    MOPrinter printer = MOPrinter();
    printer.name = printerState.nameController.text;
    printer.ip = printerState.ipController.text;
    printer.port = printerState.portController.text;
    printer.type = printerState.typeController.text;
    ref.read(lastPrinterProvider.notifier).state = printer;
    ref.read(directPrintWithLastPrinterProvider.notifier).update((state) => !state);


  }

  void askForPrint(WidgetRef ref, MOPrinter printer) {
    if(printer.name==null){
      return ;
    }
    String title = Messages.PRINT_TO_LAST_PRINTER;
    String message = printer.name!;
     bool directPrint = true;
    AwesomeDialog(
        context: ref.context,
        headerAnimationLoop: false,
        dialogType: DialogType.noHeader,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Center(
            child: Column(
              spacing: 10,
              children: [
                Text(title, style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
                Text(message, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        title: title,
        desc: message,
        autoDismiss: true,
        autoHide: Duration(seconds: 2),
        btnCancelText: Messages.CANCEL,
        btnOkText: Messages.OK,
        btnOkOnPress: () {
          directPrint = true;
        },
        btnCancelOnPress: () {
          directPrint = false;
          ref.read(directPrintWithLastPrinterProvider.notifier).state = false;
          return;
        }
    ).show().then((value) {
      if(!directPrint) return;
      var printerState = ref.read(printerProvider);
      String ip = printerState.ipController.text.trim();
      String port = printerState.portController.text.trim();
      String type = printerState.typeController.text.trim();
      String name = printerState.nameController.text.trim();
      if(ip.isEmpty || port.isEmpty || type.isEmpty || name.isEmpty){
        showWarningMessage(context, ref, Messages.ERROR_SAVE_PRINTER);
        return;
      }

      String qrData = '$ip:$port:$type:$name:END';
      print('QR Data: $qrData');
      ref.read(printerProvider.notifier).updateFromScan(qrData, ref);
    });
  }

  void popScopeAction(BuildContext context, WidgetRef ref) async {
    print('popScopeAction----------------------------');
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;
    actionScan.state = Memory.ACTION_FIND_MOVEMENT_BY_ID;
    context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$movementId');
  }
}

