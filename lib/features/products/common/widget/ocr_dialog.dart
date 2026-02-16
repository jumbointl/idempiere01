import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

// English: OCR using Google ML Kit Text Recognition.
// Returns tokens split by whitespace/newlines (compatible with your showOCRDialog).
Future<List<String>> performOcr(BuildContext context, WidgetRef ref) async {
  final picker = ImagePicker();

  // English: Let user choose image source (camera/gallery)
  final ImageSource? source = await showModalBottomSheet<ImageSource?>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx, null),
            ),
          ],
        ),
      );
    },
  );

  if (source == null) return [];

  // English: Pick image
  final XFile? xfile = await picker.pickImage(
    source: source,
    maxWidth: 2000, // English: keep quality but avoid huge memory usage
    imageQuality: 95,
  );

  if (xfile == null) return [];

  final file = File(xfile.path);
  if (!file.existsSync()) return [];

  // English: Create ML Kit input image from file path
  final inputImage = InputImage.fromFilePath(xfile.path);

  // English: Create a TextRecognizer (Latin script works for UPC/SKU/labels).
  // If you need Japanese/Chinese recognition you may need different configs,
  // but for codes this is typically fine.
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  try {
    final RecognizedText recognizedText =
    await textRecognizer.processImage(inputImage);

    final rawText = recognizedText.text.trim();
    if (rawText.isEmpty) return [];

    // English: Split into tokens: first by lines, then by whitespace.
    final lines = rawText
        .split(RegExp(r'[\n\r]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final out = <String>[];
    for (final line in lines) {
      out.addAll(
        line.split(RegExp(r'\s+')).map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }


// English: Normalize token to improve duplicate detection
    String normalizeToken(String input) {
      return input
          .trim()
          .replaceAll(RegExp(r'[^\w\-]'), '') // remove punctuation except dash
          .toUpperCase(); // unify case
    }

    // English: De-duplicate while preserving order (robust version)
    final seen = <String>{};
    final deduped = <String>[];

    for (final t in out) {
      final normalized = normalizeToken(t);

      if (normalized.isEmpty) continue;

      if (seen.add(normalized)) {
        deduped.add(normalized);
      }
    }

    return deduped;
  } catch (e) {
    // Spanish: si querés, acá podés mostrar tu showErrorMessage(...)
    // showErrorMessage(context, ref, 'OCR error: $e');
    return [];
  } finally {
    // English: Always close the recognizer to free native resources.
    await textRecognizer.close();
  }
}
