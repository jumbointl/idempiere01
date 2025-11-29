// print_controller.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';

import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';

/*
// ====== MODELOS (ajústalos si ya los tienes en tu proyecto) ======
class IdempiereMovementLine {
  final String? sKU;
  final String? uPC;
  final double? movementQty;
  final String locatorFromName;
  final String locatorToName;
  final String productNameWithLine;
  final String? attributeName;
  final String movementQtyString;

  IdempiereMovementLine({
    this.sKU,
    this.uPC,
    this.movementQty,
    required this.locatorFromName,
    required this.locatorToName,
    required this.productNameWithLine,
    this.attributeName,
    required this.movementQtyString,
  });
}

class MovementAndLines {
  final int? id;
  final String? movementDate;
  final String documentNumber;
  final String documentStatus;
  final String movementIcon; // asset image path
  final String documentMovementTitle;
  final List<IdempiereMovementLine>? movementLines;

  MovementAndLines({
    this.id,
    this.movementDate,
    required this.documentNumber,
    required this.documentStatus,
    required this.movementIcon,
    required this.documentMovementTitle,
    required this.movementLines,
  });
}
*/

// ====== PROVIDER ======
final printControllerProvider =
AsyncNotifierProvider<PrintController, Uint8List?>(PrintController.new);

class PrintController extends AsyncNotifier<Uint8List?> {
  late String _ip;
  late int _port;
  late MovementAndLines _data;

  @override
  Future<Uint8List?> build() async {
    // Se genera el PDF cuando se inicializa (luego de init)
    return null;
  }

  void init({
    required String ip,
    required int port,
    required MovementAndLines data,
  }) {
    _ip = ip;
    _port = port;
    _data = data;
    _generateAndSet();
  }

  Future<void> _generateAndSet() async {
    final bytes = await _generatePdf(_data);
    state = AsyncData(bytes);
  }

  Future<void> regenerate() async {
    await _generateAndSet();
  }

  Future<void> printToSocket() async {
    final pdfBytes = state.value;
    if (pdfBytes == null) {
      // Si aún no existe, lo generamos.
      final bytes = await _generatePdf(_data);
      await _sendRawPdf(bytes);
    } else {
      await _sendRawPdf(pdfBytes);
    }
  }

  Future<void> _sendRawPdf(Uint8List pdfBytes) async {
    // Envia el PDF tal cual por socket TCP a la impresora
    // IMPORTANTE: Esto solo funciona si la impresora acepta PDF crudo por socket.
    // Muchas POS solo aceptan ESC/POS (texto/bitmap). Ajusta según tu equipo.
    final socket = await Socket.connect(_ip, _port, timeout: const Duration(seconds: 5));
    socket.add(pdfBytes);
    await socket.flush();
    await socket.close();
  }

  // ====== Generación de PDF ======
  Future<Uint8List> _generatePdf(MovementAndLines m) async {
    final pdf = pw.Document();

    // Cargar icono desde assets si lo tienes en Flutter
    pw.ImageProvider? movementIcon;
    try {
      final image = await _tryLoadAssetImage(m.movementIcon);
      if (image != null) movementIcon = image;
    } catch (_) {}

    final totalItems = (m.movementLines ?? [])
        .fold<double>(0.0, (acc, e) => acc + (e.movementQty ?? 0.0));

    // Tipografías base
    final base = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => _buildHeader(
          m: m,
          base: base,
          bold: bold,
          movementIcon: movementIcon,
        ),
        footer: (ctx) => _buildFooter(
          m: m,
          base: base,
          bold: bold,
        ),
        build: (context) => [
          _buildTableHeader(base: base, bold: bold),
          pw.SizedBox(height: 6),
          ..._buildTableBody(
            lines: m.movementLines ?? [],
            base: base,
            bold: bold,
          ),
          pw.Divider(thickness: 1),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'ITEMS TOTAL ${_fmtNum(totalItems)}',
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  String _fmtNum(double n) {
    // Formatea 12.0 -> 12.000 (según ejemplo)
    return n.toStringAsFixed(3);
  }

  // Encabezado
  pw.Widget _buildHeader({
    required MovementAndLines m,
    required pw.Font base,
    required pw.Font bold,
    pw.ImageProvider? movementIcon,
  }) {
    final qr = Barcode.qrCode();
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Columna izquierda: icono y textos
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (movementIcon != null)
                      pw.Container(
                        width: 32,
                        height: 32,
                        margin: const pw.EdgeInsets.only(right: 8),
                        child: pw.Image(movementIcon),
                      ),
                    pw.Expanded(
                      child: pw.Center(
                        child: pw.Text(
                          m.documentMovementTitle,
                          style: pw.TextStyle(font: bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(m.movementDate ?? '', style: pw.TextStyle(font: base)),
                pw.Text('MONALISA S.A.', style: pw.TextStyle(font: base)),
                pw.Text(m.documentStatus, style: pw.TextStyle(font: base)),
                pw.Text(m.documentNumber, style: pw.TextStyle(font: base)),
                pw.Text('Av. Monseñor Rodriguez', style: pw.TextStyle(font: base)),
                pw.Text('C/ Av. Carlos Antonio López, CDE', style: pw.TextStyle(font: base)),
                pw.Text('Actualizacion de existencias ', style: pw.TextStyle(font: base)),
              ],
            ),
          ),
          // Derecha: QR con número de documento, tamaño 50 (altura ≈ 50)
          pw.Container(
            alignment: pw.Alignment.topRight,
            child: pw.BarcodeWidget(
              barcode: qr,
              data: m.documentNumber,
              width: 50,
              height: 50,
            ),
          ),
        ],
      ),
    );
  }

