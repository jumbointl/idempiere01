// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';


import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/product_provider_common.dart';

class NewMovementCardWithLocator extends ConsumerStatefulWidget {
  Color bgColor;
  final MovementAndLines movementAndLines;
  final String argument;
  double height = 180.0;
  double width = double.infinity;
  //MovementsScreen movementScreen;
  TextStyle movementStyle = const TextStyle(fontWeight: FontWeight.bold,color: Colors.white,
        fontSize: themeFontSizeLarge);
  NewMovementCardWithLocator({
    super.key,
    required this.bgColor,
    required this.height,
    required this.width,
    required this.movementAndLines,
    required this.argument,
  });

  @override
  ConsumerState<NewMovementCardWithLocator> createState() => MovementHeaderCardWithLocatorState();
}


class MovementHeaderCardWithLocatorState extends ConsumerState<NewMovementCardWithLocator> {
  @override
  Widget build(BuildContext context) {

    String titleLeft='';
    String titleRight='';
    String subtitleLeft='';
    String subtitleRight='';

    String date='';
    String id='';
    bool canCompleteMovement = widget.movementAndLines.canCompleteMovement ;
    if(widget.movementAndLines.hasMovement){      //id = movement.documentNo ?? '';
      id = widget.movementAndLines.id.toString();
      date = widget.movementAndLines.movementDate?.toString() ?? '';
      titleLeft = '${Messages.FROM}:${widget.movementAndLines.mWarehouseID?.identifier ?? ''}';
      titleRight = '${Messages.TO}:${widget.movementAndLines.mWarehouseToID?.identifier ?? ''}';
      subtitleLeft = '${Messages.DOC_STATUS}: ${widget.movementAndLines.docStatus?.identifier ?? ''}';
      subtitleRight = canCompleteMovement ? Messages.CONFIRM : '';
    } else {
      id = widget.movementAndLines.name ?? Messages.EMPTY;
      titleLeft =widget.movementAndLines.identifier ?? Messages.EMPTY;
    }
    final isScanning = ref.watch(isScanningProvider.notifier);
    widget.bgColor = themeColorPrimary;
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        //height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.bgColor,
          /*image: DecorationImage(
            image: AssetImage('assets/images/supply-chain.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
          ),*/
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.shadow.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
          border: Border.all(
            color: context.outline.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        padding: EdgeInsets.only(left: 16,right:16, top: 16,bottom: 16),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(id,style: widget.movementStyle,overflow: TextOverflow.ellipsis,),
                Text(
                  date,
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green, // Changed to transparent for IconButton
                    ),
                    onPressed: () {
                       //printMovementAndLines(context, ref,widget.movementAndLines);
                      //GoRouterHelper(ref.context).push(AppRouter.PAGE_PDF_MOVEMENT_AND_LINE, extra: widget.movementAndLines);
                      GoRouterHelper(ref.context).go(AppRouter.PAGE_MOVEMENT_PRINTER_SETUP,
                          extra: widget.movementAndLines);

                      /*AwesomeDialog(
                        context: context,
                        dialogType: DialogType.info,
                        animType: AnimType.scale,
                        title: Messages.NOT_IMPLEMENTED,
                        desc: Messages.NOT_IMPLEMENTED_YET,
                        autoHide: const Duration(seconds: 3),
                        btnOkOnPress: () {},
                        btnOkColor: themeColorSuccessful,
                      ).show();

                       */
                    },
                    icon: Icon(Icons.print, color: Colors.white,)), // Changed to Icon for IconButton
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    titleLeft,
                    style: widget.movementStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    titleRight,
                    style: widget.movementStyle,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              widget.movementAndLines.hasLastLocatorFrom ?
              widget.movementAndLines.lastLocatorFrom!.value ??
                  widget.movementAndLines.lastLocatorFrom!.identifier ?? '' : '',
              style: widget.movementStyle,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.movementAndLines.hasLastLocatorTo ? widget.movementAndLines.lastLocatorTo!.value ??
                  widget.movementAndLines.lastLocatorTo!.identifier ?? '' : '',
              style: widget.movementStyle,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitleLeft,
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),

                canCompleteMovement ? GestureDetector(
                  onTap: (){
                    if(!widget.movementAndLines.canComplete){
                      AwesomeDialog(
                        context: context,
                        animType: AnimType.scale,
                        dialogType: DialogType.error,
                        body: Center(child: Text(
                          Messages.MOVEMENT_ALREADY_COMPLETED,
                          //style: TextStyle(fontStyle: FontStyle.italic),
                        ),), // correct here
                        title: Messages.MOVEMENT_ALREADY_COMPLETED,
                        desc:   '',
                        autoHide: const Duration(seconds: 3),
                        btnOkOnPress: () {},
                        btnOkColor: themeColorSuccessful,
                        btnCancelColor: themeColorError,
                        btnCancelText: Messages.CANCEL,
                        btnOkText: Messages.OK,
                      ).show();
                      return;
                    } else {

                      GoRouterHelper(context).go(
                          AppRouter.PAGE_MOVEMENTS_CONFIRM_SCREEN,
                      extra: widget.movementAndLines);
                    }

                  },
                  child: Container(
                    color: canCompleteMovement ? Colors.green : themeColorPrimary,
                    child: Text(
                      subtitleRight ,
                      textAlign: TextAlign.end,
                      style: widget.movementStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ) :Text(
                  subtitleRight ,
                  textAlign: TextAlign.end,
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),

              ],
            ) ,
          ],
        ),
      ),
    );
  }

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
                            }).toList(),
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
// Define el ancho de las columnas usando un mapa.
  final Map<int, pw.TableColumnWidth> tableWidths = {
    0: pw.FractionColumnWidth(1 / 28), // Line (flex: 1)
    1: pw.FractionColumnWidth(3 / 28), // SKU (flex: 3)
    2: pw.FractionColumnWidth(3 / 28), // UPC (flex: 3)
    3: pw.FractionColumnWidth(2 / 28), // QTY (flex: 2)
    4: pw.FractionColumnWidth(3 / 28), // Product (flex: 3)
    5: pw.FractionColumnWidth(3 / 28), // From (flex: 3)
    6: pw.FractionColumnWidth(3 / 28), // To (flex: 3)
    7: pw.FractionColumnWidth(3 / 28), // Attribute (flex: 3)
    8: pw.FractionColumnWidth(3 / 28), // Price (flex: 3)
    9: pw.FractionColumnWidth(3 / 28), // Subtotal (flex: 3)
  };
}
