import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../../../../common/messages_dialog.dart';
import '../../printer_scan_notifier.dart';
import 'template_zpl_models.dart';
import 'template_zpl_store.dart';

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
  ConsumerState<_UseZplTemplateSheet> createState() => _UseZplTemplateSheetState();
}

class _UseZplTemplateSheetState extends ConsumerState<_UseZplTemplateSheet> {
  late List<ZplTemplate> all;
  ZplTemplateMode selectedMode = ZplTemplateMode.movement;
  String? selectedId;

  @override
  void initState() {
    super.initState();
    all = widget.store.loadAll();
    widget.store.normalizeDefaults();

    final def = widget.store.loadDefaultByMode(selectedMode);
    if (def != null) {
      selectedId = def.id;
    } else {
      final list = _filtered();
      if (list.isNotEmpty) selectedId = list.first.id;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.store.ensureSingleIfOnlyOneDefault(selectedMode);
      await _reload();

      final def = widget.store.loadDefaultByMode(selectedMode);
      if (def != null && !_dfExists.containsKey(def.id)) {
        await _checkTemplateExists(def);
      }
    });
  }

  Future<void> _reload() async {
    setState(() {
      all = widget.store.loadAll();
    });

    final list = _filtered();
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

  List<ZplTemplate> _filtered() {
    return all.where((t) => t.mode == selectedMode).toList()
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  ZplTemplate? get selected {
    final list = _filtered();
    if (selectedId == null) return null;
    for (final t in list) {
      if (t.id == selectedId) return t;
    }
    return null;
  }
  final Map<String, bool?> _dfExists = {};
// id -> true / false / null (no verificado)
  Future<void> _checkTemplateExists(ZplTemplate t) async {
    final printerState = ref.read(printerScanProvider);
    final ip = printerState.ipController.text.trim();
    final port = int.tryParse(printerState.portController.text.trim()) ?? 0;
    final type = printerState.typeController.text.trim();

    if (type != 'ZPL') {
      showErrorMessage(context, ref, 'La impresora no es ZPL');
      return;
    }

    if (ip.isEmpty || port == 0) {
      showErrorMessage(context, ref, 'IP/PORT inválido');
      return;
    }

    try {
      final exists = await zebraFileExists(
        ip: ip,
        port: port,
        drive: 'E:',
        fileName: t.templateFileName,
      );

      setState(() {
        _dfExists[t.id] = exists;
      });

      if (exists) {
        showSuccessMessage(
          context,
          ref,
          'Template encontrado en impresora (${t.templateFileName})',
        );
      } else {
        showErrorMessage(
          context,
          ref,
          'Template NO existe en la impresora',
        );
      }
    } catch (e) {
      showErrorMessage(
        context,
        ref,
        'Error al verificar template: $e',
      );
    }
  }

  Future<bool> zebraFileExists({
    required String ip,
    required int port,
    required String drive,     // "E:" o "R:" etc
    required String fileName,  // "MOVEMENT_BY_CATEGORY_TEMPLATE.ZPL"
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));

    // SGD: devuelve el listado en el mismo socket/puerto
    final cmd = '! U1 do "file.dir" "$drive"\r\n';

    final completer = Completer<String>();
    final buffer = StringBuffer();

    late StreamSubscription sub;
    Timer? timer;

    void finish() {
      if (!completer.isCompleted) completer.complete(buffer.toString());
      timer?.cancel();
    }

    // Lee respuesta hasta que se quede “quieto” o timeout
    timer = Timer(timeout, finish);

    sub = socket.listen(
          (data) {
        buffer.write(utf8.decode(data, allowMalformed: true));
        // Reinicia timeout mientras sigan llegando datos
        timer?.cancel();
        timer = Timer(timeout, finish);
      },
      onError: (_) => finish(),
      onDone: () => finish(),
      cancelOnError: true,
    );

    socket.add(utf8.encode(cmd));
    await socket.flush();

    final resp = await completer.future;

    await sub.cancel();
    await socket.close();

    final target = '${drive.toUpperCase()}${fileName.toUpperCase()}';
    return resp.toUpperCase().contains(target);
  }


  String _modeLabel(ZplTemplateMode m) {
    switch (m) {
      case ZplTemplateMode.movement:
        return 'Movement';
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await widget.store.deleteById(t.id);
    _dfExists.remove(t.id);
    await widget.store.ensureSingleIfOnlyOneDefault(selectedMode);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    final t = selected;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Usar template ZPL',
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: DropdownButtonFormField<ZplTemplateMode>(
            initialValue: selectedMode,
            decoration: const InputDecoration(
              labelText: 'Filtrar por modo',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: ZplTemplateMode.values
                .map(
                  (m) => DropdownMenuItem(
                value: m,
                child: Text(
                  _modeLabel(m),
                  style: const TextStyle(fontSize: themeFontSizeNormal),
                ),
              ),
            )
                .toList(),
            onChanged: (m) async {
              if (m == null) return;
              setState(() => selectedMode = m);
              await widget.store.ensureSingleIfOnlyOneDefault(selectedMode);
              await _reload();
            },
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No hay templates en este modo.'))
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final x = list[i];
              final exists = _dfExists[x.id];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.black.withOpacity(0.08)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    setState(() => selectedId = x.id);
                    await widget.store.setDefaultForMode(
                      templateId: x.id,
                      mode: selectedMode,
                    );
                    await _reload();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: x.id,
                          groupValue: selectedId,
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => selectedId = v);
                            await widget.store.setDefaultForMode(
                              templateId: v,
                              mode: selectedMode,
                            );
                            await _reload();
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      x.templateFileName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (x.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.4),
                                        ),
                                      ),
                                      child: const Text(
                                        'DEFAULT',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
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
                        Row(
                          children: [
                            // ICONO ESTADO
                            if (exists != null)
                              Icon(
                                exists ? Icons.check_circle : Icons.cancel,
                                color: exists ? Colors.green : Colors.red,
                                size: 22,
                              )
                            else
                              const Icon(
                                Icons.help_outline,
                                color: Colors.grey,
                                size: 22,
                              ),

                            const SizedBox(width: 8),

                            // BOTÓN VERIFICAR
                            IconButton(
                              tooltip: 'Verificar template en impresora',
                              icon: const Icon(Icons.cloud_sync),
                              onPressed: () => _checkTemplateExists(x),
                            ),

                            // ELIMINAR
                            IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(x),
                            ),
                          ],
                        ),
                        /*IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(x),
                        ),*/
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cerrar'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (t == null) ? null : () => Navigator.pop(context, t),
                child: const Text('Usar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}






/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import 'template_zpl_models.dart';
import 'template_zpl_store.dart';

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
  ConsumerState<_UseZplTemplateSheet> createState() => _UseZplTemplateSheetState();
}

class _UseZplTemplateSheetState extends ConsumerState<_UseZplTemplateSheet> {
  late List<ZplTemplate> all;
  ZplTemplateMode selectedMode = ZplTemplateMode.movement;

  String? selectedId;

  @override
  void initState() {
    super.initState();
    all = widget.store.loadAll();

    // normaliza defaults por seguridad
    widget.store.normalizeDefaults();

    // elegir modo inicial: si hay default en movement, usarlo
    final def = widget.store.loadDefaultByMode(selectedMode);
    if (def != null) {
      selectedId = def.id;
    } else {
      // si hay algún template en ese modo, elegir primero
      final list = _filtered();
      if (list.isNotEmpty) selectedId = list.first.id;
    }

    // si hay 1 solo en el modo, forzar default
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.store.ensureSingleIfOnlyOneDefault(selectedMode);
      await _reload();
    });
  }

  Future<void> _reload() async {
    setState(() {
      all = widget.store.loadAll();
    });

    // Ajusta selectedId si quedó apuntando a algo que ya no está en el modo
    final list = _filtered();
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

  List<ZplTemplate> _filtered() {
    return all.where((t) => t.mode == selectedMode).toList()
      ..sort((a, b) {
        // default primero, luego por fecha desc
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  ZplTemplate? get selected {
    final list = _filtered();
    if (selectedId == null) return null;
    for (final t in list) {
      if (t.id == selectedId) return t;
    }
    return null;
  }

  String _modeLabel(ZplTemplateMode m) {
    switch (m) {
      case ZplTemplateMode.movement:
        return 'Movement';
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    final t = selected;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Usar template ZPL',
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ZplTemplateMode>(
                  initialValue: selectedMode,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por modo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ZplTemplateMode.values
                      .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(_modeLabel(m),style: const TextStyle(fontSize: themeFontSizeNormal)),
                  ))
                      .toList(),
                  onChanged: (m) async {
                    if (m == null) return;
                    setState(() => selectedMode = m);

                    await widget.store.ensureSingleIfOnlyOneDefault(selectedMode);
                    await _reload();

                    final def = widget.store.loadDefaultByMode(selectedMode);
                    if (def != null) {
                      setState(() => selectedId = def.id);
                    } else if (_filtered().isNotEmpty) {
                      setState(() => selectedId = _filtered().first.id);
                    } else {
                      setState(() => selectedId = null);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No hay templates en este modo.'))
              : RadioGroup<String>(
            groupValue: selectedId,
            onChanged: (value) async {
              if (value == null) return;
              setState(() => selectedId = value);

              // ✅ Al seleccionar => marcar default del modo
              await widget.store.setDefaultForMode(
                templateId: value,
                mode: selectedMode,
              );
              await _reload();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final x = list[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      setState(() => selectedId = x.id);
                      await widget.store.setDefaultForMode(
                        templateId: x.id,
                        mode: selectedMode,
                      );
                      await _reload();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Radio<String>(value: x.id),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        x.templateFileName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    if (x.isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: Colors.green.withOpacity(0.4)),
                                        ),
                                        child: const Text(
                                          'DEFAULT',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'rows: ${x.rowPerpage}  •  ${_modeLabel(x.mode)}  •  ${x.createdAt}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ),

        const Divider(height: 1),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cerrar'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (t == null) ? null : () => Navigator.pop(context, t),
                child: const Text('Usar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
*/
