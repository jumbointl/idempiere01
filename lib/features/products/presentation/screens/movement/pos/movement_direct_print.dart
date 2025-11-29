import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle, Uint8List, ByteData;
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../domain/idempiere/idempiere_movement_confirm.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../printer/pos_image_utility.dart';

final maxCharacterBarcodeOneRow = 17;
Future<void> printReceiptWithQr(String ip, int port,MovementAndLines movementAndLines) async {
  if(ip.isEmpty || port==0) {
    return;
  }
  // 1. Cargar el perfil de la impresora
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm80, profile); // Ajusta el tamaño del papel

  List<int> bytes = [];
  bytes += generator.reset();
  bytes += generator.setGlobalCodeTable('CP1252');
  // --- Parte de la impresión del logo ---
  //final ByteData data = await rootBundle.load('assets/images/monalisa_logo_movement.jpg');

  //final Uint8List assetBytes = data.buffer.asUint8List();
  String qrData = movementAndLines.documentNumber ;
  String title = movementAndLines.documentMovementTitle;
  String logo = movementAndLines.movementIcon;
  final Uint8List assetBytes = await combineLogoAndQrCode(logo: logo , qrData: qrData);
  Future.delayed(Duration(milliseconds: 500), () {});
  final img.Image? logoImage = img.decodeImage(assetBytes);
  String date = movementAndLines.movementDate ??'';
  String company = movementAndLines.cBPartnerID?.identifier ?? '';
  String documentNumber = movementAndLines.documentNumber;
  String documentStatus = movementAndLines.documentStatus;
  String address =movementAndLines.cBPartnerLocationID?.identifier ?? '';
  String description =movementAndLines.description ??'';
  late var titleSizeWidth = PosTextSize.size1;



  Future.delayed(Duration(milliseconds: 500), () {});
  if (logoImage != null) {
    bytes += generator.image(logoImage);
    bytes += generator.feed(1);
  } else {
    print('Error: No se pudo decodificar la imagen.');
    // Continúa imprimiendo sin el logo si falla
  }
  bytes += generator.row([
    PosColumn(
      text: '',
      width: 1,
      styles: const PosStyles(

        align: PosAlign.left, bold: false, ),
    ),
    PosColumn(
      text: title,
      width: 10,
      styles: PosStyles(
        align: PosAlign.center, bold: true,height: PosTextSize.size2, width: titleSizeWidth,),
    ),
    PosColumn(
      text: '',
      width: 1,
      styles: const PosStyles(

        align: PosAlign.left, bold: false, ),
    ),
  ]);
  bytes += generator.feed(1);
  bytes += generator.row([
    PosColumn(
      text: date,
      width: 6,
      styles: const PosStyles(

        align: PosAlign.left, bold: false, ),
    ),
    PosColumn(
      text: '',
      width: 6,
      styles: const PosStyles(
        align: PosAlign.right, bold: false, ),
    ),

  ]);
  bytes += generator.row([
    PosColumn(
      text: documentStatus,
      width: 4,
      styles: const PosStyles(

        align: PosAlign.left, bold: false, ),
    ),
    PosColumn(
      text: documentNumber,
      width: 8,
      styles: const PosStyles(
        align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size1, ),
    ),

  ]);

  //bytes += generator.text(documentNumber, styles: const PosStyles(align: PosAlign.right, bold: true,height: PosTextSize.size2, width: PosTextSize.size1));
  bytes += generator.text(company, styles: const PosStyles(align: PosAlign.left, bold: false));
  bytes += generator.text(address, styles: const PosStyles(align: PosAlign.left, bold: false));
  bytes += generator.text(description, styles: const PosStyles(align: PosAlign.left, bold: false));
  bytes += generator.feed(1);
  bytes += generator.hr(); // Línea horizontal

  Future.delayed(Duration(milliseconds: 500), () {});
  bytes += generator.row([
    PosColumn(
      text: 'UPC/SKU',
      width: 6,
      styles: const PosStyles(

        align: PosAlign.left, bold: false, ),
    ),
    PosColumn(
      text: 'HASTA/DESDE',
      width: 6,
      styles: const PosStyles(
        align: PosAlign.right, bold: false, ),
    ),

  ]);
  bytes += generator.row([
    PosColumn(
      text: 'ATTRIBUTO',
      width: 6,
      styles: const PosStyles(
        align: PosAlign.left, bold: false, ),
    ),
    PosColumn(
      text: 'CANTIDAD',
      width: 6,
      styles: const PosStyles(
        align: PosAlign.right, bold: false, ),
    ),

  ]);
  bytes += generator.row([
    PosColumn(
      text: 'LINEA/NOMBRE DE PRODUCTO',
      width: 7,
      styles: const PosStyles(
        align: PosAlign.left, bold: false, ),
    ),
    PosColumn(
      text: '',
      width: 5,
      styles: const PosStyles(
        align: PosAlign.left, bold: false, ),
    ),

  ]);

  bytes += generator.hr();
  List<IdempiereMovementLine> rows = movementAndLines.movementLines ?? [];
  double totalItems = 0;
  for(int i = 0; i<rows.length; i++){
    double quantity = rows[i].movementQty ?? 0;
    totalItems += quantity;
    String quantityStr = Memory.numberFormatter0Digit.format(quantity);
    String product = rows[i].productNameWithLine;
    String upc = rows[i].uPC ?? '';
    String sku = rows[i].sKU ?? '';
    String to = rows[i].locatorToName ?? '';
    String from = rows[i].locatorFromName ?? '';
    String atr = rows[i].attributeName ?? '--';
    bytes += generator.row([
      PosColumn(
        text: upc,
        width: 5,
        styles: const PosStyles(align: PosAlign.left,bold: true),
      ),
      PosColumn(
        text: to,
        width: 7,
        styles: const PosStyles(align: PosAlign.right, bold: true,),
      ),]);
    bytes += generator.row([
      PosColumn(
        text: sku,
        width: 5,
        styles: const PosStyles(align: PosAlign.left,bold: false),
      ),
      PosColumn(
        text: from,
        width: 7,
        styles: const PosStyles(align: PosAlign.right, bold: false,),
      ),]);
    bytes += generator.row([
      PosColumn(
        text: atr,
        width: 5,
        styles: const PosStyles(align: PosAlign.left,bold: false),
      ),
      PosColumn(
        text: '',
        width: 7,
        styles: const PosStyles(align: PosAlign.right, bold: true,),
      ),]);
    bytes += generator.row([
      PosColumn(
        text: product,
        width: 7,
        styles: const PosStyles(align: PosAlign.left,bold: true),
      ),

      PosColumn(
        text: quantityStr,
        width: 5,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
      ),]);
    bytes += generator.hr();
  }
  String totalItemsString = Memory.numberFormatter0Digit.format(totalItems);
  bytes += generator.row([
    PosColumn(
      text: 'ITEMS TOTAL',
      width: 6,
      styles: const PosStyles(align: PosAlign.left,bold: false,height: PosTextSize.size2, width: PosTextSize.size2),
    ),
    PosColumn(
      text: totalItemsString,
      width: 6,
      styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    ),]);
  //bytes += generator.hr();
  // --- Parte de la impresión del código QR ---

  bytes += generator.feed(1);


  DateTime now = DateTime.now();

  String datetime = now.toIso8601String().split('.').first;
  datetime = datetime.replaceAll('T', ' ');
  //var barcodeValue = '{BORDEN-${Random().nextInt(9999)}';

  if(movementAndLines.movementConfirms!= null && movementAndLines.movementConfirms!.isNotEmpty){
       for(int i = 0; i<movementAndLines.movementConfirms!.length; i++){
         IdempiereMovementConfirm movementConfirm = movementAndLines.movementConfirms![i];
         String barcodeData = movementConfirm.documentNo ?? '';
         String qrData = movementConfirm.documentNo ?? '';
         if(barcodeData.length<=maxCharacterBarcodeOneRow){
           final Uint8List assetBytesAux = await combineQrAndBarcode(qrData, barcodeData);
           Future.delayed(Duration(milliseconds: 500), () {});
           final img.Image? logoImageAux = img.decodeImage(assetBytesAux);
           if (logoImageAux != null) {
             bytes += generator.image(logoImageAux);
             bytes += generator.feed(1);
           }
         } else {
           bytes += generator.qrcode(
             qrData,
             size: QRSize.size5, // Ajusta el tamaño del QR (1 a 16)
             cor: QRCorrection.L, // Nivel de corrección (L, M, Q, H)
           );
           Future.delayed(Duration(milliseconds: 500), () {});
           bytes += generator.feed(1); // Alimentar un poco de papel después del QR

           /// CODE128
           ///
           /// k >= 2
           /// d: '{A'/'{B'/'{C' => '0'–'9', A–D, a–d, $, +, −, ., /, :
           /// usage:
           /// {A = QRCode type A
           /// {B = QRCode type B
           /// {C = QRCode type C
           /// barcodeData ex.: "{BMOSK-12345".split(""); only accept {B at 09/10/2025
           barcodeData='{B$barcodeData';
           print(barcodeData);
           //final barcode =  Barcode.code128(barcodeData)
           //final barcode =  Barcode.code128("{BMOSK-12345".split(""));
           final barcode =  Barcode.code128(barcodeData.split(""));
           bytes += generator.barcode(
             barcode,
             width: 1,  // Ajusta el ancho de las barras (1-4)
             height: 40, // Ajusta la altura del código de barras
             font: BarcodeFont.fontB,
             textPos: BarcodeText.below, // Muestra el texto debajo del código
           );
           bytes += generator.feed(1);
         }


       }



  }

  bytes += generator.text(datetime,
      styles: const PosStyles(align: PosAlign.center));
  /*bytes += generator.text('Código del documento', styles: const PosStyles(
      align: PosAlign.center,codeTable: 'CP1252'));*/
  bytes += generator.feed(1);


  bytes += generator.feed(5);
  bytes += generator.cut(); // Cortar el papel
  printPosTicket(ip,port,bytes);

}

Future<void> printPosTicket(String ip, int port, List<int> ticket) async {

  final printer = PrinterNetworkManager(ip,
      port: port);
  PosPrintResult connect = await printer.connect();
  if (connect == PosPrintResult.success) {
    PosPrintResult printing = await printer.printTicket(ticket);
    print(printing.msg);
    await Future.delayed(const Duration(seconds: 2));
    printer.disconnect();
  }

}