import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/ftpconfig.dart';

const String APP_ENV = String.fromEnvironment('ENV', defaultValue: 'DEV');
abstract class UploadService {
  Future<bool> uploadImage(Uint8List bytes, String fileName, String productId);
}

class FtpUploadService implements UploadService {
  final FtpConfig config;

  FtpUploadService(this.config);

  @override
  Future<bool> uploadImage(Uint8List bytes, String fileName, String productId) async {
    final ftp = FTPConnect(
      config.host,
      user: config.user,
      pass: config.pass,
      port: config.port,
      timeout: 60,
    );

    try {
      await ftp.connect();
      // Lógica de directorios products/productId/ ...
      await ftp.sendCustomCommand("TYPE I");
      await ftp.createFolderIfNotExist('products');
      await ftp.changeDirectory('products');
      await ftp.createFolderIfNotExist(productId);
      await ftp.changeDirectory(productId);

      final tempDir = await getTemporaryDirectory();
      final tempFile = await File('${tempDir.path}/$fileName').writeAsBytes(bytes,flush: true);
      bool success = await ftp.uploadFile(tempFile);
      if (await tempFile.exists()) await tempFile.delete();

      return success;
    } catch (e) {
      return false;
    } finally {
      await ftp.disconnect();
    }
  }
}



class S3UploadService implements UploadService {
  @override
  Future<bool> uploadImage(Uint8List bytes, String fileName, String productId) async {
    final dio = Dio();

    // 定義 S3 的完整路徑結構
    // 格式：https://[BUCKET_NAME].s3.[REGION]://[PRODUCT_ID]/[FILENAME]
    // 注意：在實務中，這個 URL 通常是由您的後端 API 產生的 Presigned URL
    final String s3Endpoint = const String.fromEnvironment('S3_URL',
        defaultValue: 'https://your-bucket.s3.amazonaws.com');

    final String fullUploadUrl = "$s3Endpoint/products/$productId/$fileName";

    print("UPLOADING TO AWS S3: $fullUploadUrl");

    try {
      final response = await dio.put(
        fullUploadUrl,
        data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: {
            "Content-Type": "image/png",
            "Content-Length": bytes.length,
            // 如果是使用 AWS 公開權限（不建議，建議用 Presigned URL）
            // "x-amz-acl": "public-read",
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("AWS S3 UPLOAD ERROR: $e");
      return false;
    }
  }
}
