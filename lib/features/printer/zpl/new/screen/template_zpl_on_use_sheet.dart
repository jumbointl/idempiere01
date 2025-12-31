import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/models/zpl_printing_template.dart';

import '../models/zpl_template.dart';
import '../models/zpl_template_store.dart';
import '../provider/always_use_last_template_provider.dart';
import '../provider/template_zpl_provider.dart';

Future<ZplTemplate?> showUseZplTemplateSheet({
  required BuildContext context,
  required WidgetRef ref,
  required ZplTemplateStore store,
}) {
  return showModalBottomSheet<ZplTemplate>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      final height = MediaQuery.of(context).size.height * 0.9;
      return SizedBox(
        height: height,
        width: double.infinity,
        child: _UseZplTemplateSheet(ref: ref, store: store),
      );
    },
  );
}

class _UseZplTemplateSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final ZplTemplateStore store;

  const _UseZplTemplateSheet({
    required this.ref,
    required this.store,
  });

  @override
  ConsumerState<_UseZplTemplateSheet> createState() =>
      _UseZplTemplateSheetState();
}

class _UseZplTemplateSheetState
    extends ConsumerState<_UseZplTemplateSheet> {
  late List<ZplTemplate> all;
  String? selectedId;

  final Map<String, bool?> _dfExists = {};

  @override
  void initState() {
    super.initState();
    all = widget.store.loadAll();
    widget.store.normalizeDefaults();
    final selectedMode = ref.read(selectedZplTemplateModeProvider);
    final def = widget.store.loadDefaultByMode(selectedMode);
    if (def != null) {
      selectedId = def.id;
    } else {
      final list = _filtered(selectedMode);
      if (list.isNotEmpty) selectedId = list.first.id;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.store.ensureSingleIfOnlyOneDefault(selectedMode);
      await _reload();
    });
  }

  Future<void> _reload() async {
    final selectedMode = ref.read(selectedZplTemplateModeProvider);
    setState(() {
      all = widget.store.loadAll();
    });

    final list = _filtered(selectedMode);
    if (list.isEmpty) {
      setState(() => selectedId = null);
      return;
    }
    final exists = list.any((t) => t.id == selectedId);
    if (!exists) {
      final def = widget.store.loadDefaultByMode(selectedMode);
      setState(() => selectedId = (def ?? list.first).id);
    }
  }

  List<ZplTemplate> _filtered(ZplTemplateMode mode) {
    return all.where((t) => t.mode == mode).toList()
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
  }


  ZplTemplate? get selected {
    final selectedMode = ref.read(selectedZplTemplateModeProvider);
    if (selectedId == null) return null;
    for (final t in _filtered(selectedMode)) {
      if (t.id == selectedId) return t;
    }
    return null;
  }

  String _modeLabel(ZplTemplateMode m) {
    switch (m) {
      case ZplTemplateMode.movement:
        return 'Movement';
      case ZplTemplateMode.shipping:
        return 'Shipping';
    }
  }

  Future<void> _confirmDelete(ZplTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar template'),
        content: Text(
          '¿Deseas eliminar el template:\n\n${t.templateFileName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await widget.store.deleteById(t.id);
    _dfExists.remove(t.id);
    final selectedMode = ref.read(selectedZplTemplateModeProvider);
    await widget.store.ensureSingleIfOnlyOneDefault(selectedMode);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMode = ref.watch(selectedZplTemplateModeProvider);
    final listTotal = _filtered(selectedMode);
    // Keep only fill_data (as before)
    final list = listTotal.where(
          (t) => t.templateFileName.contains(
        ZplPrintingTemplate.filterOfFileToFillData,
      ),
    ).toList();


    final t = selected;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Usar template ZPL (modo: ${_modeLabel(selectedMode)})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, null),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: InkWell(
            onTap: () {
              final newValue = !ref.read(alwaysUseLastTemplateProvider);

              ref.read(alwaysUseLastTemplateProvider.notifier).state = newValue;
              saveAlwaysUseLastTemplate(newValue);
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 24,
                child: Checkbox(
                  value: ref.watch(alwaysUseLastTemplateProvider),
                  onChanged: (value) {
                    final newValue = value ?? false;
                    ref.read(alwaysUseLastTemplateProvider.notifier).state = newValue;
                    saveAlwaysUseLastTemplate(newValue);
                  },
                ),
              ),
              title: const Text(
                'Usar siempre la última template',
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ),
        ),
        const Divider(height: 1),

        /// -------------------- LIST --------------------
        Expanded(
          child: list.isEmpty
              ? const Center(
            child: Text('No hay templates en este modo.'),
          )
              : RadioGroup<String>(
            groupValue: selectedId,
            onChanged: (v) async {
              if (v == null) return;
              _selectTemplate(v);
            },
            child: ListView.separated(
              padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final x = list[i];
                final fileName =
                    x.templateFileName.split(ZplPrintingTemplate.filterOfFileToFillData).first;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: x.isDefault
                          ? Colors.green
                          : Colors.black.withOpacity(0.08),
                      width: x.isDefault ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final selectedMode =
                      ref.read(selectedZplTemplateModeProvider);

                      // English comment: "Set tapped template as default"
                      await widget.store.setDefaultForMode(
                        templateId: x.id,
                        mode: selectedMode,
                      );

                      await widget.store.normalizeDefaults();

                      if (!context.mounted) return;

                      // English comment: "Return selected template"
                      Navigator.of(context).pop(x);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (x.isDefault)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20)
                          else
                            const Icon(Icons.description_outlined,
                                size: 20),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'rows: ${x.rowPerpage} • ${_modeLabel(x.mode)} • ${x.createdAt}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _confirmDelete(x),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },

            ),
          ),
        ),

        const Divider(height: 1),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: TextButton(
            onPressed: () =>
                Navigator.pop(context, null),
            child: const Text('Cerrar'),
          ),
        ),
      ],
    );
  }
  Future<void> _selectTemplate(String id) async {
    // English comment: "Avoid double selection"
    if (selectedId == id) {
      final sel = selected;
      if (sel != null) {
        if(!sel.isDefault){
          final selectedMode = ref.read(selectedZplTemplateModeProvider);
          await widget.store.setDefaultForMode(
            templateId: id,
            mode: selectedMode,
          );
        }

        if(context.mounted){
          Navigator.of(context).pop(sel);
        }

      }
      return;
    }

    setState(() => selectedId = id);

    final selectedMode = ref.read(selectedZplTemplateModeProvider);
    await widget.store.setDefaultForMode(
      templateId: id,
      mode: selectedMode,
    );

    await _reload();

    // English comment: "Let UI update before closing"
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    final sel = selected;
    if (sel != null) {
      Navigator.of(context).pop(sel);
    }
  }

}
