import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<Uint8List> generateDocument(data, image) async {
  final pdf = pw.Document();
  final defaultFontSize = 10.0;
  final titleFontSize = 16.0;

  // Calcular los totales antes de construir la tabla.
  final totalQty = data.movementLines!.fold(0, (sum, line) => sum + (line.movementQty ?? 0));
  final totalSubtotal = data.movementLines!.fold(0.0, (sum, line) => sum + ((line.movementQty ?? 0) * (line.priceActual ?? 0)));

  // Ancho de las columnas de la tabla (basado en la suma de los flex: 28).
  final Map<int, pw.TableColumnWidth> tableWidths = {
    0: pw.FractionColumnWidth(1 / 28), // Line
    1: pw.FractionColumnWidth(3 / 28), // SKU
    2: pw.FractionColumnWidth(3 / 28), // UPC
    3: pw.FractionColumnWidth(2 / 28), // QTY
    4: pw.FractionColumnWidth(3 / 28), // Product
    5: pw.FractionColumnWidth(3 / 28), // From
    6: pw.FractionColumnWidth(3 / 28), // To
    7: pw.FractionColumnWidth(3 / 28), // Attribute
    8: pw.FractionColumnWidth(3 / 28), // Price
    9: pw.FractionColumnWidth(3 / 28), // Subtotal
  };

  // Agregar una página usando MultiPage para manejar la paginación.
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape, // Formato A4 horizontal.

      // *** ENCABEZADO ***
      header: (pw.Context context) {
        final double contentWidth = PdfPageFormat.a4.landscape.width -
            PdfPageFormat.a4.landscape.marginLeft -
            PdfPageFormat.a4.landscape.marginRight;
        return pw.Container(
          padding: pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.SizedBox(
            width: contentWidth,
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Image(image, width: 150),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    children: [
                      pw.Text('Material Movement', style: pw.TextStyle(fontSize: titleFontSize)),
                      pw.Text(data.documentNo ?? '', style: pw.TextStyle(fontSize: titleFontSize)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 10,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Document No: ${data.documentNo ?? ''}', style: pw.TextStyle(fontSize: defaultFontSize)),
                      pw.Text('Date: ${data.movementDate != null ? data.movementDate! : ''}',
                          style: pw.TextStyle(fontSize: defaultFontSize)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: data.documentNo ?? '',
                    width: 50,
                    height: 50,
                  ),
                ),
              ],
            ),
          ),
        );
      },

      // *** PIE DE PÁGINA ***
      footer: (pw.Context context) {
        return pw.Container(
          padding: pw.EdgeInsets.all(5),
          alignment: pw.Alignment.centerRight, // Alinear el contenido a la derecha.
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold),
          ),
        );
      },

      // *** CUERPO (BODY) ***
      build: (pw.Context context) => [
        pw.SizedBox(height: 10),
        pw.Table(
          columnWidths: tableWidths,
          border: pw.TableBorder.all(color: PdfColors.grey),
          children: [
            // Encabezado de la tabla
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

            // Filas de datos
            ...data.movementLines!.map((line) {
              return pw.TableRow(
                children: [
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text('${line.line}', style: pw.TextStyle(fontSize: defaultFontSize))),
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(line.sKU ?? '', style: pw.TextStyle(fontSize: defaultFontSize))),
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(line.uPC ?? '', style: pw.TextStyle(fontSize: defaultFontSize))),
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text('${line.movementQty}', style: pw.TextStyle(fontSize: defaultFontSize))),
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(line.mProductID?.identifier ?? '', style: pw.TextStyle(fontSize: defaultFontSize))),
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(line.mLocatorID?.value ?? '', style: pw.TextStyle(fontSize: defaultFontSize))),
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(line.mLocatorToID?.value ?? '', style: pw.TextStyle(fontSize: defaultFontSize))),
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(line.mAttributeSetInstanceID?.identifier ?? '', style: pw.TextStyle(fontSize: defaultFontSize))),
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text('${line.priceActual}', style: pw.TextStyle(fontSize: defaultFontSize))),
                  pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(((line.movementQty ?? 0) * (line.priceActual ?? 0)).toStringAsFixed(2), style: pw.TextStyle(fontSize: defaultFontSize))),
                ],
              );
            }).toList(),

            // Fila de totales
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: [
                pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold))),
                ...List.generate(2, (index) => pw.Text('')),
                pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text('$totalQty', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold))),
                ...List.generate(5, (index) => pw.Text('')),
                pw.Padding(padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4), child: pw.Text(totalSubtotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold))),
              ],
            ),

            // Fila con el mensaje de estado
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
                ...List.generate(9, (index) => pw.Text('')),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  return await pdf.save();
}
