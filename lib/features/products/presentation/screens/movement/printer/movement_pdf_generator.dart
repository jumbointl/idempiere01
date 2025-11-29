import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> generateMovementDocument(MovementAndLines data, Uint8List imageBytes) async {
  final pdf = pw.Document();
  final defaultFontSize = 8.0;
  final titleFontSize = 16.0;
  final pwImage = pw.MemoryImage(imageBytes);
  // Calcular los totales antes de construir la tabla.
  final totalQty = data.movementLines!.fold(0, (sum, line) => sum + (line.movementQty ?? 0).toInt());
  final totalSubtotal = data.movementLines!.fold(0.0, (sum, line) => sum + ((line.movementQty ?? 0) * (line.priceActual ?? 0)));
  String documentStatus = data.docStatus?.id ?? '';
  documentStatus =  MemoryProducts.getDocumentStatusById(documentStatus);

// 1 milímetro equivale a aproximadamente 2.83 puntos (1 pulgada = 72 puntos = 25.4 mm)
  const double pointPerMm = 2.8346456693; // 72 / 25.4

// Tu margen en milímetros
  const double marginInMm = 12.0;
  const double marginInPoint = marginInMm * pointPerMm/2;
  String title = data.documentMovementTitle ;
  String company = data.documentMovementOrganizationName ?? '';
  String address = data.documentMovementOrganizationAddress ?? '';



  // Ancho de las columnas de la tabla (basado en la suma de los flex: 28).
  final Map<int, pw.TableColumnWidth> tableWidths = {
    0: pw.FractionColumnWidth(0.9 / 28), // Line
    1: pw.FractionColumnWidth(2.5 / 28), // SKU
    2: pw.FractionColumnWidth(2.4 / 28), // UPC
    3: pw.FractionColumnWidth(2 / 28), // QTY
    4: pw.FractionColumnWidth(6 / 28), // Product
    5: pw.FractionColumnWidth(3.1 / 28), // From
    6: pw.FractionColumnWidth(3.1 / 28), // To
    7: pw.FractionColumnWidth(2 / 28), // Attribute
    8: pw.FractionColumnWidth(2.2 / 28), // Price
    9: pw.FractionColumnWidth(2.8 / 28), // Subtotal
  };

  // Agregar una página usando MultiPage para manejar la paginación.
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape, // Formato A4 horizontal.
      margin: pw.EdgeInsets.all(marginInPoint),


      // *** ENCABEZADO ***
      header: (pw.Context context) {
        return pw.Container(
          padding: pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Table(
            columnWidths: headerColumnWidths,
            children: [
              pw.TableRow(
                children: [
                  // Celda para la imagen
                  pw.Image(pwImage, width: 150),

                  // Celda para los títulos
                  pw.Column(
                    children: [
                      pw.Text(title, style: pw.TextStyle(fontSize: titleFontSize)),
                      //pw.Text(data.documentNo ?? '', style: pw.TextStyle(fontSize: titleFontSize)),
                    ],
                  ),

                  // Celda para los detalles del documento
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('No: ${data.documentNo ?? ''}', style: pw.TextStyle(fontSize: titleFontSize)),
                      pw.Text('${Messages.DATE}: ${data.movementDate != null ? data.movementDate!  : ''}',
                          style: pw.TextStyle(fontSize: titleFontSize)),
                    ],
                  ),

                  // Celda para el código QR
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: data.documentNo ?? '',
                    width: 50,
                    height: 50,
                  ),
                ],
              ),
            ],
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
            '${Messages.PAGE} ${context.pageNumber} ${Messages.OF} ${context.pagesCount}',
            style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold),
          ),
        );
      },

      // *** CUERPO (BODY) ***
      build: (pw.Context context) => [
        pw.SizedBox(height: 10),
    pw.Table(
      columnWidths: tableWidths,
      // 1. Eliminar los bordes verticales y solo mostrar los horizontales interiores.
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(width: 1, color: PdfColors.grey),
        top: pw.BorderSide(width: 1, color: PdfColors.grey), // Agregar borde superior
        bottom: pw.BorderSide(width: 1, color: PdfColors.grey), // Agregar borde inferior
      ),
      children: [
        // Encabezado de la tabla.
        pw.TableRow(
          //decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            // Las celdas de texto normales se alinean a la izquierda por defecto.
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Line', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
              ),

            ),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Text('SKU', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Text('UPC/EAN', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
            ),

            // 2. Alinear a la derecha los encabezados numéricos
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text(Messages.QUANTITY_SHORT, style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
              ),

            ),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Text(Messages.PRODUCT, style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Text(Messages.FROM, style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Text(Messages.TO, style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Text(Messages.ATTRIBUTE, style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
            ),

            // 2. Alinear a la derecha los encabezados numéricos
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text(Messages.PRICE, style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
              ),

            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text(Messages.LINE_AMOUNT, style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
              ),

            ),
          ],
        ),

        // Filas de datos generadas dinámicamente.
        ...data.movementLines!.map((line) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text((line.line ?? 0).toStringAsFixed(0), style: pw.TextStyle(fontSize: defaultFontSize)),
                ),

              ),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text(line.sKU ?? '', style: pw.TextStyle(fontSize: defaultFontSize)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text(line.uPC ?? '', style: pw.TextStyle(fontSize: defaultFontSize)),
              ),
              // 2. Alinear a la derecha los campos numéricos.
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('${line.movementQty ?? 0}', style: pw.TextStyle(fontSize: defaultFontSize)),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text((line.mProductID?.identifier ?? '').split('_').last, style: pw.TextStyle(fontSize: defaultFontSize)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text(line.mLocatorID?.value ?? line.mLocatorID?.identifier ??'', style: pw.TextStyle(fontSize: defaultFontSize)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text(line.mLocatorToID?.value ?? line.mLocatorToID?.identifier ??'', style: pw.TextStyle(fontSize: defaultFontSize)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text(line.mAttributeSetInstanceID?.identifier ?? '---', style: pw.TextStyle(fontSize: defaultFontSize)),
              ),
              // 2. Alinear a la derecha los campos numéricos.
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('${line.priceActual}', style: pw.TextStyle(fontSize: defaultFontSize)),
                ),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(((line.movementQty ?? 0) * (line.priceActual ?? 0)).toStringAsFixed(2), style: pw.TextStyle(fontSize: defaultFontSize)),
                ),
              ),
            ],
          );
        }),

        // Fila de totales.
        pw.TableRow(
          //decoration: pw.BoxDecoration(color: PdfColors.blueGrey100),
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
            // 2. Alinear a la derecha el total de cantidad.
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('$totalQty', style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
              ),
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
            // 2. Alinear a la derecha el total de subtotal.
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(totalSubtotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold)),
              ),
            ),
          ],
        ),

        /*// Fila con el mensaje de estado que ocupa todas las columnas.
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.teal100),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: pw.Align(
                alignment: pw.Alignment.centerLeft, // Alinea el texto a la izquierda
                child: pw.Text(
                  'Document Status: Completo',
                  style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            ...List.generate(9, (index) => pw.Text('')), // Rellena las celdas restantes
          ],
        ),*/

      ],
    ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                '${Messages.DOCUMENT_STATUS} : $documentStatus',
                style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                '${Messages.DATE}: ${DateTime.now().toLocal().toString().split('.').first}',
                style: pw.TextStyle(fontSize: defaultFontSize, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ]
        )// Espacio después de la tabla

        /*pw.SizedBox(height: 5),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${Messages.DATE}: ${DateTime.now().toLocal().toString()}', // Formatear la fecha y hora actual
            style: pw.TextStyle(fontSize: defaultFontSize),
          ),
        ),*/
      ],
    ),
  );

  return await pdf.save();
}
final Map<int, pw.TableColumnWidth> headerColumnWidths = {
  0: pw.FractionColumnWidth(4 / 20), // Imagen
  1: pw.FractionColumnWidth(4 / 20), // Título y documento
  2: pw.FractionColumnWidth(10 / 20), // Detalles del documento
  3: pw.FractionColumnWidth(2 / 20), // Código QR
};