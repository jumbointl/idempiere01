import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';

class DioConfiguration {
  static Future<void> configureDio(Dio dio,
      {bool validateCertificate = true, String? certificatePath}) async {
    try {
      final adapter = IOHttpClientAdapter();

      if (validateCertificate && certificatePath != null) {
        final cert = await rootBundle.load(certificatePath);
        final certBytes = cert.buffer.asUint8List();

        final securityContext = SecurityContext(withTrustedRoots: false);
        securityContext.setTrustedCertificatesBytes(certBytes);

        adapter.createHttpClient = () => HttpClient(context: securityContext);
      } else {
        adapter.createHttpClient = () => HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
      }

      dio.httpClientAdapter = adapter;
    } catch (e) {
      print('Error al configurar Dio: $e');
      rethrow;
    }
  }
}
