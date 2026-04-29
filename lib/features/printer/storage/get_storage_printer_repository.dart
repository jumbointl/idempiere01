import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:monalisapy_features/printer/models/printer_select_models.dart';
import 'package:riverpod_printer/riverpod_printer.dart';
import 'package:riverpod_printer_ui/riverpod_printer_ui.dart';

class GetStoragePrinterRepository implements PrinterRepository {
  GetStoragePrinterRepository(this._box);

  final GetStorage _box;

  @override
  Future<List<PrinterDevice>> loadAll() async {
    final dynamic raw = _box.read(PrinterSelectStorageKeys.printersList);
    if (raw is! String || raw.trim().isEmpty) {
      return const <PrinterDevice>[];
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return const <PrinterDevice>[];
      return decoded
          .map((e) => PrinterDevice.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const <PrinterDevice>[];
    }
  }

  @override
  Future<void> saveAll(List<PrinterDevice> printers) async {
    final List<Map<String, dynamic>> payload =
        printers.map((p) => p.toJson()).toList();
    await _box.write(
      PrinterSelectStorageKeys.printersList,
      jsonEncode(payload),
    );
  }

  @override
  Future<String?> loadSelectedId() async {
    final dynamic raw = _box.read(PrinterSelectStorageKeys.selectedPrinterId);
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return null;
  }

  @override
  Future<void> saveSelectedId(String? id) async {
    await _box.write(PrinterSelectStorageKeys.selectedPrinterId, id);
  }
}
