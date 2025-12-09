import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_theme.dart';

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