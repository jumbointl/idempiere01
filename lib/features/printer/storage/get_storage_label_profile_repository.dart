import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:monalisapy_features/printer/models/printer_select_models.dart';
import 'package:riverpod_printer/riverpod_printer.dart';
import 'package:riverpod_printer_ui/riverpod_printer_ui.dart';

class GetStorageLabelProfileRepository implements LabelProfileRepository {
  GetStorageLabelProfileRepository(this._box);

  final GetStorage _box;

  @override
  Future<List<LabelProfile>> loadAll() async {
    final dynamic raw = _box.read(PrinterSelectStorageKeys.labelProfilesList);
    if (raw is! String || raw.trim().isEmpty) {
      return const <LabelProfile>[];
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return const <LabelProfile>[];
      return decoded
          .map((e) => LabelProfile.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const <LabelProfile>[];
    }
  }

  @override
  Future<void> saveAll(List<LabelProfile> profiles) async {
    final List<Map<String, dynamic>> payload =
        profiles.map((p) => p.toJson()).toList();
    await _box.write(
      PrinterSelectStorageKeys.labelProfilesList,
      jsonEncode(payload),
    );
  }

  @override
  Future<String?> loadSelectedId() async {
    final dynamic raw = _box.read(PrinterSelectStorageKeys.selectedLabelProfileId);
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return null;
  }

  @override
  Future<void> saveSelectedId(String? id) async {
    await _box.write(PrinterSelectStorageKeys.selectedLabelProfileId, id);
  }
}
