class Environment {
  static String apiUrl = '';
  static String token = '';
  static bool validateCertificate = false;

  static Future<void> initEnvironment() async {
    // await dotenv.load(fileName: '.env');
  }

  // static String apiUrl =
  //     dotenv.env['API_URL'] ?? 'No está configurado el API_URL';

  // static bool validateCertificate =
  //     dotenv.env['VALIDATE_CERTIFICATE']?.toLowerCase() == 'true';

  

  // static String apiUrl = 'https://idempiere-dev.monalisa.com.py:8443';
  

}
