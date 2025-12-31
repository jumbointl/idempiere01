import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';

/// ===============================
/// MODELO
/// ===============================
class ZplPrintProfile {
  final String id;
  final String name;

  /// Cantidad de productos (movementLines) por etiqueta
  final int rowsPerLabel;

  /// Cuántas líneas permites para productNameWithLine: 1 o 2
  final int rowPerProductName;

  /// Ajustes prácticos de impresión
  final int marginX;
  final int marginY;

  ZplPrintProfile({
    required this.id,
    required this.name,
    required this.rowsPerLabel,
    required this.rowPerProductName,
    required this.marginX,
    required this.marginY,
  });

  ZplPrintProfile copyWith({
    String? id,
    String? name,
    int? rowsPerLabel,
    int? rowPerProductName,
    int? marginX,
    int? marginY,
  }) {
    return ZplPrintProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      rowsPerLabel: rowsPerLabel ?? this.rowsPerLabel,
      rowPerProductName: rowPerProductName ?? this.rowPerProductName,
      marginX: marginX ?? this.marginX,
      marginY: marginY ?? this.marginY,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'rowsPerLabel': rowsPerLabel,
    'rowPerProductName': rowPerProductName,
    'marginX': marginX,
    'marginY': marginY,
  };

  factory ZplPrintProfile.fromMap(Map<String, dynamic> map) {
    return ZplPrintProfile(
      id: map['id'],
      name: map['name'],
      rowsPerLabel: (map['rowsPerLabel'] ?? 4) as int,
      rowPerProductName: (map['rowPerProductName'] ?? 2) as int,
      marginX: (map['marginX'] ?? 20) as int,
      marginY: (map['marginY'] ?? 20) as int,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ZplPrintProfile.fromJson(String s) =>
      ZplPrintProfile.fromMap(jsonDecode(s));
}

/// ===============================
/// STORAGE
/// ===============================
class ZplProfileStorage {
  static const _key = 'zpl_print_profiles';
  static final _box = GetStorage();

  static List<ZplPrintProfile> load() {
    final raw = _box.read<List>(_key) ?? const [];
    return raw
        .map((e) => ZplPrintProfile.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static void save(List<ZplPrintProfile> profiles) {
    _box.write(_key, profiles.map((e) => e.toMap()).toList());
  }
}
class ZplActiveProfileStorage {
  static const _key = 'zpl_print_profile_active_id';
  static final _box = GetStorage();

  static String? loadActiveId() => _box.read<String>(_key);

  static void saveActiveId(String id) => _box.write(_key, id);

  static void clear() => _box.remove(_key);
}

ZplPrintProfile? loadActiveOrFirstProfile() {
  final profiles = ZplProfileStorage.load();
  if (profiles.isEmpty) return null;

  final activeId = ZplActiveProfileStorage.loadActiveId();
  if (activeId == null || activeId.isEmpty) return profiles.first;

  final idx = profiles.indexWhere((p) => p.id == activeId);
  return idx >= 0 ? profiles[idx] : profiles.first;
}

/// ===============================
/// PROVIDER
/// ===============================
final zplProfilesProvider =
StateNotifierProvider<ZplProfilesNotifier, List<ZplPrintProfile>>(
      (ref) => ZplProfilesNotifier(),
);

class ZplProfilesNotifier extends StateNotifier<List<ZplPrintProfile>> {
  ZplProfilesNotifier() : super(ZplProfileStorage.load()) {
    // Si no hay nada, crea 1 perfil por defecto
    if (state.isEmpty) {
      final p = ZplPrintProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Default 100x150',
        rowsPerLabel: 4,
        rowPerProductName: 2,
        marginX: 20,
        marginY: 20,
      );
      state = [p];
      ZplProfileStorage.save(state);
    }
  }

  void add(ZplPrintProfile p) {
    state = [...state, p];
    ZplProfileStorage.save(state);
  }

  void update(ZplPrintProfile p) {
    state = [
      for (final e in state) if (e.id == p.id) p else e,
    ];
    ZplProfileStorage.save(state);
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    ZplProfileStorage.save(state);
  }
}

/// ===============================
/// CÁLCULO AUTOMÁTICO (203dpi, 100x150)
/// Header 40mm incl QR, Footer 10mm, TableHeader 10mm
/// ===============================

class ZplPhysical {
  static const int labelHeightDots = 1200; // 150mm * 8
  static const int headerHeightDots = 320; // 40mm * 8 (incluye QR)
  static const int footerHeightDots = 80;  // 10mm * 8
  static const int tableHeaderDots = 80;   // 10mm * 8
}

/// Devuelve el máximo REAL de productos por etiqueta para evitar pisar footer.
int maxRowsAllowed({
  required int marginY,
  required int rowPerProductName, // 1 o 2
}) {
  final bodyHeight =
      ZplPhysical.labelHeightDots -
          marginY -
          ZplPhysical.headerHeightDots -
          ZplPhysical.footerHeightDots -
          marginY;

  final usable = bodyHeight - ZplPhysical.tableHeaderDots;
  if (usable <= 0) return 1;

  // Si usas ^A0N,28,... un paso seguro de línea:
  const linePitch = 32;

  final nameLines = rowPerProductName.clamp(1, 2);

  // Bloque por producto:
  // upc/to + sku/from + attr (3 líneas)
  // + productName (1 o 2 líneas)
  // + padding + separador
  final perItem = (linePitch * (3 + nameLines)) + 30;

  return (usable ~/ perItem).clamp(1, 999);
}


enum ZplLabelType {
  movementDetail,
  movementByCategory,
}

const String kZplLabelTypeKey = 'zpl_label_type';

String zplLabelTypeToStorage(ZplLabelType t) => t.name;

ZplLabelType? zplLabelTypeFromStorage(String? s) {
  if (s == null || s.isEmpty) return null;
  for (final v in ZplLabelType.values) {
    if (v.name == s) return v;
  }
  return null;
}


Future<ZplLabelType?> showZplLabelTypeSheet(
    BuildContext context, {
      ZplLabelType? current,
    }) async {
  final box = GetStorage();

  return showModalBottomSheet<ZplLabelType>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      Widget item({
        required IconData icon,
        required String title,
        required String subtitle,
        required ZplLabelType value,
      }) {
        final selected = value == current;
        return ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: () {
            box.write(kZplLabelTypeKey, zplLabelTypeToStorage(value));
            Navigator.of(ctx).pop(value);
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Tipo de label a imprimir'),
                subtitle: Text('Selecciona el formato de etiqueta'),
              ),
              item(
                icon: Icons.list_alt,
                title: 'MovementDetail',
                subtitle: 'Detalle por línea / producto',
                value: ZplLabelType.movementDetail,
              ),
              item(
                icon: Icons.category,
                title: 'Movement by Category',
                subtitle: 'Agrupado por categoría (totales)',
                value: ZplLabelType.movementByCategory,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );
}
