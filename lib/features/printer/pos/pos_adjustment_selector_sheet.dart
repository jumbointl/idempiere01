import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/printer/pos/pos_adjustment_values.dart';
import 'package:monalisa_app_001/features/printer/pos/pos_paper_size_pick_sheet.dart';
import 'package:monalisa_app_001/features/printer/pos/pos_test_pick_sheets.dart';
import 'package:monalisa_app_001/features/products/common/input_dialog.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../../shared/data/messages.dart';
import 'pos_adjustment_helpers.dart';
import 'pos_adjustment_profile_editor_sheet.dart';
import 'pos_adjustment_providers.dart';
import 'pos_adjustment_storage.dart';
import 'pos_test_print.dart';

Future<PosAdjustmentValues?> showPosAdjustmentSelectorSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String ip,
  required int port,
  required bool alwaysOpen,
}) async {
  final alwaysDefault = ref.read(useAlwaysDefaultPosProvider);
  final list = ref.read(posAdjustmentsProvider);

  if (!alwaysOpen && alwaysDefault) {
    final def = list.where((e) => e.isDefault).toList();
    if (def.length == 1) return def.first;
  }

  return showModalBottomSheet<PosAdjustmentValues>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return Consumer(builder: (context, ref, _) {
        final isScanning = ref.watch(isScanningProvider);

        final profiles = ref.watch(posAdjustmentsProvider);
        int? selectedId = profiles.firstWhere(
              (e) => e.isDefault,
          orElse: () => profiles.first,
        ).id;

        PosAdjustmentValues getSelected() {
          if (selectedId != null) {
            final hit = profiles.where((e) => e.id == selectedId).toList();
            if (hit.isNotEmpty) return hit.first;
          }
          final defaults = profiles.where((e) => e.isDefault).toList();
          return defaults.isNotEmpty ? defaults.first : profiles.first;
        }

        void saveAndSelect(PosAdjustmentValues updated) {
          var newList =
          profiles.map((e) => e.id == updated.id ? updated : e).toList();

          // garantizar un solo default
          if (updated.isDefault) {
            newList = ensureSingleDefault(newList, updated.id);
          }

          savePosAdjustments(ref, newList);
          selectedId = updated.id;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---------- HEADER ----------
                    ListTile(
                      title: const Text('Perfiles POS'),
                      subtitle: const Text('Selecciona perfil · Test y aplicar ajustes'),
                    ),
                    isScanning ? const LinearProgressIndicator() : const SizedBox.shrink(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          // ---------- ROW 1: PAPEL ----------
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                tooltip: 'Test papel (32/42/48)',
                                icon: const Icon(Icons.receipt_long),
                                onPressed: () async {
                                  ref.read(isScanningProvider.notifier).state = true;
                                  await Future.delayed(const Duration(milliseconds: 100));

                                  final target = getSelected();

                                  final res = await printPaperSizeColsTestTicket(
                                    ip: ip,
                                    port: port,
                                    printerName: target.machineModel,
                                  );
                                  if (res != PosPrintResult.success) return;
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  ref.read(isScanningProvider.notifier).state = false;
                                  final pickedPaper =
                                  await showPaperSizePickFromColsSheet(context);
                                  if (pickedPaper == null) return;

                                  final updated =
                                  target.copyWith(paperSize: pickedPaper);

                                  setState(() => saveAndSelect(updated));
                                },
                              ),

                              IconButton(
                                tooltip: 'Agregar perfil',
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  final created = await showPosProfileEditorSheet(
                                    context: context,
                                    ref: ref,
                                    suggestedNextId: nextPosProfileId(profiles),
                                  );
                                  if (created == null) return;

                                  var newList = [...profiles, created];
                                  if (created.isDefault) {
                                    newList =
                                        ensureSingleDefault(newList, created.id);
                                  }
                                  savePosAdjustments(ref, newList);
                                  setState(() => selectedId = created.id);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // ---------- ROW 2: AJUSTES FINOS ----------
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // TEXT WIDTH
                              IconButton(
                                tooltip: 'Test texto (cols)',
                                icon: const Icon(Icons.straighten),
                                onPressed: () async {
                                  ref.read(isScanningProvider.notifier).state = true;
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  final target = getSelected();

                                  final res = await printWidthTestTicket(
                                    ip: ip,
                                    port: port,
                                    printerName: target.machineModel,
                                    paperSize: target.paperSize,
                                  );
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  ref.read(isScanningProvider.notifier).state = false;



                                  if (res != PosPrintResult.success) return;

                                  final picked = await showWidthPickSheet(context);
                                  if (picked == null) return;

                                  final updated = target.copyWith(
                                    charactersPerLineAdjustment:
                                    picked.colsBaseDelta,
                                  );

                                  setState(() => saveAndSelect(updated));
                                },
                              ),

                              // IMAGE WIDTH
                              IconButton(
                                tooltip: 'Test imagen',
                                icon: const Icon(Icons.photo),
                                onPressed: () async {
                                  final target = getSelected();
                                  ref.read(isScanningProvider.notifier).state = true;
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  final res =
                                  await printWidthAdjustmentHeaderTestTicket(
                                    context: context,
                                    ip: ip,
                                    port: port,
                                    printerName: target.machineModel,
                                    baseAdj: target,
                                    logoAssetPath:
                                    'assets/images/monalisa_logo_movement.jpg',
                                    qrData: '5678999-123-456-0007890',
                                    paperSize: target.paperSize,
                                  );
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  ref.read(isScanningProvider.notifier).state = false;

                                  if (res != PosPrintResult.success) return;

                                  final picked =
                                  await showImageWidthPickSheet(context);
                                  if (picked == null) return;

                                  final updated = target.copyWith(
                                    printWidthAdjustment:
                                    picked.printWidthAdjustment,
                                  );

                                  setState(() => saveAndSelect(updated));
                                },
                              ),

                              // CHARSET
                              IconButton(
                                tooltip: 'Test charset',
                                icon: const Icon(Icons.translate),
                                onPressed: () async {
                                  final target = getSelected();
                                  ref.read(isScanningProvider.notifier).state = true;
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  final res = await printDiagCodepageTicket(
                                    ip: ip,
                                    port: port,
                                    printerName: target.machineModel,
                                    paperSize: target.paperSize,
                                    adj: target,
                                  );
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  ref.read(isScanningProvider.notifier).state = false;

                                  if (res != PosPrintResult.success) return;

                                  final picked =
                                  await showCharsetPickSheet(context);
                                  if (picked == null) return;

                                  final updated = target.copyWith(
                                    charSet: picked.charSet,
                                    escTCodeTable: picked.escTCodeTable,
                                    textMode: picked.textMode,
                                  );

                                  setState(() => saveAndSelect(updated));
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),


                    // ---------- ALWAYS DEFAULT ----------
                    SwitchListTile(
                      title: const Text('Usar siempre default'),
                      value: ref.watch(useAlwaysDefaultPosProvider),
                      onChanged: (v) {
                        PosAdjustmentStorage.writeAlwaysDefault(v);
                        ref
                            .read(useAlwaysDefaultPosProvider.notifier)
                            .state = v;
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.red),
                      title: const Text(
                        'Resetear a valores por defecto',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        final ok = await openBottomSheetConfirmationDialog(
                            ref: ref,
                            title: Messages.RESET_TO_DEFAULT,
                            message:  Messages.CONFIRM_TO_RESET_TO_DEFAULT,
                        );

                        if (ok!=true) return;

                        // 🔥 reset storage
                        PosAdjustmentStorage.resetToDefaults();
                        ref.invalidate(posAdjustmentsProvider);
                        ref.invalidate(useAlwaysDefaultPosProvider);

                        await showSuccessMessage(context, ref, Messages.RESET_TO_DEFAULT);

                        // ♻️ refrescar providers

                        final profiles = ref.read(posAdjustmentsProvider);

                        // ✅ seleccionar default
                        final def = profiles.firstWhere(
                              (e) => e.isDefault,
                          orElse: () => profiles.first,
                        );

                        setState(() {
                          selectedId = def.id;
                        });
                      },
                    ),


                    const Divider(height: 1),

                    // ---------- LIST ----------
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = profiles[i];
                          final isSelected = p.id == selectedId;

                          return ListTile(
                            leading: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : p.isDefault
                                  ? Icons.star
                                  : Icons.print,
                            ),
                            title: Text(p.machineModel),
                            subtitle: Text(
                                'WidthAdj ${p.printWidthAdjustment} | '
                                    'CharsAdj ${p.charactersPerLineAdjustment} | '
                                    '${p.charSet.name} · ${p.textMode.name} | '
                                    'ESC t ${p.escTCodeTable ?? '-'}'

                            ),
                            onTap: () {
                              setState(() => selectedId = p.id);
                              if (!alwaysOpen) {
                                Navigator.pop(context, p);
                              }
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // SET DEFAULT
                                IconButton(
                                  icon: const Icon(Icons.star_outline),
                                  onPressed: () {
                                    final updated =
                                    p.copyWith(isDefault: true);
                                    setState(() => saveAndSelect(updated));
                                  },
                                ),
                                // EDIT
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final edited =
                                    await showPosProfileEditorSheet(
                                      context: context,
                                      ref: ref,
                                      initial: p,
                                      suggestedNextId:
                                      nextPosProfileId(profiles),
                                    );
                                    if (edited == null) return;
                                    setState(() => saveAndSelect(edited));
                                  },
                                ),
                                // DELETE
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    if(profiles.length==1){
                                      showWarningMessage(context, ref, Messages.CANNOT_DELETE_LAST_PROFILE);
                                      return ;
                                    }
                                    final newList = profiles
                                        .where((x) => x.id != p.id)
                                        .toList();
                                    savePosAdjustments(ref, newList);
                                    setState(() {
                                      if (newList.isEmpty) {
                                        selectedId = null;
                                      } else {
                                        selectedId = newList.firstWhere(
                                              (e) => e.isDefault,
                                          orElse: () => newList.first,
                                        ).id;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    },
  );
}
