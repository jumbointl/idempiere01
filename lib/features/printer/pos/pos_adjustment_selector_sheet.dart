import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/printer/pos/pos_adjustment_values.dart';
import 'package:monalisa_app_001/features/printer/pos/pos_test_pick_sheets.dart';

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
        final profiles = ref.watch(posAdjustmentsProvider);
        int? selectedId;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------- HEADER ----------
                  ListTile(
                    title: const Text('Perfiles POS'),
                    subtitle: const Text(
                      'Selecciona perfil · Test y aplicar ajustes',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TEST ANCHO
                        IconButton(
                          tooltip: 'Test ancho',
                          icon: const Icon(Icons.straighten),
                          onPressed: () async {
                            final target = getSelected();
                            final res = await printWidthTestTicket(
                              ip: ip,
                              port: port,
                              printerName: target.machineModel,
                            );


                            if (res != PosPrintResult.success) return;

                            final picked =
                            await showWidthPickSheet(context);
                            if (picked == null) return;

                            final updated = target.copyWith(

                              charactersPerLineAdjustment:
                              picked.suggestedCharsAdj,
                            );

                            setState(() => saveAndSelect(updated));
                          },
                        ),
                        IconButton(
                          tooltip: 'Test imagen',
                          icon: const Icon(Icons.photo),
                          onPressed: () async {
                            final target = getSelected();
                            final res = await printWidthAdjustmentHeaderTestTicket(
                              baseAdj: target,
                              logoAssetPath: 'assets/images/monalisa_logo_movement.jpg',
                              qrData: '5678999-123-456-0007890',
                              ip: ip,
                              port: port,
                              printerName: target.machineModel,
                            );

                            if (res != PosPrintResult.success) return;
                            if(context.mounted){
                              final picked = await showImageWidthPickSheet(context);
                              if (picked == null) return;

                              final updated = target.copyWith(
                                printWidthAdjustment: picked.printWidthAdjustment,
                              );

                              setState(() => saveAndSelect(updated));
                            }

                          },
                        ),
                        // TEST CHARSET
                        IconButton(
                          tooltip: 'Test charset',
                          icon: const Icon(Icons.translate),
                          onPressed: () async {
                            final target = getSelected();
                            final res = await printCharsetTestTicket(
                              ip: ip,
                              port: port,
                            );
                            if (res != PosPrintResult.success) return;

                            final picked =
                            await showCharsetPickSheet(context);
                            if (picked == null) return;

                            final escT =
                            picked == PosCharSet.cp850 ? 2 : 16;

                            final updated = target.copyWith(
                              charSet: picked,
                              escTCodeTable: escT,
                            );

                            setState(() => saveAndSelect(updated));
                          },
                        ),

                        // ADD
                        IconButton(
                          tooltip: 'Agregar perfil',
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final created =
                            await showPosProfileEditorSheet(
                              context: context,
                              ref: ref,
                              suggestedNextId:
                              nextPosProfileId(profiles),
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
                                'ESC t ${p.escTCodeTable ?? '-'}',
                          ),
                          onTap: () {
                            setState(() => selectedId = p.id);
                            Navigator.pop(context, p);
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
                                  final newList = profiles
                                      .where((x) => x.id != p.id)
                                      .toList();
                                  savePosAdjustments(ref, newList);
                                  setState(() => selectedId = null);
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
            );
          },
        );
      });
    },
  );
}
