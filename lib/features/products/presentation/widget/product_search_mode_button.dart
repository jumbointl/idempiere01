import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../shared/data/messages.dart';
import '../providers/actions/find_product_by_sku_name_action_provider.dart';


String _label(ProductSearchMode mode) {

  switch (mode) {
    case ProductSearchMode.upc:
      return 'UPC';
    case ProductSearchMode.sku:
      return 'SKU';
    case ProductSearchMode.name:
      return 'NAME';
  }
}
String _labelLarge(ProductSearchMode mode) {

  switch (mode) {
    case ProductSearchMode.upc:
      return Messages.FIND_PRODUCT_BY_UPC;
    case ProductSearchMode.sku:
      return Messages.FIND_PRODUCT_BY_SKU;
    case ProductSearchMode.name:
      return Messages.FIND_BY_NAME;
  }
}


Widget getSearchModeButton({
  bool? largeButton,
  required BuildContext context,
  void Function(ProductSearchMode mode)? onModeChanged,
}) {
  return Consumer(
    builder: (context, ref, _) {
      final mode = ref.watch(productSearchModeProvider);
      if (largeButton == true) {
        return TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => _SearchModeDialog(
                onModeChanged: onModeChanged,
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(
                color: Colors.purple,
                width: 1,
              ),
            ),
            foregroundColor: Colors.purple,
          ),
          child: Text(
            _labelLarge(mode),
            style: const TextStyle(
              fontSize: themeFontSizeNormal,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }


      return TextButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => _SearchModeDialog(
              onModeChanged: onModeChanged,
            ),
          );
        },
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: Colors.purple,
              width: 0.8,
            ),
          ),
          foregroundColor: Colors.purple,
        ),
        child: Text(
          _label(mode),
          style: const TextStyle(fontSize: 12),
        ),
      );
    },
  );
}


class _SearchModeDialog extends ConsumerWidget {
  final void Function(ProductSearchMode mode)? onModeChanged;
  const _SearchModeDialog({this.onModeChanged});
  void _applyMode(
      BuildContext context,
      WidgetRef ref,
      ProductSearchMode mode,
      ) {
    ref.read(productSearchModeProvider.notifier).state = mode;

    // cerrar primero
    Navigator.pop(context);

    // y después ejecutar callback
    if (onModeChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onModeChanged!(mode);
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(productSearchModeProvider);

    return AlertDialog(
      title: const Text('Modo de búsqueda'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tile(
            context,
            selected: selectedMode == ProductSearchMode.upc,
            icon: Icons.qr_code_scanner,
            title: 'UPC',
            subtitle: 'Buscar por código de barras o id del producto',
            onTap: () => _applyMode(context,ref, ProductSearchMode.upc),
          ),
          _tile(
            context,
            selected: selectedMode == ProductSearchMode.sku,
            icon: Icons.tag,
            title: 'SKU',
            subtitle: 'Buscar por SKU',
            onTap: () => _applyMode(context,ref, ProductSearchMode.sku),
          ),
          _tile(
            context,
            selected: selectedMode == ProductSearchMode.name,
            icon: Icons.search,
            title: 'NOMBRE',
            subtitle: 'Buscar por nombre del producto',
            onTap: () => _applyMode(context,ref, ProductSearchMode.name),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _tile(
      BuildContext context, {
        required bool selected,
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check_circle) : null,
        onTap: onTap,
      ),
    );
  }
}
