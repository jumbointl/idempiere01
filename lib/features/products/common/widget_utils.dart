import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_theme.dart';
import 'input_dialog.dart';

Widget compactIconButton({
  required IconData icon,
  required VoidCallback onPressed,
  Color? color,
  String? tooltip,
}) {
  return IconButton(
    icon: Icon(icon, color: color),
    tooltip: tooltip,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(
      minWidth: 32,
      minHeight: 32,
    ),
    iconSize: 18,
    onPressed: onPressed,
  );
}
Widget compactElevatedButton({
  required String label,
  required VoidCallback onPressed,
  Color? backgroundColor,
  Widget? icon,          // opcional: ícone à esquerda
}) {
  return SizedBox(
    height: 36, // 🔹 altura bem mais baixa que o padrão
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? themeColorPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 13),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}
class CompactEditableField extends ConsumerWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  final void Function(WidgetRef ref)? onTapAction;
  final void Function(WidgetRef ref)? onEditingCompleteAction;

  const CompactEditableField({
    super.key,
    required this.label,
    required this.controller,
    required this.keyboardType,
    this.onTapAction,
    this.onEditingCompleteAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14), // texto menor

      onTap: () {
        if (onTapAction != null) {
          onTapAction!(ref);
        }
      },

      onEditingComplete: () {
        if (onEditingCompleteAction != null) {
          onEditingCompleteAction!(ref);
        }
      },

      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class CompactEditableFieldScreenInput extends ConsumerWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  // Extras que usas para el diálogo
  final bool history; // tip: cámbialo por tu tipo real (List<String>, etc.)
  final String title;
  final bool numberOnly;

  // Opcional: hook extra si quieres hacer algo luego de setear el texto
  final void Function(WidgetRef ref, String newValue)? onChangedAfterDialog;

  const CompactEditableFieldScreenInput({
    super.key,
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.history,
    required this.title,
    this.numberOnly = false,
    this.onChangedAfterDialog,
  });

  Future<void> _handleTap(WidgetRef ref) async {
    final result = await openInputDialogWithResult(
      ref.context,
      ref,
      history,
      title: title,
      value: controller.text,
      numberOnly: numberOnly,
    );

    if (result == null) return;

    controller.text = result; // <- aquí estaba el "resulte" typo :)
    onChangedAfterDialog?.call(ref, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      readOnly: true, // clave: evita que aparezca teclado si usas diálogo
      onTap: () => _handleTap(ref),

      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}