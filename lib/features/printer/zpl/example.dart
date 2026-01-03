import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image/image.dart' as img;
import '../../products/common/messages_dialog.dart';
import '../../products/domain/idempiere/idempiere_movement_confirm.dart';
import '../../products/domain/idempiere/idempiere_movement_line.dart';
import '../../products/domain/idempiere/movement_and_lines.dart';
import '../../shared/data/memory.dart';
import '../../shared/data/messages.dart';
import 'package:barcode_image/barcode_image.dart' as img_barcode;
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle, Uint8List, ByteData;
final int imageWidth80mm = 576;
final int leftMargin = 20;
final int rightMargin = 0;
final int qrSize = 110;
final int barcodeWidth =440;

final maxCharacterBarcodeOneRow = 17;
Future<void> printReceiptWithQr(WidgetRef ref,String ip, int port,MovementAndLines movementAndLines) async {
  if(ip.isEmpty || port==0) {
    return;
  }
  print('PRINTING POS');
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
  print('PRINTING POS 2');
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
  if(ref.context.mounted) printPosTicket(ref, ip,port,bytes);

}

Future<void> printPosTicket(WidgetRef ref, String ip, int port, List<int> ticket) async {
  print('PRINTING POS printPosTicket');
  final printer = PrinterNetworkManager(ip,
      port: port);
  PosPrintResult connect = await printer.connect();
  print('PRINTING POS printPosTicket connect: $connect');
  if (connect == PosPrintResult.success) {
    print('PRINTING POS printPosTicket connect: success');
    PosPrintResult printing = await printer.printTicket(ticket);
    print(printing.msg);
    await Future.delayed(const Duration(seconds: 2));
    printer.disconnect();
  } else {
    print('PRINTING POS printPosTicket connect: timeout');
    if (ref.context.mounted) {
      showErrorMessage(ref.context, ref, Messages.ERROR_TIMEOUT);
    }
  }
}

// Función principal para combinar
Future<Uint8List> combineQrAndBarcode(String qrData, String barcodeData) async {

  final int targetHeight = qrSize; // Altura objetivo para ambos

  // --- 1. Generar el QR Code (tu código existente funciona bien) ---
  // ... (código QR Painter a ui.Image a img.Image) ...
  final qrPainter = QrPainter(data: qrData, version: QrVersions.auto, gapless: false);
  final ui.Image qrUiImage = await qrPainter.toImage(targetHeight.toDouble());
  final ByteData? qrByteData = await qrUiImage.toByteData(format: ui.ImageByteFormat.png);
  final img.Image qrImage = img.decodeImage(qrByteData!.buffer.asUint8List())!;


  // --- 2. Generar el Barcode usando barcode_image ---
  // Crear una imagen 'img.Image' vacía donde dibujar el barcode
  int finalBarcodeWidth = barcodeWidth;
  if(barcodeData.length<8){
    finalBarcodeWidth = 250;
  }else if(barcodeData.length<10){
    finalBarcodeWidth = 280;
  } else if(barcodeData.length<14){
    finalBarcodeWidth = 320;
  }
  final img.Image barcodeImage = img.Image(width: finalBarcodeWidth, height: targetHeight, numChannels: 3);
  img.fill(barcodeImage, color: img.ColorRgb8(255, 255, 255)); // Fondo blanco
  final img.BitmapFont font = img.arial24;
  // Dibujar el Code 128 en la imagen usando el paquete barcode_image

  img_barcode.drawBarcode(
      barcodeImage,
      img_barcode.Barcode.code128(
        useCode128B: true,
      ), // Usa la simbología code128 del paquete barcode_image
      barcodeData,
      width: finalBarcodeWidth,
      height: targetHeight,
      font: font,
      textPadding: 5

  );

  // --- 3. Combinar las dos imágenes ---
  //final int spacing = 10;
  //final int totalWidth = qrImage.width + barcodeImage.width + spacing;
  final int totalWidth = imageWidth80mm;
  final img.Image mergedImage = img.Image(width: totalWidth, height: targetHeight, numChannels: 3);
  img.fill(mergedImage, color: img.ColorRgb8(255, 255, 255));

  img.compositeImage(mergedImage, qrImage, dstX: 0, dstY: 0);
  img.compositeImage(mergedImage, barcodeImage, dstX: totalWidth-barcodeImage.width-rightMargin, dstY: 0);

  // 4. Codificar la imagen combinada a bytes
  final Uint8List combinedImageBytes = Uint8List.fromList(img.encodePng(mergedImage));

  return combinedImageBytes;


}

Future<Uint8List> combineLogoAndQrCode({required String logo, required String qrData}) async {
  // --- 1. Cargar y decodificar el Logo ---
  final ByteData logoBytes = await rootBundle.load('assets/images/monalisa_logo_movement.jpg');
  img.Image logoImage = img.decodeImage(logoBytes.buffer.asUint8List())!;

  // Opcional: Redimensionar el logo si es muy grande. Ejemplo: 100px de ancho.
  logoImage = img.copyResize(logoImage, width: qrSize);

  // --- 2. Generar y decodificar el QR Code ---


  final qrPainter = QrPainter(
    data: qrData,
    version: QrVersions.auto,
    gapless: false,
  );

  // Convertir el QrPainter a ui.Image
  final ui.Image qrUiImage = await qrPainter.toImage(qrSize.toDouble());

  // Convertir ui.Image a formato img.Image (paquete 'image')
  final ByteData? qrByteData = await qrUiImage.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List qrUint8List = qrByteData!.buffer.asUint8List();
  img.Image qrImage = img.decodeImage(qrUint8List)!;
  // --- 3. Combinar las dos imágenes usando compositeImage ---

  // Calcular las dimensiones de la nueva imagen combinada
  //final int totalWidth = logoImage.width + qrImage.width + 10; // Añadir un pequeño margen
  final int totalWidth = imageWidth80mm; // Añadir un pequeño margen
  final int maxHeight = logoImage.height > qrImage.height ? logoImage.height : qrImage.height;

  // Crear un nuevo lienzo (fondo blanco)
  final img.Image mergedImage = img.Image(width: totalWidth, height: maxHeight, numChannels: 3);
  img.fill(mergedImage, color: img.ColorRgb8(255, 255, 255));

  // Copiar el logo a la izquierda (x: 0, y: centrado verticalmente)
  img.compositeImage(
    mergedImage,
    logoImage,
    dstX: 0,
    dstY: (maxHeight - logoImage.height) ~/ 2, // Centrado vertical
    blend: img.BlendMode.alpha, // Modo de mezcla normal
  );

  // Copiar el QR a la derecha (x: ancho del logo + margen, y: centrado verticalmente)
  img.compositeImage(
    mergedImage,
    qrImage,
    //dstX: logoImage.width + 10, // Posición después del logo + margen
    dstX: totalWidth - qrImage.width-rightMargin, // Posición después del logo + margen
    dstY: (maxHeight - qrImage.height) ~/ 2, // Centrado vertical
    blend: img.BlendMode.alpha,
  );

  // 4. Codificar la imagen combinada a bytes
  final Uint8List combinedImageBytes = Uint8List.fromList(img.encodePng(mergedImage));

  return combinedImageBytes;

}