// lib/lite_ipp_print.dart
//
// 極簡 IPP Print-Job 實作：將 PDF 送到 CUPS。
// 支援：HTTP/HTTPS、Basic Auth（用 userInfo 或參數）、自簽憑證測試。
// 僅實作 Print-Job 必要欄位 + 少量常見 Job 屬性。
// 免第三方套件。

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class LiteIppPrintOptions {
  static const int PRINTER_ORIENTATION_PORTRAIT = 3;
  static const int PRINTER_ORIENTATION_LANDSCAPE = 4;
  static const int PRINTER_ORIENTATION_REVERSE_PORTRAIT = 5;
  static const int PRINTER_ORIENTATION_REVERSE_LANDSCAPE = 6;

  final String jobName;               // 列印工作名稱
  final String media;                 // 紙張（例：'iso_a4_210x297mm'、'na_letter_8.5x11in'）
  final String sides;                 // 'one-sided' | 'two-sided-long-edge' | 'two-sided-short-edge'
  final int? printQuality;            // 3=Draft, 4=Normal, 5=High（IPP enum）
  final int? orientationRequested;    // 3=portrait, 4=landscape, 5=rev-portrait, 6=rev-landscape
  final bool fitToPage;               // 是否縮放適配紙張
  final String documentFormat;        // 預設 application/pdf
  final String requestingUserName;    // 顯示在 CUPS 的使用者名稱

  const LiteIppPrintOptions({
    this.jobName = 'Flutter PDF Job',
    this.media = 'iso_a4_210x297mm',
    this.sides = 'one-sided',
    this.printQuality,
    this.orientationRequested,
    this.fitToPage = true,
    this.documentFormat = 'application/pdf',
    this.requestingUserName = 'flutter',
  });
}

