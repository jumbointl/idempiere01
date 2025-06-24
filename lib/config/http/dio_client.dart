import 'package:dio/dio.dart';
import '../constants/environment.dart';
import 'dio_config.dart';

class DioClient {
  static Future<Dio> create() async {
    final dio = Dio(BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final validateCertificate = Environment
        .validateCertificate; // true en producción, false en desarrollo
    await DioConfiguration.configureDio(
      dio,
      validateCertificate: validateCertificate,
      certificatePath:
          validateCertificate ? 'assets/certificates/my_certificate.pem' : null,
    );

    // Agregar interceptor para incluir el token en todas las peticiones
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (Environment.apiUrl.isEmpty) {
          return handler.reject(DioException(
            requestOptions: options,
            error: 'urlApi',
            message: 'API URL no configurada',
          ));
        }
        options.baseUrl = Environment.apiUrl;
        final token = Environment.token;
        options.headers['Authorization'] = 'Bearer $token';
        options.headers['Accept'] = 'application/json';
        return handler.next(options); // continuar con la solicitud
      },
    ));

    return dio;
  }
}
