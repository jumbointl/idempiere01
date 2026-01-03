import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/features/printer/web_template/screen/show_ftp_configuration.dart';
import 'package:monalisa_app_001/features/products/common/widget/app_initializer_overlay.dart';
import '../../../products/domain/models/zpl_printing_template.dart';
import '../../../products/presentation/providers/common_provider.dart';
import '../../../shared/data/messages.dart';
import '../../zpl/new/models/zpl_template.dart';
import '../../zpl/new/models/zpl_template_store.dart';
import '../provider/refresh_all_zpl_templates_from_ftp_provider.dart';

Future<List<ZplTemplate>?> showSearchZplTemplateSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ZplTemplateMode mode,
}) async {
  bool didTrigger = false;
  late List<ZplTemplate> allFiles ;
  loadFtpAccountConfig() ;
  return showModalBottomSheet<List<ZplTemplate>?>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {


      return StatefulBuilder(
        builder: (ctx, setState) {
          return Consumer(
            builder: (_, consumerRef, __) {
              // English comment: "Trigger refresh only once"
              if (!didTrigger) {
                didTrigger = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  consumerRef.read(refreshAllZplTemplatesFromFtpProvider.notifier).state++;
                });
              }

              final asyncAll = consumerRef.watch(findAllZplTemplatesFromFtpProvider);

              return SafeArea(
                child: AppInitializerOverlay(
                  child: SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.85,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Templates FTP (modo: ${mode.name})',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(ctx).pop(null),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: asyncAll.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) => Center(child: Text('Error: $e')),
                            data: (all) {
                              // Filter by mode
                              final list = all.where((t) => t.mode == mode).toList();
                              allFiles = all;



                              if (list.isEmpty) {
                                return const Center(child: Text('No hay templates disponibles'));
                              }

                              return ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final t = list[i];
                                  late String name ;
                                  if(t.templateFileName.contains(ZplPrintingTemplate.filterOfFileToPrinter)){
                                    name = '${t.templateFileName.split(ZplPrintingTemplate.filterOfFileToPrinter).first} ZPL';

                                  } else {
                                    name = t.templateFileName
                                        .split(ZplPrintingTemplate.filterOfFileToFillData)
                                        .first;

                                  }

                                  return ListTile(
                                    title: Text(name),
                                    subtitle: Text(t.mode.name),
                                    onTap: () => Navigator.of(ctx).pop(t),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(ctx).pop(null),
                                  child: Text(Messages.CANCEL),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final all = allFiles ?? [];

                                    if (all.isEmpty) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text('No hay templates para guardar')),
                                      );
                                      return;
                                    }

                                    ref.read(initializingProvider.notifier).state = true;
                                    await Future.delayed(const Duration(milliseconds: 100));
                                    final box = GetStorage();
                                    final store = ZplTemplateStore(box);

                                    // English comment: "Wipe old templates first"
                                    await store.clearAll();
                                    for (int i = 0; i < all.length; i++) {
                                      final t = all[i];
                                      String baseId = 'ZPL_$i';
                                      final normalized = t.copyWith(id: baseId);
                                      await store.upsert(normalized);
                                    }
                                    await store.normalizeDefaults();
                                    ref.read(initializingProvider.notifier).state = false;
                                    await Future.delayed(const Duration(milliseconds: 100));

                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop(all);
                                    }
                                  },

                                  child: const Text('SAVE'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
