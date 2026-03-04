import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image_v2/flutter_native_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:image/image.dart' as img_lib;
import 'package:monalisa_app_001/features/products/presentation/providers/ai/upload_service.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/models/product_image.dart';
import '../common_provider.dart';
import 'global_providers.dart';

// 使用 .family 以便針對不同的 productId 建立獨立的 Provider
final productGalleryProvider = StateNotifierProvider.family<ProductGalleryNotifier, List<ProductImage>, String>((ref, productId) {
  return ProductGalleryNotifier(productId: productId, ref: ref);
});
final selectedImageIndexProvider = StateProvider<int>((ref) => 0);
class ProductGalleryNotifier extends StateNotifier<List<ProductImage>> {
  final String productId;
  final Ref ref;
  ProductGalleryNotifier({required this.productId, required this.ref}) : super([]);

  // 核心下載邏輯：自動判斷 DEV (FTP) 或 PROD (S3)
  Future<void> fetchRemoteImages() async {
    if (APP_ENV == 'PROD') {
      await _fetchFromS3();
    } else {
      await _fetchFromFtp();
    }
  }
  Future<void> _fetchFromFtp() async {
    final config = ref.read(ftpConfigProvider);
    ref.read(aiLoadingProvider.notifier).state =
        LoadingState(isLoading: true, message: "DOWNLOADING IMAGES...");

    final ftp = FTPConnect(
      config.host,
      user: config.user,
      pass: config.pass,
      port: config.port,
      timeout: 60,

    );
    bool _looksLikeImage(Uint8List b, String name) {
      if (b.length < 12) return false;

      final isPng = b[0] == 0x89 &&
          b[1] == 0x50 &&
          b[2] == 0x4E &&
          b[3] == 0x47 &&
          b[4] == 0x0D &&
          b[5] == 0x0A &&
          b[6] == 0x1A &&
          b[7] == 0x0A;

      final isJpg = b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

      final extOk = name.toLowerCase().endsWith('.png') || name.toLowerCase().endsWith('.jpg') || name.toLowerCase().endsWith('.jpeg');
      return extOk && (isPng || isJpg);
    }

    try {
      await ftp.connect();
      await ftp.sendCustomCommand("TYPE I");
      debugPrint("FTP CONNECTED PASSIVE");

      // Si tu versión soporta binario, actívalo:
      // ftp.transferType = TransferType.binary;
      // await ftp.setTransferType(TransferType.binary);

      await ftp.changeDirectory('/');

      final dirOk = await ftp.changeDirectory('products/$productId');
      debugPrint("FTP CHANGE DIR: $dirOk");
      if (!dirOk) {
        state = [];
        return;
      }

      final files = await ftp.listDirectoryContent();
      debugPrint("FTP FILES: ${files.length}");

      final tempDir = await getTemporaryDirectory();
      final loadedImages = <ProductImage>[];

      for (final entry in files) {
        final name = entry.name;

        final lower = name.toLowerCase();
        final isImage = lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg');
        if (!isImage) continue;

        final tempFile = File('${tempDir.path}/$name');
        debugPrint("FTP DOWNLOADING: $name -> ${tempFile.path}");

        final ok = await ftp.downloadFile(name, tempFile);
        if (!ok) {
          debugPrint("COULD NOT DOWNLOAD: $name");
          continue;
        }

        final size = await tempFile.length();
        debugPrint("FTP DOWNLOADED: $name ($size bytes)");
        if (size <= 0) {
          debugPrint("ERROR: FILE $name IS EMPTY");
          if (await tempFile.exists()) await tempFile.delete();
          continue;
        }

        final bytes = await tempFile.readAsBytes();
        if (!_looksLikeImage(bytes, name)) {
          debugPrint("ERROR: $name IS NOT A VALID PNG/JPG. "
              "FIRST BYTES=${bytes.take(16).toList()} SIZE=$size");
          if (await tempFile.exists()) await tempFile.delete();
          continue;
        }

        loadedImages.add(ProductImage(
          fileName: name,
          bytes: bytes,
          thumbnailBytes: bytes, // luego puedes generar thumbnail real
          isLocal: false,
        ));

        if (await tempFile.exists()) await tempFile.delete();
      }

      state = loadedImages;
    } catch (e) {
      ref.read(errorProvider.notifier).state =
      "DOWNLOAD FAILED: ${e.toString().toUpperCase()}";
    } finally {
      await ftp.disconnect();
      ref.read(aiLoadingProvider.notifier).state =
          LoadingState(isLoading: false, message: "DOWNLOAD FINISHED");
    }
  }


  Future<void> _fetchFromFtpOld() async {
    final config = ref.read(ftpConfigProvider);

    final ftp = FTPConnect(
        config.host,
        user: config.user,
        pass: config.pass,
        port: config.port
    );
    try {
      await ftp.connect();
      await ftp.changeDirectory('products/$productId');

      final List<FTPEntry> files = await ftp.listDirectoryContent();
      List<ProductImage> loadedImages = [];

      // Directorio temporal para la descarga
      final tempDir = await getTemporaryDirectory();

      for (var file in files) {
        if (file.name.endsWith('.png') || file.name.endsWith('.jpg')) {
          final File tempFile = File('${tempDir.path}/${file.name}');

          // MÉTODO CORRECTO: downloadFile(String name, File target)
          bool downloaded = await ftp.downloadFile(file.name, tempFile);

          if (downloaded) {
            final Uint8List bytes = await tempFile.readAsBytes();

            // GENERAR PRODUCT IMAGE CON THUMBNAIL
            loadedImages.add(await _createProductImage(file.name, tempFile));

            // LIMPIEZA: borrar archivo temporal
            await tempFile.delete();
          }
        }
      }
      state = loadedImages;
    } catch (e) {
      ref.read(errorProvider.notifier).state = "FTP DOWNLOAD ERROR: $e";
    } finally {
      await ftp.disconnect();
    }
  }


