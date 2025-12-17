import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';

class MovementPrintService {
  static const Map<int, pw.TableColumnWidth> tableWidths = {
    0: pw.FractionColumnWidth(1 / 28),
    1: pw.FractionColumnWidth(3 / 28),
    2: pw.FractionColumnWidth(3 / 28),
    3: pw.FractionColumnWidth(2 / 28),
    4: pw.FractionColumnWidth(3 / 28),
    5: pw.FractionColumnWidth(3 / 28),
    6: pw.FractionColumnWidth(3 / 28),
    7: pw.FractionColumnWidth(3 / 28),
    8: pw.FractionColumnWidth(3 / 28),
    9: pw.FractionColumnWidth(3 / 28),
  };

  void printMovementAndLines(BuildContext context, WidgetRef ref, MovementAndLines data) async {

    if(data.movementLines == null || data.movementLines!.isEmpty){
      if(ref.context.mounted){
        AwesomeDialog(
          context: ref.context,
          dialogType: DialogType.info,
          animType: AnimType.scale,
          title: Messages.LINES,
          desc: Messages.ERROR_MOVEMENT_LINE,
          autoHide: const Duration(seconds: 3),
          btnOkOnPress: () {},
          btnOkColor: themeColorSuccessful,
        ).show();
        return;
      } else {

        if(ref.context.mounted){
          final snackBar = SnackBar(content: Text(Messages.ERROR_MOVEMENT_LINE));
          ScaffoldMessenger.of(ref.context).showSnackBar(snackBar);
        }

        return;
      }


    }
    final double titleFontSize = 16;
    final double defaultFontSize = 10;
    final pdf = pw.Document();
    final image = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo-monalisa.jpg')).buffer.asUint8List(),
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          final double contentWidth = PdfPageFormat.a4.landscape.width -
              PdfPageFormat.a4.landscape.marginLeft -
              PdfPageFormat.a4.landscape.marginRight;
          double totalQty = 0;
          double totalSubtotal = 0;
          data.movementLines?.forEach((line) {
            totalQty += line.movementQty ?? 0;
            totalSubtotal += ((line.movementQty ?? 0) * (line.priceActual ?? 0));
          });



          return [
            pw.Column(
              children: [
                // Body
                pw.Container(
                  padding: pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // Para distribuir el espacio entre los elementos
                    children: [
                      pw.Image(image, width: 150), // Imagen con ancho fijo
                      pw.SizedBox(width: 10), // Separador
                      pw.Column(
                        children: [
                          pw.Text('Material Movement', style: pw.TextStyle(fontSize: titleFontSize)),
                          pw.Text(data.documentNo ?? '', style: pw.TextStyle(fontSize: titleFontSize)),
                        ],
                      ),
                      pw.Spacer(), // Ocupa el espacio restante
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Document No: ${data.documentNo ?? ''}', style: pw.TextStyle(fontSize: defaultFontSize)),
                          pw.Text('Date: ${data.movementDate != null ? data.movementDate! : ''}',
                              style: pw.TextStyle(fontSize: defaultFontSize)),
                        ],
                      ),
                      pw.SizedBox(width: 10), // Separador
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: data.documentNo ?? '',
                        width: 50,
                        height: 50,
                      ),
                    ],
                  ),
                ),
                // Body Title
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Table(
                    columnWidths: tableWidths,
                    border: pw.TableBorder.all(color: PdfColors.grey),
                    children: [
                      // Encabezado de la tabla.
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Text('Line', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          pw.Text('SKU', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          pw.Text('UPC', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          pw.Text('QTY', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Product', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          pw.Text('From', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          pw.Text('To', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Attribute', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Price', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Subtotal', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),

                      // Filas de datos generadas dinámicamente.
                      ...data.movementLines!.map((line) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text('${line.line}', style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text(line.sKU ?? '', style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text(line.uPC ?? '', style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text('${line.movementQty}', style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text(line.mProductID?.identifier ?? '', style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text(line.mLocatorID?.value ?? '', style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text(line.mLocatorToID?.value ?? '', style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text(line.mAttributeSetInstanceID?.identifier ?? '', style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text('${line.priceActual}', style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: pw.Text(((line.movementQty ?? 0) * (line.priceActual ?? 0)).toStringAsFixed(2), style: pw.TextStyle(fontSize: defaultFontSize)),
                            ),
                          ],
                        );
                      }),
                      // **2. Fila de totales al final de la tabla.**
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.blueGrey100),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text('', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text('', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text('$totalQty', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text('', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text('', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text('', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text('', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text('', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text(totalSubtotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      // **Fila con el mensaje de estado.**
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.teal100),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: pw.Text(
                              'Document Status: Completo',
                              style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          // Rellenar las celdas restantes de esta fila con texto vacío.
                          ...List.generate(9, (index) => pw.Text('')),
                        ],
                      ),
                    ],
                  ),
                ),
                // Body Content

                // Totals section
                pw.Container(
                  padding: pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 7, child: pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: defaultFontSize))), // Spans Line, SKU, UPC
                      pw.Expanded(flex: 2, child: pw.Text(totalQty.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: defaultFontSize))), // QTY
                      pw.Expanded(flex: 18, child: pw.Container()), // Spans Product, From, To, Attribute, Price
                      pw.Expanded(flex: 3, child: pw.Text(totalSubtotal.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: defaultFontSize))), // Subtotal
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
