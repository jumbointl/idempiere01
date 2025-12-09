import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';

import 'mo_printer.dart';

const String kSavedPrintersKey = 'saved_printers';

final savedPrintersProvider = StateProvider<List<MOPrinter>>((ref) {
  final box = GetStorage();
  final raw = box.read(kSavedPrintersKey);

  if (raw is List) {
    return raw.map<MOPrinter>((item) {
      if (item is Map) {
        final p = MOPrinter();
        p.name       = item['name']       as String?;
        p.ip         = item['ip']         as String?;
        p.port       = item['port']       as String?;
        p.type       = item['type']       as String?;
        p.serverIp   = item['serverIp']   as String?;
        p.serverPort = item['serverPort'] as String?;
        return p;
      }
      if (item is String) {
        // por si un día guardas como json string
        final map = jsonDecode(item) as Map<String, dynamic>;
        final p = MOPrinter();
        p.name       = map['name']       as String?;
        p.ip         = map['ip']         as String?;
        p.port       = map['port']       as String?;
        p.type       = map['type']       as String?;
        p.serverIp   = map['serverIp']   as String?;
        p.serverPort = map['serverPort'] as String?;
        return p;
      }
      return MOPrinter();
    }).toList();
  }

  return <MOPrinter>[];
});
Future<void> savePrinterToStorage(WidgetRef ref, MOPrinter printer) async {
  final box  = GetStorage();
  final list = loadSavedPrinters();

  // 🔑 unicidad por ip+port
  final index = list.indexWhere(
        (p) => (p.ip ?? '') == (printer.ip ?? '') && (p.port ?? '') == (printer.port ?? ''),
  );

  if (index >= 0) {
    final existing = list[index];
    // si el nuevo no trae noborrar, conserva el valor anterior
    printer.noDelete ??= existing.noDelete ?? false;
    list.removeAt(index);
  }

  // 👉 más usada = la que se usó/guardó más recientemente
  list.insert(0, printer);

  // 🎯 aplicar límite de 10 sin tocar las protegidas (noborrar == true)
  final pinned  = list.where((p) => p.noDelete == true).toList();
  final normals = list.where((p) => p.noDelete != true).toList();

  // máximo 10 impresoras totales, pero nunca borramos las pinned
  const int maxTotal = 10;
  final int maxNormales = (maxTotal - pinned.length).clamp(0, 1000);

  final trimmedNormals = normals.take(maxNormales).toList();

  final finalList = <MOPrinter>[];
  // puedes decidir si quieres pinned primero o dejar orden por uso.
  // Aquí: primero pinned, luego las más usadas normales
  finalList.addAll(pinned);
  finalList.addAll(trimmedNormals);

  final jsonList = finalList.map((p) => p.toJson()).toList();

  await box.write(kSavedPrintersKey, jsonList);
  ref.read(savedPrintersProvider.notifier).state = List<MOPrinter>.from(finalList);
}
List<MOPrinter> loadSavedPrinters() {
  final box = GetStorage();
  final raw = box.read(kSavedPrintersKey);

  if (raw is List) {
    return raw.map<MOPrinter>((item) {
      if (item is Map) {
        final p = MOPrinter();
        p.name       = item['name']       as String?;
        p.ip         = item['ip']         as String?;
        p.port       = item['port']       as String?;
        p.type       = item['type']       as String?;
        p.serverIp   = item['serverIp']   as String?;
        p.serverPort = item['serverPort'] as String?;
        p.noDelete   = item['noDelete']   as bool? ?? false; // 👈 AQUI
        return p;
      }
      if (item is String) {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final p = MOPrinter();
        p.name       = map['name']       as String?;
        p.ip         = map['ip']         as String?;
        p.port       = map['port']       as String?;
        p.type       = map['type']       as String?;
        p.serverIp   = map['serverIp']   as String?;
        p.serverPort = map['serverPort'] as String?;
        p.noDelete   = map['noDelete']   as bool? ?? false; // 👈 AQUI
        return p;
      }
      return MOPrinter();
    }).toList();
  }

  return <MOPrinter>[];
}