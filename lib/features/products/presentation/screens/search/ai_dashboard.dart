import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import '../../../../../config/router/app_router.dart';
import '../../providers/ai/gallery_provider.dart';
import '../../providers/ai/global_providers.dart';

class AiDashboardScreen extends ConsumerStatefulWidget {
  final String productId;
  bool? forceRefresh;

  AiDashboardScreen({super.key, required this.productId,this.forceRefresh});

  @override
  ConsumerState<AiDashboardScreen> createState() => _AiDashboardScreenState();
}

class _AiDashboardScreenState extends ConsumerState<AiDashboardScreen> {
  bool _loadImagen = false;


  @override
  void initState() {
    super.initState();
    if(widget.forceRefresh != null && widget.forceRefresh! &&
        !_loadImagen && widget.productId.isNotEmpty){

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadImagen = true ;
        String productId = widget.productId;
        if(productId.isNotEmpty){
          ref.read(productGalleryProvider(productId).notifier).fetchRemoteImages();
        }
      });
    }


  }

  @override
  Widget build(BuildContext context) {
    // ESCUCHA LA LISTA DE IMÁGENES DEL PRODUCTO
    final images = ref.watch(productGalleryProvider(widget.productId));
    final notifier = ref.read(productGalleryProvider(widget.productId).notifier);


    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        //leading: Icon(Icons.image,color: themeColorPrimary,),
        title:  ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColorPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            // NAVEGA AL PROCESADOR SIN IMAGEN (NUEVA FOTO)
            goToAiProcessorScreen(context, ref);

          },
          icon: const Icon(Icons.add_a_photo),
          label: const Text(
            'ADD NEW PRODUCT PHOTO',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,color: Colors.purple,),
            onPressed: () { notifier.fetchRemoteImages();},
          )
        ],
      ),
      body: images.isEmpty
          ? const Center(
        child: Text(
          'NO PHOTOS FOUND FOR THIS PRODUCT',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      )
          : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final img = images[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8),
              // MUESTRA LA 縮圖 (THUMBNAIL) PARA AHORRAR MEMORIA
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  img.thumbnailBytes,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  cacheWidth: 150, // OPTIMIZACIÓN DE RENDERIZADO EN ANDROID
                ),
              ),
              title: Text(
                img.fileName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('TAP TO EDIT WITH AI'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: () => _confirmDelete(context, ref, img.fileName),
              ),
              onTap: () async {
                // NAVEGA AL PROCESADOR PASANDO LA IMAGEN EXISTENTE (EDITAR)
                ref.read(selectedImageIndexProvider.notifier).state = index;
                final result = await context.push<dynamic>(
                  '${AppRouter.PAGE_AI_PROCESSOR}/${widget.productId}',
                  extra: img,
                );
                // SI HUBO CAMBIOS, REFRESCAR LISTA
                if (result != null) notifier.fetchRemoteImages();
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColorPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            // NAVEGA AL PROCESADOR SIN IMAGEN (NUEVA FOTO)
            goToAiProcessorScreen(context, ref);

          },
          icon: const Icon(Icons.add_a_photo),
          label: const Text(
            'ADD NEW PRODUCT PHOTO',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // DIÁLOGO DE CONFIRMACIÓN DE ELIMINACIÓN EN ALL CAPS
  void _confirmDelete(BuildContext context, WidgetRef ref, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CONFIRM DELETE'),
        content: Text('ARE YOU SURE YOU WANT TO DELETE $fileName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final loading = ref.read(aiLoadingProvider.notifier);
              loading.show("DELETING FILE FROM SERVER...");

              await ref
                  .read(productGalleryProvider(widget.productId).notifier)
                  .deleteImage(fileName);

              loading.hide();
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> goToAiProcessorScreen(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(productGalleryProvider(widget.productId).notifier);
    final result = await context.push<dynamic>('${AppRouter.PAGE_AI_PROCESSOR}/${widget.productId}');
    if (result != null) notifier.fetchRemoteImages();
  }
}
