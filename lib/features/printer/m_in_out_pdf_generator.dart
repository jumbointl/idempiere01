import 'dart:typed_data';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Mirrors [generateMovementDocument] but works against the [MInOut] entity.
/// The MInOut Line model exposes [movementQty], [mLocatorId], [mLocatorToId],
/// [mProductId], [sku], [upc] and [mAttributeSetInstanceID]; price columns are
/// not available on m_inoutline so they're omitted in the table totals.
Future<Uint8List> generateMInOutDocument(
  MInOut data,
  Uint8List imageBytes,
) async {
  final pdf = pw.Document();
  const double defaultFontSize = 8.0;
  const double titleFontSize = 16.0;
  final pwImage = pw.MemoryImage(imageBytes);

  final lines = data.lines;
  final totalQty = lines.fold<int>(
    0,
    (sum, line) => sum + (line.movementQty ?? 0).toInt(),
  );

  String documentStatus = data.docStatus.id ?? '';
  documentStatus = MemoryProducts.getDocumentStatusById(documentStatus);

  // 1 mm ≈ 2.83 points (1 inch = 72 points = 25.4 mm)
  const double pointPerMm = 2.8346456693;
  const double marginInMm = 12.0;
  const double marginInPoint = marginInMm * pointPerMm / 2;

  final String docNo = data.documentNo ?? '';
  final String movementDate = data.movementDate != null
      ? data.movementDate!.toIso8601String().substring(0, 10)
      : '';
  final String type = (data.isSoTrx == true) ? 'Shipment' : 'Receipt';
  final String title = data.cDocTypeId?.identifier ?? type;

  final Map<int, pw.TableColumnWidth> tableWidths = {
    0: const pw.FractionColumnWidth(0.9 / 22), // Line
    1: const pw.FractionColumnWidth(2.5 / 22), // SKU
    2: const pw.FractionColumnWidth(2.4 / 22), // UPC
    3: const pw.FractionColumnWidth(2 / 22), // QTY
    4: const pw.FractionColumnWidth(7 / 22), // Product
    5: const pw.FractionColumnWidth(3.1 / 22), // From
    6: const pw.FractionColumnWidth(2 / 22), // Attribute
    7: const pw.FractionColumnWidth(2.1 / 22), // To
  };

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: pw.EdgeInsets.all(marginInPoint),
      header: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Table(
            columnWidths: _headerColumnWidths,
            children: [
              pw.TableRow(
                children: [
                  pw.Image(pwImage, width: 150),
                  pw.Column(
                    children: [
                      pw.Text(title,
                          style: const pw.TextStyle(fontSize: titleFontSize)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('No: $docNo',
                          style: const pw.TextStyle(fontSize: titleFontSize)),
                      pw.Text('${Messages.DATE}: $movementDate',
                          style: const pw.TextStyle(fontSize: titleFontSize)),
                    ],
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: docNo,
                    width: 50,
                    height: 50,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      footer: (pw.Context context) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(5),
          alignment: pw.Alignment.centerRight,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Text(
            '${Messages.PAGE} ${context.pageNumber} ${Messages.OF} ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: defaultFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
      },
      build: (pw.Context context) => [
        pw.SizedBox(height: 10),
        pw.Table(
          columnWidths: tableWidths,
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(width: 1, color: PdfColors.grey),
            top: pw.BorderSide(width: 1, color: PdfColors.grey),
            bottom: pw.BorderSide(width: 1, color: PdfColors.grey),
          ),
          children: [
            // Header row.
            pw.TableRow(
              children: [
                _headerCell('Line', alignRight: true),
                _headerCell('SKU'),
                _headerCell('UPC/EAN'),
                _headerCell(Messages.QUANTITY_SHORT, alignRight: true),
                _headerCell(Messages.PRODUCT),
                _headerCell(Messages.FROM),
                _headerCell(Messages.ATTRIBUTE),
                _headerCell(Messages.TO),
              ],
            ),
            // Data rows.
            ...lines.map((line) {
              return pw.TableRow(
                children: [
                  _bodyCell((line.line ?? 0).toString(), alignRight: true),
                  _bodyCell(line.sku ?? ''),
                  _bodyCell(line.upc ?? ''),
                  _bodyCell('${line.movementQty ?? 0}', alignRight: true),
                  _bodyCell(
                    (line.mProductId?.identifier ?? '').split('_').last,
                  ),
                  _bodyCell(
                    line.mLocatorId?.identifier ?? '',
                  ),
                  _bodyCell(
                    line.mAttributeSetInstanceID?.identifier ?? '---',
                  ),
                  _bodyCell(
                    line.mLocatorToId?.identifier ?? '',
                  ),
                ],
              );
            }),
            // Totals row.
            pw.TableRow(
              children: [
                _bodyCell('', bold: true),
                _bodyCell('TOTAL', bold: true),
                _bodyCell('', bold: true),
                _bodyCell('$totalQty', alignRight: true, bold: true),
                _bodyCell('', bold: true),
                _bodyCell('', bold: true),
                _bodyCell('', bold: true),
                _bodyCell('', bold: true),
              ],
            ),
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
                style: pw.TextStyle(
                  fontSize: defaultFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                '${Messages.DATE}: ${DateTime.now().toLocal().toString().split('.').first}',
                style: pw.TextStyle(
                  fontSize: defaultFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  return await pdf.save();
}

pw.Widget _headerCell(String text, {bool alignRight = false}) {
  final cell = pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 8.0, fontWeight: pw.FontWeight.bold),
    ),
  );
  if (!alignRight) return cell;
  return pw.Align(alignment: pw.Alignment.centerRight, child: cell);
}

pw.Widget _bodyCell(String text,
    {bool alignRight = false, bool bold = false}) {
  final style = pw.TextStyle(
    fontSize: 8.0,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  final padded = pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
    child: pw.Text(text, style: style),
  );
  if (!alignRight) return padded;
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
    child: pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(text, style: style),
    ),
  );
}

final Map<int, pw.TableColumnWidth> _headerColumnWidths = {
  0: const pw.FractionColumnWidth(4 / 20),
  1: const pw.FractionColumnWidth(4 / 20),
  2: const pw.FractionColumnWidth(10 / 20),
  3: const pw.FractionColumnWidth(2 / 20),
};
