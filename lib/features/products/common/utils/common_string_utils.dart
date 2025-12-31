import 'package:dio/dio.dart';

import '../../../shared/data/messages.dart';

String zplSafe(String s) => s
    .replaceAll('^', ' ')
    .replaceAll('~', ' ')
    .replaceAll('\n', ' ')
    .replaceAll('\r', ' ')
    .trim();

String truncateEllipsis(String s, int maxChars) {
  final t = s.trim();
  if (maxChars <= 0) return '';
  if (t.length <= maxChars) return t;
  if (maxChars == 1) return '…';
  return '${t.substring(0, maxChars - 1)}…';
}
String sanitizeJsonText(String input) {
  return input
      .replaceAll('\uFEFF', '')
      .replaceAll('\u200B', '')
      .replaceAll('\u200C', '')
      .replaceAll('\u200D', '')
      .replaceAll('\u2060', '')
      .trim();
}

String mapDioErrorToMessage(DioException e) {
  // English: Normalize Dio errors for UI consumption
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return Messages.CONNECTION_TIMEOUT;
    case DioExceptionType.receiveTimeout:
      return Messages.SERVER_TIMEOUT;
    case DioExceptionType.badResponse:
      return 'HTTP ${e.response?.statusCode ?? ''}';
    case DioExceptionType.connectionError:
      return Messages.NO_INTERNET;
    default:
      return Messages.UNEXPECTED_ERROR;
  }
}
