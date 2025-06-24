import 'package:flutter/material.dart';

import 'custom_filled_button.dart';

class ContainerActionButtons extends StatelessWidget {
  final List<CustomFilledButton> children;

  const ContainerActionButtons({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.end,
      children: children,
    );
  }
}