class LiteIppClient {
  /// 將 PDF bytes 送到 CUPS 的 IPP 端點，例如：
  ///   http://192.168.1.50:631/printers/HP_LaserJet
  ///   https://cups.local:631/printers/Office
  ///
  /// 若需要 Basic Auth，可：
  ///   1) 在 cupsUri 使用 userInfo: https://user:pass@host:631/printers/...
  ///   2) 或傳入 username/password 參數。
  ///
  /// [allowSelfSigned] 僅建議測試環境使用（HTTPS 自簽）。
  static Future<void> printPdf({
    required Uri cupsUri,
    required Uint8List pdfData,
    String? username,
    String? password,
    bool allowSelfSigned = false,
    LiteIppPrintOptions options = const LiteIppPrintOptions(),
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (cupsUri.scheme != 'http' && cupsUri.scheme != 'https') {
      throw ArgumentError('cupsUri debe ser http/https：$cupsUri');
    }

    final httpClient = HttpClient();
    if (allowSelfSigned && cupsUri.scheme == 'https') {
      httpClient.badCertificateCallback = (cert, host, port) => true;
    }

    // 如果 URI 沒包含 userInfo，嘗試用參數傳入帳密。
    final authUserInfo = (cupsUri.userInfo.isNotEmpty)
        ? cupsUri.userInfo
        : (username != null && password != null)
        ? '$username:$password'
        : null;

    // 建構 IPP Print-Job 要求的二進位內容
    final ippPayload = _buildIppPrintJobRequest(
      cupsUri: cupsUri,
      pdfData: pdfData,
      options: options,
      authUser: (authUserInfo != null) ? authUserInfo.split(':').first : options.requestingUserName,
    );

    final request = await httpClient.postUrl(cupsUri).timeout(timeout);

    // Basic Auth（若必要）
    if (authUserInfo != null && cupsUri.userInfo.isEmpty) {
      final basic = base64Encode(utf8.encode(authUserInfo));
      request.headers.add(HttpHeaders.authorizationHeader, 'Basic $basic');
    }

    request.headers.contentType = ContentType('application', 'ipp'); // application/ipp
    request.headers.contentLength = ippPayload.length;

    request.add(ippPayload);
    final response = await request.close().timeout(timeout);

    final respBytes = await consolidateHttpClientResponseBytes(response);
    httpClient.close();

    if (response.statusCode != 200) {
      throw HttpException(
        'HTTP ${response.statusCode} ${response.reasonPhrase}\n${utf8.decode(respBytes, allowMalformed: true)}',
        uri: cupsUri,
      );
    }

    // 解析 IPP 回應的狀態碼（前 8 bytes 包含 version + status + requestId）
    if (respBytes.length < 8) {
      throw Exception('IPP 回應長度異常（< 8 bytes）');
    }
    final statusCode = _readUint16(respBytes, 2); // 位移 2～3
    // IPP 成功範圍：0x0000～0x0003（success-ok 等）
    if (statusCode > 0x0003) {
      // 簡易錯誤說明
      final msg = _guessIppStatus(statusCode);
      throw Exception('IPP 列印失敗：0x${statusCode.toRadixString(16)} $msg');
    }
  }

  // ------------------ IPP Binary Encoding（最小子集） ------------------

  static Uint8List _buildIppPrintJobRequest({
    required Uri cupsUri,
    required Uint8List pdfData,
    required LiteIppPrintOptions options,
    String? authUser,
  }) {
    final bytes = BytesBuilder();

    // IPP Header
    // version-number: 0x02 0x00 (IPP 2.0)
    bytes.add([0x02, 0x00]);

    // operation-id: Print-Job = 0x0002
    bytes.add(_u16(0x0002));

    // request-id (任意非 0)
    final reqId = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    bytes.add(_u32(reqId));

    // Operation Attributes Group
    bytes.add([0x01]); // operation-attributes-tag

    // attributes-charset (charset) -> 'utf-8'
    _writeAttribute(
      bytes: bytes,
      valueTag: 0x47, // charset
      name: 'attributes-charset',
      valueUtf8: 'utf-8',
    );

    // attributes-natural-language (naturalLanguage) -> 'en'
    _writeAttribute(
      bytes: bytes,
      valueTag: 0x48, // naturalLanguage
      name: 'attributes-natural-language',
      valueUtf8: 'en',
    );

    // printer-uri (uri)
    _writeAttribute(
      bytes: bytes,
      valueTag: 0x45, // uri
      name: 'printer-uri',
      valueUtf8: cupsUri.toString(),
    );

    // requesting-user-name (nameWithoutLanguage)
    _writeAttribute(
      bytes: bytes,
      valueTag: 0x42, // nameWithoutLanguage
      name: 'requesting-user-name',
      valueUtf8: (authUser ?? options.requestingUserName),
    );

    // job-name (nameWithoutLanguage)
    _writeAttribute(
      bytes: bytes,
      valueTag: 0x42,
      name: 'job-name',
      valueUtf8: options.jobName,
    );

    // document-format (mimeMediaType)
    _writeAttribute(
      bytes: bytes,
      valueTag: 0x49, // mimeMediaType
      name: 'document-format',
      valueUtf8: options.documentFormat, // 'application/pdf'
    );

    // Job Attributes Group
    bytes.add([0x02]); // job-attributes-tag

    // media (keyword)
    _writeAttribute(
      bytes: bytes,
      valueTag: 0x44, // keyword
      name: 'media',
      valueUtf8: options.media,
    );

    // sides (keyword)
    _writeAttribute(
      bytes: bytes,
      valueTag: 0x44, // keyword
      name: 'sides',
      valueUtf8: options.sides,
    );

    // print-quality (enum) 3/4/5（可選）
    if (options.printQuality != null) {
      _writeAttributeEnum(
        bytes: bytes,
        name: 'print-quality',
        enumValue: options.printQuality!,
      );
    }

    // orientation-requested (enum) 3/4/5/6（可選）
    if (options.orientationRequested != null) {
      _writeAttributeEnum(
        bytes: bytes,
        name: 'orientation-requested',
        enumValue: options.orientationRequested!,
      );
    }

    // fit-to-page（非標準化：許多 CUPS 驅動接受 'print-scaling' keyword）
    if (options.fitToPage) {
      _writeAttribute(
        bytes: bytes,
        valueTag: 0x44, // keyword
        name: 'print-scaling',
        valueUtf8: 'fill', // 常見值：'auto' | 'auto-fit' | 'fill' | 'fit'（視驅動）
      );
    }

    // end-of-attributes-tag
    bytes.add([0x03]);

    // document data (PDF)
    bytes.add(pdfData);

    return bytes.toBytes();
  }

  static void _writeAttribute({
    required BytesBuilder bytes,
    required int valueTag,
    required String name,
    required String valueUtf8,
  }) {
    final nameBytes = utf8.encode(name);
    final valBytes = utf8.encode(valueUtf8);

    bytes.add([valueTag]);
    bytes.add(_u16(nameBytes.length));
    bytes.add(nameBytes);
    bytes.add(_u16(valBytes.length));
    bytes.add(valBytes);
  }

  static void _writeAttributeEnum({
    required BytesBuilder bytes,
    required String name,
    required int enumValue,
  }) {
    final nameBytes = utf8.encode(name);
    bytes.add([0x23]); // enum
    bytes.add(_u16(nameBytes.length));
    bytes.add(nameBytes);
    bytes.add(_u16(4)); // enum = 4 bytes
    bytes.add(_u32(enumValue));
  }

  static List<int> _u16(int v) => [(v >> 8) & 0xff, v & 0xff];
  static List<int> _u32(int v) => [
    (v >> 24) & 0xff,
    (v >> 16) & 0xff,
    (v >> 8) & 0xff,
    v & 0xff,
  ];

  static int _readUint16(Uint8List data, int offset) {
    return (data[offset] << 8) | data[offset + 1];
  }

  static String _guessIppStatus(int code) {
    // 常見錯誤代碼對照（簡化）
    switch (code) {
      case 0x0400:
        return 'client-error-bad-request';
      case 0x0401:
        return 'client-error-forbidden';
      case 0x0402:
        return 'client-error-not-authenticated';
      case 0x0403:
        return 'client-error-not-authorized';
      case 0x0405:
        return 'client-error-not-found';
      case 0x040C:
        return 'client-error-document-format-not-supported';
      case 0x0500:
        return 'server-error-internal-error';
      case 0x0502:
        return 'server-error-service-unavailable';
      default:
        return 'IPP status 0x${code.toRadixString(16)}';
    }
  }
}
