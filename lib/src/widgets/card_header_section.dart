// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

class CardHeaderSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final EdgeInsetsGeometry padding;

  const CardHeaderSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: padding,
      title: Text(subtitle, style: context.bodySmall),
      subtitle: Text(
        title,
        style: context.bodyMedium.copyWith(
          //Theme.of(context).colorScheme.secondary,
          color: context.secondaryContent,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: trailing,
    );
  }
}
