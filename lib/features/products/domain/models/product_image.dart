import 'dart:typed_data';

class ProductImage {
  final String fileName;
  final Uint8List bytes;          // 原圖
  final Uint8List thumbnailBytes; // 縮圖 (優化清單顯示)
  final bool isLocal;

  ProductImage({
    required this.fileName,
    required this.bytes,
    required this.thumbnailBytes,
    this.isLocal = false
  });
}
