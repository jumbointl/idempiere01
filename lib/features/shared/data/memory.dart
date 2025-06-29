import 'package:intl/intl.dart';

class Memory {
  static const int  TOKEN_EXPIRE_MINUTES = 720;

  static const int REFRESH_TOKEN_EXPIRE_MINUTES = 1200;

  static final numberFormatter2Digit = NumberFormat.decimalPatternDigits
    (locale: 'es_PY',decimalDigits: 2);
  
}