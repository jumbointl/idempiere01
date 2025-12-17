import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../common/widget_utils.dart';
import 'zpl_print_profile_providers.dart';

/// ===============================
/// PREVIEW VISUAL
/// ===============================
class ZplLabelPreview extends StatelessWidget {
  final int rowsPerLabel;
  final int rowPerProductName;
  final int marginX;
  final int marginY;

  const ZplLabelPreview({
    super.key,
    required this.rowsPerLabel,
    required this.rowPerProductName,
    required this.marginX,
    required this.marginY,
  });

  @override
  Widget build(BuildContext context) {
    const double labelW = 300;
    const double labelH = 450;

    final headerH = labelH * (40 / 150);
    final tableH = labelH * (10 / 150);
    final footerH = labelH * (10 / 150);
    final bodyH = labelH - headerH - tableH - footerH;

    final int items = rowsPerLabel <= 0 ? 1 : rowsPerLabel;
    final itemH = bodyH / items;

    return Container(
      width: labelW,
      height: labelH,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _sec(
            height: headerH,
            title: 'HEADER 40mm (incl QR)',
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('mX=$marginX  mY=$marginY',
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
          _sec(
            height: tableH,
            title: 'TABLE HEADER 10mm',
            child: const Center(
              child: Text(
                'UPC/SKU | HASTA/DESDE\nATRIBUTO | CANTIDAD',
                style: TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          _sec(
            height: bodyH,
            title: 'BODY ($items items)',
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items,
              itemBuilder: (_, i) => Container(
                height: itemH,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('UPC/TO | SKU/FROM | ATR',
                        style: TextStyle(fontSize: 10)),
                    const SizedBox(height: 4),
                    ...List.generate(
                      rowPerProductName.clamp(1, 2),
                          (k) => Text(
                        'productName line ${k + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Text('QTY',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          ),
          _sec(
            height: footerH,
            title: 'FOOTER 10mm',
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ITEMS | TOTAL | 1/3',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sec({
    required double height,
    required String title,
    required Widget child,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.25)),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 6,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white,
              child: Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// BOTTOM SHEET PRINCIPAL
/// Devuelve el perfil seleccionado (o null)
/// ===============================
Future<ZplPrintProfile?> showZplPrintProfilesSheet(
    BuildContext context,
    WidgetRef ref,
    ) {
  return showModalBottomSheet<ZplPrintProfile>(
    isDismissible: false,
    enableDrag: false,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _ZplProfilesPanel(),
  );
}

class _ZplProfilesPanel extends ConsumerWidget {
  const _ZplProfilesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(zplProfilesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Configuración impresión ZPL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: profiles.length,
                itemBuilder: (_, i) {
                  final p = profiles[i];
                  final maxAllowed = maxRowsAllowed(
                    marginY: p.marginY,
                    rowPerProductName: p.rowPerProductName,
                  );

                  return Card(
                    child: ListTile(
                      title: Text(p.name),
                      subtitle: Text(
                        'rows=${p.rowsPerLabel} (max $maxAllowed) | nameLines=${p.rowPerProductName} | mX=${p.marginX} mY=${p.marginY}',
                      ),
                      onTap: () async {
                        final edited = await showZplProfileEditor(
                          context,
                          ref,
                          initial: p,
                        );
                        if (edited != null) {
                          ref.read(zplProfilesProvider.notifier).update(edited);
                        }
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => ref
                                .read(zplProfilesProvider.notifier)
                                .remove(p.id),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, p),
                            child: const Text('Usar'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final created = await showZplProfileEditor(context, ref);
                if (created != null) {
                  ref.read(zplProfilesProvider.notifier).add(created);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// EDITOR (crear/editar) + preview + clamp
/// ===============================
Future<ZplPrintProfile?> showZplProfileEditor(
    BuildContext context,
    WidgetRef ref, {
      ZplPrintProfile? initial,
    }) async {
  final nameCtrl = TextEditingController(text: initial?.name ?? '');
  final rowsCtrl =
  TextEditingController(text: (initial?.rowsPerLabel ?? 4).toString());
  final mxCtrl =
  TextEditingController(text: (initial?.marginX ?? 20).toString());
  final myCtrl =
  TextEditingController(text: (initial?.marginY ?? 20).toString());

  int rppn = initial?.rowPerProductName ?? 2;

  int computeMax() {
    final my = int.tryParse(myCtrl.text) ?? 20;
    return maxRowsAllowed(marginY: my, rowPerProductName: rppn);
  }

  void clampRows(StateSetter setState) {
    final maxAllowed = computeMax();
    final current = int.tryParse(rowsCtrl.text) ?? 1;
    final clamped = current.clamp(1, maxAllowed);

    if (clamped != current) {
      rowsCtrl.text = clamped.toString();
      rowsCtrl.selection =
          TextSelection.fromPosition(TextPosition(offset: rowsCtrl.text.length));
    }
    setState(() {});
  }

  return showDialog<ZplPrintProfile>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) {
        final maxAllowed = computeMax();

        final mx = int.tryParse(mxCtrl.text) ?? 20;
        final my = int.tryParse(myCtrl.text) ?? 20;
        final rows = (int.tryParse(rowsCtrl.text) ?? 1).clamp(1, maxAllowed);

        return AlertDialog(
          title: Text(initial == null ? 'Nuevo perfil ZPL' : 'Editar perfil ZPL'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Nombre
                  CompactEditableFieldScreenInput(
                    label: 'Nombre',
                    controller: nameCtrl,
                    keyboardType: TextInputType.text,
                    history: false,
                    title: 'Nombre',
                    numberOnly: false,
                    onChangedAfterDialog: null,
                  ),
                  const SizedBox(height: 8),

                  // Dropdown sigue igual
                  DropdownButtonFormField<int>(
                    initialValue: rppn,
                    decoration: const InputDecoration(
                      labelText: 'Líneas para productName',
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 línea')),
                      DropdownMenuItem(value: 2, child: Text('2 líneas')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      rppn = v;
                      clampRows(setState);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Productos por etiqueta
                  Column(
                    children: [
                      CompactEditableFieldScreenInput(
                        label: 'Productos por etiqueta',
                        controller: rowsCtrl,
                        keyboardType: TextInputType.number,
                        history: false,
                        title: 'Productos por etiqueta',
                        numberOnly: true,
                        onChangedAfterDialog: (ref, newValue) {
                          // por ahora no hace nada extra, solo ajusta y refresca
                          //clampRows(setState);
                        },
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Máximo permitido: $maxAllowed',
                          style: Theme.of(ctx)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: CompactEditableFieldScreenInput(
                          label: 'Margen X',
                          controller: mxCtrl,
                          keyboardType: TextInputType.number,
                          history: false,
                          title: 'Margen X',
                          numberOnly: true,
                          onChangedAfterDialog: (ref, newValue) {
                            setState(() {}); // refresca preview
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CompactEditableFieldScreenInput(
                          label: 'Margen Y',
                          controller: myCtrl,
                          keyboardType: TextInputType.number,
                          history: false,
                          title: 'Margen Y',
                          numberOnly: true,
                          onChangedAfterDialog: (ref, newValue) {
                            clampRows(setState); // cambia max permitido + preview
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // PREVIEW
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Preview layout',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ZplLabelPreview(
                      rowsPerLabel: rows,
                      rowPerProductName: rppn,
                      marginX: mx,
                      marginY: my,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty
                    ? (initial == null ? 'Perfil ZPL' : initial.name)
                    : nameCtrl.text.trim();

                final mx = int.tryParse(mxCtrl.text) ?? 20;
                final my = int.tryParse(myCtrl.text) ?? 20;

                final maxAllowed = maxRowsAllowed(
                  marginY: my,
                  rowPerProductName: rppn,
                );
                final rows =
                (int.tryParse(rowsCtrl.text) ?? 1).clamp(1, maxAllowed);

                final p = ZplPrintProfile(
                  id: initial?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  rowsPerLabel: rows,
                  rowPerProductName: rppn,
                  marginX: mx,
                  marginY: my,
                );

                Navigator.pop(ctx, p);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );
}

/*Future<ZplPrintProfile?> showZplProfileEditor(
    BuildContext context,
    WidgetRef ref, {
      ZplPrintProfile? initial,
    }) async {
  final nameCtrl = TextEditingController(text: initial?.name ?? '');
  final rowsCtrl =
  TextEditingController(text: (initial?.rowsPerLabel ?? 4).toString());
  final mxCtrl =
  TextEditingController(text: (initial?.marginX ?? 20).toString());
  final myCtrl =
  TextEditingController(text: (initial?.marginY ?? 20).toString());

  int rppn = initial?.rowPerProductName ?? 2;

  int computeMax() {
    final my = int.tryParse(myCtrl.text) ?? 20;
    return maxRowsAllowed(marginY: my, rowPerProductName: rppn);
  }

  void clampRows(StateSetter setState) {
    final maxAllowed = computeMax();
    final current = int.tryParse(rowsCtrl.text) ?? 1;
    final clamped = current.clamp(1, maxAllowed);
    if (clamped != current) {
      rowsCtrl.text = clamped.toString();
      rowsCtrl.selection =
          TextSelection.fromPosition(TextPosition(offset: rowsCtrl.text.length));
    }
    setState(() {});
  }

  return showDialog<ZplPrintProfile>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) {
        final maxAllowed = computeMax();

        final mx = int.tryParse(mxCtrl.text) ?? 20;
        final my = int.tryParse(myCtrl.text) ?? 20;
        final rows = (int.tryParse(rowsCtrl.text) ?? 1).clamp(1, maxAllowed);

        return AlertDialog(
          title: Text(initial == null ? 'Nuevo perfil ZPL' : 'Editar perfil ZPL'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                children: [

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<int>(
                    initialValue: rppn,
                    decoration: const InputDecoration(
                      labelText: 'Líneas para productName',
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 línea')),
                      DropdownMenuItem(value: 2, child: Text('2 líneas')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      rppn = v;
                      clampRows(setState);
                    },
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: rowsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Productos por etiqueta',
                      helperText: 'Máximo permitido: $maxAllowed',
                    ),
                    onChanged: (_) => clampRows(setState),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: mxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Margen X'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: myCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Margen Y'),
                          onChanged: (_) => clampRows(setState),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // PREVIEW
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Preview layout',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ZplLabelPreview(
                      rowsPerLabel: rows,
                      rowPerProductName: rppn,
                      marginX: mx,
                      marginY: my,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim().isEmpty
                    ? (initial == null ? 'Perfil ZPL' : initial.name)
                    : nameCtrl.text.trim();

                final mx = int.tryParse(mxCtrl.text) ?? 20;
                final my = int.tryParse(myCtrl.text) ?? 20;

                final maxAllowed = maxRowsAllowed(
                  marginY: my,
                  rowPerProductName: rppn,
                );
                final rows = (int.tryParse(rowsCtrl.text) ?? 1).clamp(1, maxAllowed);

                final p = ZplPrintProfile(
                  id: initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  rowsPerLabel: rows,
                  rowPerProductName: rppn,
                  marginX: mx,
                  marginY: my,
                );

                Navigator.pop(ctx, p);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );
}*/
