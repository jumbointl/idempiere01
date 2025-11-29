
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../../providers/common_provider.dart';
import 'lite_ipp_print.dart';

Future<void> sendPdfToNode(WidgetRef ref, Uint8List pdfBytes, String cupsServiceUrl,String printerName) async {

  print('Enviando archivo PDF a $cupsServiceUrl');

  var request = http.MultipartRequest(
    'POST',
    Uri.parse(cupsServiceUrl),
  );
  request.fields['printer_name'] = printerName;
  // Crea el MultipartFile a partir de los bytes
  request.files.add(
    http.MultipartFile.fromBytes(
      'print_file', // El nombre del campo que espera tu servicio Node.js
      pdfBytes,
      filename: 'documento.pdf', // Un nombre de archivo para el servicio
      // Asegúrate de que el tipo MIME sea 'application/pdf'
      contentType: MediaType('application', 'pdf'),
    ),
  );

  try {
    print('Enviando archivo PDF a $cupsServiceUrl');
    var response = await request.send().timeout(const Duration(seconds: 60));
    if (response.statusCode == 200) {
      if(ref.context.mounted) {
        showSuccessMessage(ref.context, ref, '${Messages.PRINT_SUCCESS} $cupsServiceUrl $printerName');
      }
      print('Archivo PDF enviado exitosamente al servicio de impresión.');
    } else {
      if(ref.context.mounted) {
        showErrorMessage(ref.context, ref, '${Messages.PRINT_FAILED} $cupsServiceUrl $printerName');
      }
      print('Error al enviar el archivo: ${response.statusCode}');
    }
  } catch (e) {
    if(ref.context.mounted) {
      showErrorMessage(ref.context, ref, '${Messages.NETWORK_ERROR} $cupsServiceUrl $printerName');
    }
    print('Error de red: $e');
  } finally {
    ref.read(isPrintingProvider.notifier).state = false;
  }
}
Future<Uint8List> get imageLogo async {
  final ByteData bytes = await rootBundle.load('assets/images/logo-monalisa.jpg');
  return bytes.buffer.asUint8List();
}

Future<void> sendPdfToNodeDio(WidgetRef ref, Uint8List pdfBytes, String cupsServiceUrl, String printerName) async {
  print('Enviando archivo PDF a $cupsServiceUrl con Dio');

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60), // Aumenta el tiempo de espera
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  final formData = FormData.fromMap({
    'printer_name': printerName,
    'print_file': MultipartFile.fromBytes(
      pdfBytes,
      filename: 'documento.pdf',
    ),
  });

  try {
    final response = await dio.post(
      cupsServiceUrl,
      data: formData,
    );

    if (response.statusCode == 200) {
      if (ref.context.mounted) {
        showSuccessMessage(ref.context, ref, '${Messages.PRINT_SUCCESS} $cupsServiceUrl $printerName');
      }
      print('Archivo PDF enviado exitosamente al servicio de impresión.');
    } else {
      if (ref.context.mounted) {
        showErrorMessage(ref.context, ref, '${Messages.PRINT_FAILED} ${response.statusCode}');
      }
      print('Error al enviar el archivo: ${response.statusCode}');
    }
  } on DioException catch (e) {
    if (ref.context.mounted) {
      // Maneja los errores de forma más detallada
      if (e.type == DioExceptionType.connectionTimeout) {
        showErrorMessage(ref.context, ref, 'Tiempo de espera agotado. Verifique la conexión.');
      } else {
        showErrorMessage(ref.context, ref, 'Error de red con Dio: ${e.message}');
      }
    }
    print('Error de Dio: $e');
  } catch (e) {
    if (ref.context.mounted) {
      showErrorMessage(ref.context, ref, '${Messages.NETWORK_ERROR} $cupsServiceUrl $printerName');
    }
    print('Error de red: $e');
  } finally {
    ref.read(isPrintingProvider.notifier).state = false;
  }
}

Future<void> printPdfToCUPSDirect(WidgetRef ref, Uint8List pdfBytes, String cupsServiceUrl
    ,String documentNo,int orientation) async {
  //final cups = Uri.parse('http://192.168.188.108:631/printers/HL1200');
  print('cupsServiceUrl: $cupsServiceUrl');
  final cups = Uri.parse(cupsServiceUrl);
  try {


  await LiteIppClient.printPdf(
    cupsUri: cups,
    pdfData: Uint8List.fromList(pdfBytes),
    // username: 'cupsuser',
    // password: 'cupspass',
    options: LiteIppPrintOptions(
      jobName: documentNo,
      media: 'iso_a4_210x297mm',
      sides: 'one-sided',
      printQuality: 5,           // High
      orientationRequested: orientation,   // landscape
      fitToPage: true,
    ),
    // 測試 HTTPS 自簽時才打開：
    // allowSelfSigned: true,
  );
  if (ref.context.mounted) {
    showSuccessMessage(ref.context, ref, '${Messages.PRINT_SUCCESS} $cupsServiceUrl');
  }
  } catch (e) {
    print('Error al imprimir directamente: $e');
    if (ref.context.mounted) {
      showErrorMessage(ref.context, ref, 'Error de red : ${e.toString()}');
    }

  } finally {
    ref.read(isPrintingProvider.notifier).state = false;
  }

}