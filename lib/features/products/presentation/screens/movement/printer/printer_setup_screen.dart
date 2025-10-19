import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/printer_type.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/qe_scan_page.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../providers/product_provider_common.dart';
import '../products_home_provider.dart';
import '../provider/new_movement_provider.dart';
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

  int movementId = -1;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Manejador del evento de teclado
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Escuchar solo el evento KeyDown para evitar duplicados
    if (event is KeyDownEvent) {
      // Usar LogicalKeyboardKey.enter
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        final printerState = ref.read(printerProvider);
        final qrData = printerState.nameController.text;
        if (qrData.isNotEmpty) {
          ref.read(printerProvider.notifier).updateFromScan(qrData);
        }
        // Devolver handled para evitar que el evento se propague
        return KeyEventResult.handled;
      }
    }
    // Devolver ignored para permitir que el evento continúe propagándose
    return KeyEventResult.ignored;
  }

  // Iniciar escaneo con cámara
  Future<void> _startCameraScan(BuildContext context, WidgetRef ref) async {
    if (await Permission.camera.request().isGranted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerPage(),
        ),
      );
      if (result != null) {
        ref.read(printerProvider.notifier).updateFromScan(result as String);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de cámara denegado')),
      );
    }
  }

  Future<Uint8List> get image async {
    final ByteData bytes = await rootBundle.load('assets/images/logo-monalisa.jpg');
    return bytes.buffer.asUint8List();
  }

  Future<void> printPdf(WidgetRef ref, {required bool direct}) async {
    MovementAndLines movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    final image = await this.image;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    direct ?  ref.read(printerProvider.notifier).printDirectly(bytes: pdfBytes,ref: ref)
        : await Printing.sharePdf(bytes: pdfBytes, filename: 'documento.pdf');
  }
  Future<void> openPrintDialog(WidgetRef ref,) async{
    MovementAndLines movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    final image = await this.image;
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
      /*print('widget.argument: ${widget.argument}');
      print('widget.movementAndLines: ${widget.movementAndLines.documentNo ?? '--null'}');
      print('movementAndLines: ${movementAndLines.documentNo ?? '--null'}');*/
      Future.delayed(Duration(milliseconds: 50), () {
        movementAndLines = ref.read(movementAndLinesProvider.notifier).state ;
        print('movementAndLines: ${movementAndLines.documentNo ?? '--null'}');
        if(!widget.movementAndLines.hasMovement){
          widget.movementAndLines = movementAndLines;

        }

      });
    });
  }

  @override
  Widget build(BuildContext context) {
    movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));

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
                ref.read(productsHomeCurrentIndexProvider.notifier).state =
                    Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN,
                actionScan.state = Memory.ACTION_FIND_MOVEMENT_BY_ID,
                context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$movementId')
              }
            //
          ),
          title: Text(Messages.PRINTER_SETUP),
        ),
        body: PopScope(
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              return;
            }
            ref.read(productsHomeCurrentIndexProvider.notifier).state =
                Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;
            actionScan.state = Memory.ACTION_FIND_MOVEMENT_BY_ID;
            context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$movementId');
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _startCameraScan(context, ref),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear con Cámara'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: printerState.nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: printerState.ipController,
                    decoration: const InputDecoration(labelText: 'Dirección IP'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: printerState.portController,
                    decoration: const InputDecoration(labelText: 'Puerto'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  // <--- DropdownButtonFormField en lugar de TextField
                  DropdownButtonFormField<PrinterType>(
                    initialValue: printerState.type,
                    decoration: InputDecoration(
                      labelText: Messages.PRINTER_TYPE,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (PrinterType? newValue) {
                      ref.read(printerProvider.notifier).setType(newValue);
                    },
                    items: PrinterType.values.map<DropdownMenuItem<PrinterType>>((PrinterType type) {
                      return DropdownMenuItem<PrinterType>(
                        value: type,
                        child: Text(type.name),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      openPrintDialog(ref);
                    },
                    child: Text(Messages.SELECT_A_PRINTER),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      showWarningMessage(context, ref, Messages.NOT_ENABLED);
                      //to do
                      //await printPdf(ref, direct: true);
                    },
                    child: Text('POS/LABEL'),
                  ),
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
}
