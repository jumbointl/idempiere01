

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/printer_config.dart';

final printerConfigProvider =
StateProvider.autoDispose<PrinterConfig?>((ref) => null);
final printerColorProvider = Provider.autoDispose<Color>((ref) {
  final cfg = ref.watch(printerConfigProvider);

  // English comment: "Green when printer is configured, black otherwise"
  if (cfg != null && cfg.isConfigured) {
    return Colors.green;
  }
  return Colors.black87;
});

final printerLabelProvider = Provider.autoDispose<String>((ref) {
  final cfg = ref.watch(printerConfigProvider);

  if (cfg == null || !cfg.isConfigured) {
    return 'Impresora: no configurada';
  }
  return 'Impresora: ${cfg.ip}:${cfg.port}';
});

