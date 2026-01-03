import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pos_adjustment_values.dart';

Future<PosAdjustmentValues?> showPosProfileEditorSheet({
  required BuildContext context,
  required WidgetRef ref,
  required int suggestedNextId,
  PosAdjustmentValues? initial,
}) async {
  final modelCtrl = TextEditingController(text: initial?.machineModel ?? '');
  final widthCtrl = TextEditingController(
      text: (initial?.printWidthAdjustment ?? 0).toString());
  final charsCtrl = TextEditingController(
      text: (initial?.charactersPerLineAdjustment ?? 0).toString());

  var charSet = initial?.charSet ?? PosCharSet.cp850;
  var isDefault = initial?.isDefault ?? false;

  int parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  return showModalBottomSheet<PosAdjustmentValues>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  initial == null ? 'Crear perfil POS' : 'Editar perfil POS',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Modelo de máquina',
                    hintText: 'Ej: BEMATECH MP-4200 TH',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widthCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ajuste ancho (dots)',
                          helperText: 'Ej: -48 (576→528)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: charsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ajuste caracteres',
                          helperText: 'Ej: -4 (48→44)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PosCharSet>(
                        value: charSet,
                        items: PosCharSet.values
                            .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name.toUpperCase()),
                        ))
                            .toList(),
                        onChanged: (v) => setState(() => charSet = v ?? PosCharSet.cp850),
                        decoration: const InputDecoration(labelText: 'Charset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Default'),
                        value: isDefault,
                        onChanged: (v) => setState(() => isDefault = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final model = modelCtrl.text.trim();
                          if (model.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Modelo no puede estar vacío')),
                            );
                            return;
                          }
                          final id = initial?.id ?? suggestedNextId;

                          final result = PosAdjustmentValues(
                            id: id,
                            machineModel: model,
                            printWidthAdjustment: parseInt(widthCtrl.text),
                            charactersPerLineAdjustment: parseInt(charsCtrl.text),
                            charSet: charSet,
                            isDefault: isDefault,
                          );

                          Navigator.pop(context, result);
                        },
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
