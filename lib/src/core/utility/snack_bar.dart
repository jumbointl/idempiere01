import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

extension SnackbarExtension on BuildContext {
  void showSnackBar(
    String message, {
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(this);
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor ?? background,
      elevation: 6,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor ?? bodyTextColor),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );

    // ScaffoldMessenger.of(this).clearSnackBars();
    // ScaffoldMessenger.of(this).showSnackBar(snackBar);
  }
}
