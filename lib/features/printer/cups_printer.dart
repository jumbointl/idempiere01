import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../products/presentation/providers/common_provider.dart';

// Re-export the package transport functions so existing app callers keep
// working without touching their imports.
export 'package:monalisapy_features/printer/transport/cups_transport.dart'
    show printPdfToCUPSDirect, sendPdfToNode;

/// App-specific logo loader. Lives in the host app because the asset path
/// is app-defined.
Future<Uint8List> get imageLogo async {
  final ByteData bytes = await rootBundle.load('assets/images/logo-monalisa.jpg');
  return bytes.buffer.asUint8List();
}

/// Dio-flavoured PDF uploader (app-only — not used by the package). Kept
/// here because it surfaces toasts via the app's [Messages] strings.
Future<void> sendPdfToNodeDio(WidgetRef ref, Uint8List pdfBytes,
    String cupsServiceUrl, String printerName) async {
  print('Enviando archivo PDF a $cupsServiceUrl con Dio');

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
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
        showSuccessMessage(ref.context, ref,
            '${Messages.PRINT_SUCCESS} $cupsServiceUrl $printerName');
      }
      print('Archivo PDF enviado exitosamente al servicio de impresión.');
    } else {
      if (ref.context.mounted) {
        showErrorMessage(
            ref.context, ref, '${Messages.PRINT_FAILED} ${response.statusCode}');
      }
      print('Error al enviar el archivo: ${response.statusCode}');
    }
  } on DioException catch (e) {
    if (ref.context.mounted) {
      if (e.type == DioExceptionType.connectionTimeout) {
        showErrorMessage(ref.context, ref,
            'Tiempo de espera agotado. Verifique la conexión.');
      } else {
        showErrorMessage(ref.context, ref, 'Error de red con Dio: ${e.message}');
      }
    }
    print('Error de Dio: $e');
  } catch (e) {
    if (ref.context.mounted) {
      showErrorMessage(
          ref.context, ref, '${Messages.NETWORK_ERROR} $cupsServiceUrl $printerName');
    }
    print('Error de red: $e');
  } finally {
    ref.read(isPrintingProvider.notifier).state = false;
  }
}
