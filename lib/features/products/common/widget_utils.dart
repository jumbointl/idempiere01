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

  // Extras para el diálogo
  final bool history;
  final String title;
  final bool numberOnly;

  /// 🔹 NUEVO: altura opcional del campo
  /// Ejemplo: 48 (default), 56, 64, etc.
  final double? height;

  /// Hook opcional luego de cambiar valor
  final void Function(WidgetRef ref, String newValue)? onChangedAfterDialog;

  const
  CompactEditableFieldScreenInput({
    super.key,
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.history,
    required this.title,
    this.numberOnly = false,
    this.height,
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

    controller.text = result;
    onChangedAfterDialog?.call(ref, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double fieldHeight = height ?? 40; // default compacto

    return SizedBox(
      height: fieldHeight,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        readOnly: true,
        onTap: () => _handleTap(ref),

        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: fieldHeight >= 56 ? 14 : 6, // adapta padding
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}



/// ✅ DropdownButtonFormField "alineado" para pantallas tipo formulario,
/// consistente con el nuevo CompactEditableFieldScreenInput (InputDecorator).
///
/// - Altura estable (default 48)
/// - isDense true
/// - Bordes redondeados iguales
/// - Mismo estilo de label
class DropdownButtonFormFieldScreenInput<T> extends ConsumerWidget {
  final String label;

  /// Valor actual (puede ser null si permites vacío)
  final T? value;

  /// Items del dropdown
  final List<DropdownMenuItem<T>> items;

  /// Callback al cambiar
  final void Function(T? value)? onChanged;

  /// Opcional: hint dentro del campo
  final String? hintText;

  /// Opcional: deshabilitar
  final bool enabled;

  /// 🔹 Nuevo: altura opcional (por defecto 48)
  final double height;

  /// Opcional: estilo de texto
  final TextStyle? textStyle;

  /// Opcional: tamaño del ícono
  final double iconSize;

  const DropdownButtonFormFieldScreenInput({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
    this.height = 48,
    this.textStyle,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Para un look consistente, usamos InputDecoration + constraints.
    return SizedBox(
      height: height,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        isExpanded: true,
        iconSize: iconSize,
        style: textStyle ?? const TextStyle(fontSize: 14, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        hint: hintText == null
            ? null
            : Text(
          hintText!,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
    );
  }
}

class EditableFieldScreenInput extends ConsumerWidget {
  final String label;
  final TextEditingController controller;

  // Diálogo
  final bool history;
  final String title;
  final bool numberOnly;

  /// Altura base para 1 línea
  final double height;

  final String? hintText;
  final bool enabled;
  final int maxLines;

  final void Function(WidgetRef ref, String newValue)? onChangedAfterDialog;

  const EditableFieldScreenInput({
    super.key,
    required this.label,
    required this.controller,
    required this.history,
    required this.title,
    this.numberOnly = false,
    this.height = 48,
    this.hintText,
    this.enabled = true,
    this.maxLines = 1,
    this.onChangedAfterDialog,
  });

  Future<void> _handleTap(WidgetRef ref) async {
    if (!enabled) return;

    final result = await openInputDialogWithResult(
      ref.context,
      ref,
      history,
      title: title,
      value: controller.text,
      numberOnly: numberOnly,
    );

    if (result == null) return;

    controller.text = result;
    onChangedAfterDialog?.call(ref, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display =
    controller.text.trim().isEmpty ? (hintText ?? '') : controller.text.trim();

    final bool isMultiline = maxLines > 1;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height,
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12),
          isDense: true,
          enabled: enabled,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        child: InkWell(
          onTap: () => _handleTap(ref),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment:
              isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    display.isEmpty ? ' ' : display,
                    maxLines: maxLines,
                    overflow:
                    isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled ? Colors.black : Colors.black38,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: EdgeInsets.only(
                    top: isMultiline ? 4 : 0,
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 18,
                    color: enabled ? Colors.black54 : Colors.black26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

