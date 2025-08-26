import 'package:flutter/material.dart';

/// Reusable settings tile widget
class SettingsTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.leading,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabledColor = Theme.of(context).disabledColor;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          minLeadingWidth: 0,
          leading: Icon(leading, color: Theme.of(context).primaryColor),
          title: Text(title),
          trailing:
              trailing ??
              Icon(Icons.arrow_forward_ios, size: 16, color: disabledColor),
          onTap: onTap,
        ),
        Divider(color: Theme.of(context).dividerColor),
      ],
    );
  }
}
