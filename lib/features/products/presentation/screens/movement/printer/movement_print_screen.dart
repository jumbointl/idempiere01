import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import 'printer_provider.dart';
import 'printer_type.dart';
import 'movement_pdf_generator.dart'; // Tu método para generar el PDF

class MovementPrintScreen extends ConsumerWidget {
  MovementPrintScreen({super.key,required this.movementAndLines, required this.argument,});

  final ipController = TextEditingController();
  final nameController = TextEditingController();
  final portController = TextEditingController();
  final String argument;
  final MovementAndLines movementAndLines;

  Future<Uint8List> get image async {
    final ByteData bytes = await rootBundle.load('assets/images/logo-monalisa.jpg');
    return bytes.buffer.asUint8List();
  }

  Future<void> printPdf(WidgetRef ref, {required bool direct}) async {
    MovementAndLines movementAndLines = MovementAndLines.fromJson(jsonDecode(argument));
    final image = await this.image;
    final pdfBytes = await generateMovementDocument(movementAndLines, image);
    direct ?  ref.read(printerProvider.notifier).printDirectly(bytes: pdfBytes)
        : await Printing.sharePdf(bytes: pdfBytes, filename: 'documento.pdf');
  }
  Future<void> openPrintDialog(WidgetRef ref,) async{
    MovementAndLines movementAndLines = MovementAndLines.fromJson(jsonDecode(argument));
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
  Widget build(BuildContext context, WidgetRef ref) {

    MovementAndLines m = MovementAndLines.fromJson(jsonDecode(argument));


    final printerState = ref.watch(printerProvider);


    ipController.text = printerState.ip;
    portController.text = printerState.port.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(Messages.OPTIONS),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: Messages.NAME),
                onChanged: ref.read(printerProvider.notifier).setName,
              ),
              TextField(
                controller: ipController,
                decoration: InputDecoration(labelText: Messages.IP),
                onChanged: ref.read(printerProvider.notifier).setIp,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: portController,
                decoration: InputDecoration(labelText: Messages.PORT),
                keyboardType: TextInputType.number,
                onChanged: ref.read(printerProvider.notifier).setPort,
              ),
              const SizedBox(height: 20),
              // Widget para seleccionar el tipo de impresión
              DropdownButton<PrinterType>(
                value: printerState.printType,
                onChanged: (PrinterType? newValue) {
                  if (newValue != null) {
                    ref.read(printerProvider.notifier).setPrintType(newValue);
                  }
                },
                items: PrinterType.values.map<DropdownMenuItem<PrinterType>>((PrinterType type) {
                  return DropdownMenuItem<PrinterType>(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
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
    );
  }
}
