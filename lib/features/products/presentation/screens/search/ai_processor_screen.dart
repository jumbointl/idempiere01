import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img_lib;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../providers/ai/gallery_provider.dart';
import '../../providers/ai/global_providers.dart';

class AiProcessorScreen extends ConsumerStatefulWidget {
  final String productId;
  final dynamic initialImage; // ProductImage

  const AiProcessorScreen({super.key, required this.productId, this.initialImage});

  @override
  ConsumerState<AiProcessorScreen> createState() => _AiProcessorScreenState();
}

class _AiProcessorScreenState extends ConsumerState<AiProcessorScreen> {
  Uint8List? _currentData;
  bool _isAiProcessed = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _currentData = widget.initialImage!.bytes;
    }
  }

  // --- ACCIÓN: SELECCIONAR IMAGEN ---
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;
    final bytes = await pickedFile.readAsBytes();
    setState(() {
      _currentData = bytes;
      _isAiProcessed = false; // Nueva imagen, reset IA
    });
  }

  // --- ACCIÓN: PROCESAR CON AI (OPCIONAL) ---
  Future<void> _processWithAi() async {
    if (_currentData == null) return;
    final loading = ref.read(aiLoadingProvider.notifier);
    loading.show("AI EXTRACTING SUBJECT...");

    try {
      // Necesitamos guardar a temp para ML Kit
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ai_temp.png');
      await tempFile.writeAsBytes(_currentData!);

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final segmenter = SubjectSegmenter(options:
      SubjectSegmenterOptions(enableForegroundBitmap: true,
          enableForegroundConfidenceMask: true,
          enableMultipleSubjects: SubjectResultOptions(
              enableConfidenceMask: true,
              enableSubjectBitmap: true)));
      final result = await segmenter.processImage(inputImage);

      if (result.subjects.isNotEmpty && result.subjects.first.bitmap != null) {
        setState(() {
          _currentData = result.subjects.first.bitmap;
          _isAiProcessed = true;
        });
      }
      segmenter.close();
    } catch (e) {
      ref.read(errorProvider.notifier).state = "AI ERROR: $e";
    } finally {
      loading.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(aiLoadingProvider);

    return PopScope(
      canPop: !loading.isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('AI PROCESSOR')),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // AREA DE VISUALIZACIÓN
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: _isAiProcessed ? Colors.green : Colors.grey),
                    ),
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(top: 15, left: 20, right: 20,bottom: 15),
                      child: _currentData != null
                          ? Image.memory(_currentData!)
                          : const Center(child: Text("NO IMAGE SELECTED")),
                    ),
                  ),
              
                  // BARRA DE HERRAMIENTAS (ZOOM / EDIT / AI)
                  if (_currentData != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionButton(
                            icon: Icons.auto_awesome,
                            label: "PROCESS WITH AI",
                            color: Colors.purple,
                            onPressed: _isAiProcessed ? null : _processWithAi,
                          ),
                          _ActionButton(
                            icon: Icons.crop,
                            label: "ZOOM / CUT",
                            color: Colors.blue.shade900,
                            onPressed: _cropImage,
                          ),
                        ],
                      ),
                    ),
              
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(child: _SourceButton(Icons.camera_alt, "CAMERA", () => _pickImage(ImageSource.camera))),
                        const SizedBox(width: 5),
                        Expanded(child: _SourceButton(Icons.photo_library, "GALLERY", () => _pickImage(ImageSource.gallery))),
                        const SizedBox(width: 5),
                        Expanded(child: _SourceButton(Icons.language, "URL", () { /* Lógica URL */ })),
                      ],
                    ),
                  ),
              
                  // BOTON FINAL DE SUBIDA
                  if (_currentData != null)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          final loadingNotif = ref.read(aiLoadingProvider.notifier);
                          loadingNotif.show("APPLYING CANVAS & UPLOADING...");
                          late String fileName ;
                          if(widget.initialImage!=null){
                            fileName = widget.initialImage!.fileName;
                          }else{
                            final images = ref.read(productGalleryProvider(widget.productId));
                            fileName = "${widget.productId}_${images.length+1}.jpg";
                          }


                          try {
                            // APLICAR CANVAS BLANCO 400x300 CON MARGENES
                            final finalBytes = _applyCanvasAndResize(_currentData!);

                            // Lógica de Upload a FTP/S3 (Ya definida antes)
                            final success = await ref.read(uploadServiceProvider).uploadImage(
                                finalBytes,
                                fileName,
                                widget.productId
                            );
              
                            if (success && context.mounted) context.pop(true);
                          } finally {
                            loadingNotif.hide();
                          }
                        },
                        child: const Text("UPLOAD AND SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),

            // LOADING OVERLAY
            if (loading.isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 15),
                      Text(loading.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Uint8List _applyCanvasAndResize(Uint8List originalBytes) {
    final image = img_lib.decodeImage(originalBytes);
    if (image == null) return originalBytes;

    // 1. Redimensionar conservando el ASPECT RATIO
    // Al poner uno de los valores en 0 o null, la librería calcula
    // automáticamente la otra dimensión para no deformar la imagen.
    final innerImage = img_lib.copyResize(
      image,
      width: (image.width > image.height) ? 400 : null,
      height: (image.height >= image.width) ? 300 : null,
      interpolation: img_lib.Interpolation.cubic,
    );

    // Verificamos que no se pase de los límites (Safety Check)
    final finalInner = (innerImage.width > 400 || innerImage.height > 300)
        ? img_lib.copyResize(innerImage, width: 400, height: 300, maintainAspect: true)
        : innerImage;

    // 2. Crear Canvas Blanco de 440x330 (ALL CAPS BACKGROUND)
    final canvas = img_lib.Image(width: 440, height: 330);
    img_lib.fill(canvas, color: img_lib.ColorRgb8(255, 255, 255));

    // 3. Calcular el centro exacto para centrar el producto dentro del canvas
    // Margen base (20, 15) + el ajuste para centrar si la foto es más pequeña
    final int dstX = 20 + ((400 - finalInner.width) ~/ 2);
    final int dstY = 15 + ((300 - finalInner.height) ~/ 2);

    // 4. Dibujar el producto centrado
    img_lib.compositeImage(
        canvas,
        finalInner,
        dstX: dstX,
        dstY: dstY
    );

    return Uint8List.fromList(img_lib.encodeJpg(canvas, quality: 90));
  }

  Future<void> _cropImage() async {
    if (_currentData == null) return;

    // Guardar a temp para el cropper
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/crop_temp.png');
    await tempFile.writeAsBytes(_currentData!);

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: tempFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'ZOOM / CUT PHOTO',
          toolbarColor: Colors.blue.shade800,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.ratio4x3,
          lockAspectRatio: true, // Bloquear para que siempre sea 4:3
        ),
      ],
    );

    if (croppedFile != null) {
      final bytes = await croppedFile.readAsBytes();
      setState(() {
        _currentData = bytes;
        _isAiProcessed = false; // Resetear estado IA si se recortó
      });
    }
  }


}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 10)),
      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  const _ActionButton({required this.icon, required this.label, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
