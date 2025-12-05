import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../config/theme/app_theme.dart';
enum DefaultActionWhenUPCIsScanned {
  ask,
  edit,
  sum,
  ignore,
}

final defaultActionWhenUPCIsScannedProvider =
StateProvider<DefaultActionWhenUPCIsScanned>(
      (ref) => DefaultActionWhenUPCIsScanned.ask,
);
Widget verticalSegmentedButtons({
  required DefaultActionWhenUPCIsScanned selected,
  required void Function(DefaultActionWhenUPCIsScanned) onSelected,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [

      _segment(
        label: 'Preguntar',
        icon: Icons.help_outline,
        value: DefaultActionWhenUPCIsScanned.ask,
        selected: selected,
        onSelected: onSelected,
      ),

      _segment(
        label: 'Editar',
        icon: Icons.edit,
        value: DefaultActionWhenUPCIsScanned.edit,
        selected: selected,
        onSelected: onSelected,
      ),

      _segment(
        label: 'Sumar',
        icon: Icons.exposure_plus_1,
        value: DefaultActionWhenUPCIsScanned.sum,
        selected: selected,
        onSelected: onSelected,
      ),

      _segment(
        label: 'Ignorar',
        icon: Icons.block,
        value: DefaultActionWhenUPCIsScanned.ignore,
        selected: selected,
        onSelected: onSelected,
      ),

    ],
  );
}
Widget _segment({
  required String label,
  required IconData icon,
  required DefaultActionWhenUPCIsScanned value,
  required DefaultActionWhenUPCIsScanned selected,
  required void Function(DefaultActionWhenUPCIsScanned) onSelected,
}) {
  final bool isActive = value == selected;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.purple : Colors.grey,
            width: 1.5,
          ),
          color: isActive ? Colors.purple.withOpacity(0.15) : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isActive ? Colors.purple : Colors.grey, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.purple : Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> openDialogSelect3Actions({required BuildContext context,
  required String title,
  required String subtitle,
  required String textButton1,
  required String textButton2,
  required String textButton3,
}) async {
  String? action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: false, // pon true si algún día quieres más alto y scroll
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // altura ajustada al contenido
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtítulo
              Text(
                subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Fila de 3 botones expandibles
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(textButton1, textAlign: TextAlign.center),
                      onPressed: () {
                        Navigator.of(sheetContext).pop(textButton1);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: themeColorPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(textButton2, textAlign: TextAlign.center),
                      onPressed: () {
                        Navigator.of(sheetContext).pop(textButton2);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.cyan[800],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(textButton3, textAlign: TextAlign.center),
                      onPressed: () {
                        Navigator.of(sheetContext).pop(textButton3);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );

  return action ;
}