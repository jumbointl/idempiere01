// response_async_value_ui_model.dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import '../../../shared/data/messages.dart';

class ResponseAsyncValueUiModel {
  final ResponseUiState state;

  final String title;
  final String subtitle;
  final String message;

  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  // Optional action
  final String? buttonLabel;
  final VoidCallback? onPressed;
  final IconData? buttonIcon;


  const ResponseAsyncValueUiModel({
    required this.state,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    this.buttonLabel,
    this.onPressed,
    this.buttonIcon,
  });
}

ResponseAsyncValueUiModel mapResponseAsyncValueToUi({
  required ResponseAsyncValue result,
  required String title,
  required String subtitle,
  Color? borderColor,
  String? buttonLabel,
  VoidCallback? onPressed,
  IconData? buttonIcon,
}) {
  // Initial state: waiting for scan
  if (!result.isInitiated) {
    return ResponseAsyncValueUiModel(
      title: title,
      subtitle: subtitle,
      message: Messages.WAIT_FOR_SEARCH,
      backgroundColor: Colors.cyan[200]!,
      borderColor: borderColor ?? Colors.amber.shade800,
      icon: Icons.qr_code_scanner,
      state: resolveUiState(result),
      buttonLabel: buttonLabel,
      onPressed: onPressed,
      buttonIcon: buttonIcon,
    );
  }

  // Success but no data
  if (result.success && result.data == null) {
    return ResponseAsyncValueUiModel(
      title: title,
      subtitle: subtitle,
      message: Messages.NO_DATA_FOUND,
      backgroundColor: borderColor ?? Colors.amber[500]!,
      borderColor: Colors.amber.shade800,
      icon: Symbols.explosion_rounded,
      state: resolveUiState(result),
      buttonLabel: buttonLabel,
      onPressed: onPressed,
      buttonIcon: buttonIcon,

    );
  }

  // Error state
  return ResponseAsyncValueUiModel(
    title: title,
    subtitle: subtitle,
    message: result.message ?? Messages.ERROR,
    backgroundColor: Colors.red[200]!,
    borderColor: Colors.red,
    icon: Icons.error,
    state: resolveUiState(result),
    buttonLabel: buttonLabel,
    onPressed: onPressed,
    buttonIcon: buttonIcon,
  );
}

enum ResponseUiState {
  idle, // isInitiated == false
  emptyOk, // success == true && data == null
  error, // success == false
}

ResponseUiState resolveUiState(ResponseAsyncValue r) {
  // English comment: "State resolution must be deterministic for animation keys"
  if (!r.isInitiated) return ResponseUiState.idle;
  if (r.success && r.data == null) return ResponseUiState.emptyOk;
  return ResponseUiState.error;
}
