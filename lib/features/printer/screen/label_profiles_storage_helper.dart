import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_printer/riverpod_printer.dart';
import '../../products/presentation/providers/common_provider.dart';
import '../models/printer_select_models.dart';

typedef DefaultProfileFactory = LabelProfile Function();

class LabelProfilesStorageHelper {
  final dynamic box; // GetStorage o similar
  final WidgetRef ref;

  final DefaultProfileFactory default40x25;
  final DefaultProfileFactory default60x40;
  final DefaultProfileFactory default50x30;

  LabelProfilesStorageHelper({
    required this.box,
    required this.ref,
    required this.default40x25,
    required this.default60x40,
    required this.default50x30,
  });

  /// Carga lista + selectedId, asegura defaults, actualiza providers y persiste.
  /// Devuelve el perfil seleccionado (o el primero).
  LabelProfile loadAndHydrateProviders({
    String listKey = PrinterSelectStorageKeys.labelProfilesList,
    String selectedIdKey = PrinterSelectStorageKeys.selectedLabelProfileId,
  }) {
    final raw = box.read(listKey);
    final selectedIdRaw = box.read(selectedIdKey);

    var list = _decodeProfiles(raw);

    // asegurar defaults
    list = _ensureDefault(list, default40x25(), 'default_40x25');
    list = _ensureDefault(list, default60x40(), 'default_60x40');
    list = _ensureDefault(list, default50x30(), 'default_50x30');

    // guardar lista a provider
    ref.read(labelProfilesProvider.notifier).state = list;

    // selected id
    final selectedId = (selectedIdRaw is String && selectedIdRaw.trim().isNotEmpty)
        ? selectedIdRaw.trim()
        : list.first.id;

    ref.read(selectedLabelProfileIdProvider.notifier).state = selectedId;

    // persistir coherente (lista + selectedId)
    saveFromProviders(listKey: listKey, selectedIdKey: selectedIdKey);

    // devolver perfil seleccionado
    return list.firstWhere(
          (p) => p.id == selectedId,
      orElse: () => list.first,
    );
  }

  /// Persiste usando providers actuales (o lista/id opcionales)
  void saveFromProviders({
    String listKey = PrinterSelectStorageKeys.labelProfilesList,
    String selectedIdKey = PrinterSelectStorageKeys.selectedLabelProfileId,
  }) {
    final list = ref.read(labelProfilesProvider);
    final selectedId = ref.read(selectedLabelProfileIdProvider);

    final payload = jsonEncode(list.map((e) => e.toJson()).toList());
    box.write(listKey, payload);
    box.write(selectedIdKey, selectedId);
  }

  // -------------------------
  // Private helpers
  // -------------------------
  List<LabelProfile> _decodeProfiles(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => LabelProfile.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {}
    }
    return <LabelProfile>[];
  }

  List<LabelProfile> _ensureDefault(List<LabelProfile> list, LabelProfile def, String id) {
    final exists = list.any((e) => e.id == id);
    if (!exists) return [...list, def];
    return list;
  }
}