  // Header de tabla
  pw.Widget _buildTableHeader({required pw.Font base, required pw.Font bold}) {
    final styleH = pw.TextStyle(font: bold, fontSize: 8);
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(width: 0.5),
        bottom: pw.BorderSide(width: 0.5),
        horizontalInside: pw.BorderSide(width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(4), // 40%
        1: const pw.FlexColumnWidth(6), // 60%
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('UPC/SKU', style: styleH),
                        pw.Text('Línea/Nombre Producto', style: styleH),
                        pw.Text('Atributo', style: styleH),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.topRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Hasta/Desde', style: styleH),
                  pw.Text('Cantidad', style: styleH),
                  pw.Text('', style: styleH),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Body de tabla
  List<pw.Widget> _buildTableBody({
    required List<IdempiereMovementLine> lines,
    required pw.Font base,
    required pw.Font bold,
  }) {
    final List<pw.Widget> rows = [];
    for (final e in lines) {
      // 2 filas por ítem, con solo líneas horizontales
      rows.add(
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(width: 0.5),
            top: pw.BorderSide(width: 0.5),
            bottom: pw.BorderSide.none,
            left: pw.BorderSide.none,
            right: pw.BorderSide.none,
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(4), // 40%
            1: pw.FlexColumnWidth(6), // 60%
          },
          children: [
            // 1ra fila
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(e.uPC ?? '-', style: pw.TextStyle(font: bold, fontSize: 12)),
                      pw.Text(e.sKU ?? '-', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(e.locatorToName, style: pw.TextStyle(font: bold, fontSize: 12)),
                      pw.Text(e.locatorFromName, style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            // 2da fila
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(e.productNameWithLine, style: const pw.TextStyle(fontSize: 12)),
                      pw.Text(e.attributeName?.isNotEmpty == true ? e.attributeName! : '-', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    e.movementQtyString,
                    style: pw.TextStyle(font: bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return rows;
  }

  // Pie de página: QR izquierda, barcode derecha
  pw.Widget _buildFooter({
    required MovementAndLines m,
    required pw.Font base,
    required pw.Font bold,
  }) {
    final qr = Barcode.qrCode();
    final code128 = Barcode.code128();

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.BarcodeWidget(
            barcode: qr,
            data: m.documentNumber,
            width: 50,
            height: 50,
          ),
          pw.Spacer(),
          pw.BarcodeWidget(
            barcode: code128,
            data: (m.id ?? 0).toString(),
            height: 50,
            width: 200, // se respeta un "width=2" como grosor por barra no aplica; aquí usamos ancho total
            drawText: false,
          ),
        ],
      ),
    );
  }

  // Carga de asset (opcional)
  Future<pw.ImageProvider?> _tryLoadAssetImage(String assetPath) async {
    // Si deseas cargar assets reales dentro de pdf, debes traer bytes (rootBundle).
    // Aquí se omite por simplicidad; si lo necesitas, inyecta bytes de la imagen.
    return null;
  }
}
