import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_theme.dart';
import '../../shared/data/messages.dart';


Future<void> showSuccessMessage(
    BuildContext context,
    WidgetRef ref,
    String message, {
      int durationSeconds = 3,
    }) async {
  // Wait briefly if widget tree is still mounting
  if (!context.mounted) {
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;
  }

  await showSuccessCenterToast(
    context,
    message,
    durationSeconds: durationSeconds,
  );
}
Future<void> showWarningMessage(
    BuildContext context,
    WidgetRef ref,
    String message, {
      int durationSeconds = 3,
    }) async {
  // Wait briefly if widget tree is still mounting
  if (!context.mounted) {
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;
  }

  await showWarningCenterToast(
    context,
    message,
    durationSeconds: durationSeconds,
  );
}

Future<bool> showConfirmDialog(
    BuildContext context, {
      required String title,
      required String message,
      String cancelText = 'Cancelar',
      String okText = 'Aceptar',
      Color? okColor,
      Color? cancelColor,
      IconData icon = Icons.help_outline_rounded,
      Color iconColor = Colors.amber,
    }) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeBorderRadius),
        ),
        title: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: cancelColor ?? themeColorError,
            ),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: okColor ?? themeColorSuccessful,
              foregroundColor: Colors.white,
            ),
            child: Text(okText),
          ),
        ],
      );
    },
  );

  return result ?? false;
}


Future<bool?> showConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    String message,
    ) {
  return showDialog<bool?>(
    context: context,
    barrierDismissible: true, // Allows dismiss by tapping outside
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            message,
            style: const TextStyle(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // User explicitly cancelled
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(Messages.CANCEL),
          ),
          ElevatedButton(
            onPressed: () {
              // User confirmed action
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(Messages.OK),
          ),
        ],
      );
    },
  );
}
Future<void> showErrorMessage(
    BuildContext context,
    WidgetRef ref,
    String message, {
      int durationSeconds = 3,
    }) async {
  // Wait briefly if widget tree is still mounting
  if (!context.mounted) {
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;
  }

  await showErrorCenterToast(
    context,
    message,
    durationSeconds: durationSeconds,
  );
}

OverlayEntry? _centerToastEntry;

/// Shows a centered toast using Overlay.
/// - durationSeconds: default 3
/// - durationSeconds == 0: manual close (tap or X button)
Future<void> _showCenterToast(
    BuildContext context, {
      required String message,
      required IconData icon,
      required Color accentColor,
      int durationSeconds = 3,
    }) async {
  _dismissCenterToast();

  final overlay = Overlay.of(context);

  late final OverlayEntry entry;
  final completer = Completer<void>();

  void close() {
    if (!completer.isCompleted) {
      completer.complete();
    }
    if (_centerToastEntry == entry) {
      _dismissCenterToast();
    }
  }

  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Center(
            child: GestureDetector(
              onTap: durationSeconds == 0 ? close : null,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 20,
                      offset: Offset(0, 10),
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accentColor, size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: close,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  _centerToastEntry = entry;
  overlay.insert(entry);

  if (durationSeconds > 0) {
    Future.delayed(Duration(seconds: durationSeconds), close);
  }

  await completer.future;
}
void _dismissCenterToast() {
  _centerToastEntry?.remove();
  _centerToastEntry = null;
}

/// Success toast (green)
Future<void> showSuccessCenterToast(
    BuildContext context,
    String message, {
      int durationSeconds = 3,
    }) async {
  await _showCenterToast(
    context,
    message: message,
    icon: Icons.check_circle_rounded,
    accentColor: Colors.green,
    durationSeconds: durationSeconds,
  );
}

/// Error toast (red)
Future<void> showErrorCenterToast(
    BuildContext context,
    String message, {
      int durationSeconds = 3,
    }) async {
  await _showCenterToast(
    context,
    message: message,
    icon: Icons.error_rounded,
    accentColor: Colors.red,
    durationSeconds: durationSeconds,
  );
}

/// Warning toast (yellow)
Future<void> showWarningCenterToast(
    BuildContext context,
    String message, {
      int durationSeconds = 3,
    }) async {
  await _showCenterToast(
    context,
    message: message,
    icon: Icons.warning_amber_rounded,
    accentColor: Colors.amber,
    durationSeconds: durationSeconds,
  );
}
