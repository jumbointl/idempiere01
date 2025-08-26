import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

/// Section title for grouping settings
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: context.bodyMedium.bold),
    );
  }
}

//Theme.of(context).colorScheme.secondary