  Future<void> _fetchFromS3() async {
    final dio = Dio();
    // ASEGURAR QUE S3_URL ESTÉ DEFINIDA EN ANDROID STUDIO (DART DEFINE)
    final String s3BucketUrl = const String.fromEnvironment('S3_URL');
    final tempDir = await getTemporaryDirectory();

    try {
      final response = await dio.get("$s3BucketUrl/api/list-products/$productId");

      if (response.statusCode == 200) {
        List<dynamic> fileList = response.data['files'];
        List<ProductImage> loadedImages = [];

        for (var fileInfo in fileList) {
          String fileName = fileInfo['name'];
          final imgRes = await dio.get(
            "$s3BucketUrl/products/$productId/$fileName",
            options: Options(responseType: ResponseType.bytes),
          );

          if (imgRes.data != null) {
            final Uint8List bytes = Uint8List.fromList(imgRes.data);

            // 1. ESCRIBIR A ARCHIVO TEMPORAL (Necesario para el resize nativo)
            final File tempFile = File('${tempDir.path}/s3_$fileName');
            await tempFile.writeAsBytes(bytes, flush: true);

            // 2. USAR LA FUNCIÓN NATIVA QUE NO SE TRANCA
            // Pasa el File directamente a la función que usa FlutterNativeImage
            final productImage = await _createProductImage(fileName, tempFile);
            loadedImages.add(productImage);

            // 3. LIMPIEZA
            if (await tempFile.exists()) await tempFile.delete();
          }
        }
        state = loadedImages;
      }
    } catch (e) {
      debugPrint("S3 FETCH ERROR: $e");
      // Mensaje de error en ALL CAPS
      ref.read(errorProvider.notifier).state = "S3 DOWNLOAD ERROR: ${e.toString().toUpperCase()}";
    }
  }

  Future<ProductImage> _createProductImage(String name, File tempFile) async {
    debugPrint("NATIVE RESIZE START: $name");

    // 1. OBTENER BYTES ORIGINALES (Para el editor AI)
    final Uint8List originalBytes = await tempFile.readAsBytes();
    debugPrint("NATIVE RESIZE original: $name");


    // 2. REDIMENSIONAR NATIVAMENTE (Mucho más rápido que img_lib)
    // Genera un nuevo archivo temporal ya redimensionado
    debugPrint("NATIVE RESIZE start");
    File thumbnailFile = await FlutterNativeImage.compressImage(
      tempFile.path,
      quality: 70,
      percentage: 10, // O usa targetWidth: 150
      targetWidth: 150,
    );
    debugPrint("NATIVE RESIZE thumbnail end: $name");

    // 3. LEER BYTES DE LA MINIATURA
    final Uint8List thumbBytes = await thumbnailFile.readAsBytes();

    // Limpiar el archivo de miniatura temporal
    await thumbnailFile.delete();

    debugPrint("NATIVE RESIZE FINISHED: $name");

    return ProductImage(
      fileName: name,
      bytes: originalBytes,
      thumbnailBytes: thumbBytes ,
      isLocal: false,
    );
  }

  // 輔助函式：生成縮圖並包裝成物件
  Future<ProductImage> _createProductImageOld(String name, Uint8List bytes) async {
    debugPrint("CREATE PRODUCT IMAGE: $name");
    return await compute(processImageInIsolate, {
      'name': name,
      'bytes': bytes,
    });

    /*
    final original = img_lib.decodeImage(bytes);
    debugPrint("CREATE PRODUCT IMAGE original: $original");


    final thumbnail = img_lib.copyResize(original!, width: 150);
    debugPrint("CREATE PRODUCT IMAGE 2: $thumbnail");

    return ProductImage(
      fileName: name,
      bytes: bytes,
      thumbnailBytes: Uint8List.fromList(img_lib.encodeJpg(thumbnail)),
      isLocal: false,
    );*/
  }

  // 刪除功能
  Future<void> deleteImage(String fileName) async {
    // 實作 FTP 或 S3 的刪除邏輯...
    state = state.where((img) => img.fileName != fileName).toList();
  }
}


ProductImage processImageInIsolate(Map<String, dynamic> data) {
  final String name = data['name'];
  final Uint8List bytes = data['bytes'];
  debugPrint("processImageInIsolate CREATE PRODUCT IMAGE: $name");
  // DECODE (Aquí es donde se trancaba)
  final original = img_lib.decodeImage(bytes);
  debugPrint("processImageInIsolate create original: $name");
  if (original == null) throw Exception("COULD NOT DECODE IMAGE");
  debugPrint("processImageInIsolate original created: $name");
  // RESIZE PARA THUMBNAIL
  final thumbnail = img_lib.copyResize(original, width: 150);
  debugPrint("processImageInIsolate thumbnail: $name");

  return ProductImage(
    fileName: name,
    bytes: bytes,
    thumbnailBytes: Uint8List.fromList(img_lib.encodeJpg(thumbnail)),
    isLocal: false,
  );
}
