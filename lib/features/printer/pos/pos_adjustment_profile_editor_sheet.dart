import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:monalisa_app_001/config/config.dart';

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

  final escTCtrl =
  TextEditingController(text: initial?.escTCodeTable?.toString() ?? '');

  // ---------- ESTADO ----------
  var charSet = initial?.charSet ?? PosCharSet.cp1252;
  var textMode = initial?.textMode ?? PosTextMode.generator;
  var paperSize = initial?.paperSize ?? PaperSize.mm80; // ✅ NUEVO
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
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // ---------- MODELO ----------
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Modelo de máquina',
                    hintText: 'Ej: BEMATECH MP-4200 TH',
                  ),
                ),

                const SizedBox(height: 10),

                // ---------- AJUSTES ----------
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
                DropdownButtonFormField<PaperSize>(
                  initialValue: paperSize,
                  items: const [
                    DropdownMenuItem(
                      value: PaperSize.mm58,
                      child: Text('58 mm (384 dots)',style: TextStyle(
                          fontSize: themeFontSizeLarge
                      ),),
                    ),
                    DropdownMenuItem(
                      value: PaperSize.mm72,
                      child: Text('72 mm (512 dots)',style: TextStyle(
                          fontSize: themeFontSizeLarge
                      ),),
                    ),
                    DropdownMenuItem(
                      value: PaperSize.mm80,
                      child: Text('80 mm (576 dots)',style: TextStyle(
                          fontSize: themeFontSizeLarge
                      ),),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => paperSize = v ?? PaperSize.mm80),
                  decoration:
                  const InputDecoration(labelText: 'Paper size'),
                ),
                // ---------- PAPERSIZE + TEXT MODE ----------
                const SizedBox(height: 10),
                DropdownButtonFormField<PosTextMode>(
                  initialValue: textMode,
                  items: PosTextMode.values
                      .map(
                        (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name,style: TextStyle(
                          fontSize: themeFontSizeLarge
                      ),),
                    ),
                  )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => textMode = v ?? PosTextMode.generator),
                  decoration:
                  const InputDecoration(labelText: 'Text mode'),
                ),

                const SizedBox(height: 10),

                // ---------- CHARSET ----------
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PosCharSet>(
                        initialValue: charSet,
                        items: PosCharSet.values
                            .map(
                              (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name.toUpperCase(),style: TextStyle(
                              fontSize: themeFontSizeNormal
                            ),),
                          ),
                        )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => charSet = v ?? PosCharSet.cp1252),
                        decoration:
                        const InputDecoration(labelText: 'Charset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: escTCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ESC t (code table)',
                          helperText:
                          'Opcional. Ej: 16=CP1252, 2=CP850, 5=CP858, 8=UTF8',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ---------- DEFAULT ----------
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Default'),
                  value: isDefault,
                  onChanged: (v) => setState(() => isDefault = v),
                ),

                const SizedBox(height: 16),

                // ---------- ACTIONS ----------
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
                              const SnackBar(
                                  content:
                                  Text('Modelo no puede estar vacío')),
                            );
                            return;
                          }

                          final id = initial?.id ?? suggestedNextId;

                          final result = PosAdjustmentValues(
                            id: id,
                            machineModel: model,
                            paperSize: paperSize, // ✅ AHORA SÍ
                            printWidthAdjustment: parseInt(widthCtrl.text),
                            charactersPerLineAdjustment:
                            parseInt(charsCtrl.text),
                            charSet: charSet,
                            textMode: textMode,
                            escTCodeTable: escTCtrl.text.trim().isEmpty
                                ? null
                                : parseInt(escTCtrl.text),
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
