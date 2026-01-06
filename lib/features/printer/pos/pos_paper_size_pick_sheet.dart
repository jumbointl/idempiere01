import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

Future<PaperSize?> showPaperSizePickFromColsSheet(BuildContext context) {
  return showModalBottomSheet<PaperSize>(
    context: context,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('Selecciona el bloque correcto'),
            subtitle: Text('Elige el que NO se corta y llega al borde.'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(child: Text('1')),
            title: const Text('COLS=32 → Paper 58mm'),
            onTap: () => Navigator.pop(context, PaperSize.mm58),
          ),
          ListTile(
            leading: const CircleAvatar(child: Text('2')),
            title: const Text('COLS=42 → Paper 72mm'),
            onTap: () => Navigator.pop(context, PaperSize.mm72),
          ),
          ListTile(
            leading: const CircleAvatar(child: Text('3')),
            title: const Text('COLS=48 → Paper 80mm'),
            onTap: () => Navigator.pop(context, PaperSize.mm80),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
