import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../products/domain/idempiere/idempiere_locator.dart';
import '../../domain/entities/line.dart';
import 'm_in_out_providers.dart';

// ---------------- Providers ----------------

// Repeated lines
final repeatedLinesProvider = StateProvider<List<Line>>((ref) => []);

// Lines with null productId
final nullProductIdLinesProvider = StateProvider<List<Line>>((ref) => []);

// ---------------- Logic helpers ----------------

List<Line> findRepeatedLines(List<Line> lines) {
  final Map<int, int> counter = {};

  for (final l in lines) {
    final v = l.line;
    if (v == null) continue;
    counter[v] = (counter[v] ?? 0) + 1;
  }

  return lines.where((l) {
    final v = l.line;
    if (v == null) return false;
    return (counter[v] ?? 0) > 1;
  }).toList();
}

// Repeated lines
final selectedLocatorForMinOutProvider = StateProvider<IdempiereLocator?>((ref) => null

);

List<Line> findLinesWithNullProductId(List<Line> lines) {
  // Chequea: line.mProductId?.id == null
  return lines.where((l) => l.mProductId?.id == null).toList();
}

void updateRepeatedLines(WidgetRef ref, List<Line> lines) {
  ref.read(repeatedLinesProvider.notifier).state = findRepeatedLines(lines);
  ref.read(nullProductIdLinesProvider.notifier).state =
      findLinesWithNullProductId(lines);
}

// ---------------- UI ----------------

Future<void> showRepeatedLinesSheet(BuildContext context, WidgetRef ref) {
  final repeated = ref.read(repeatedLinesProvider);
  final nullProductLines = ref.read(nullProductIdLinesProvider);
  final noConfirmLines = ref.read(lineWithoutConfirmIdProvider);

  final allLines = ref.read(mInOutProvider).mInOut?.allLines ?? [];
  final missingLines = calculateMissingLines(allLines);

  final hasNoConfirmTab = noConfirmLines.isNotEmpty;
  final tabCount = hasNoConfirmTab ? 4 : 3;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return DefaultTabController(
        length: tabCount,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Lines validation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Repeated (${repeated.length})'),
                    Tab(text: 'Missing (${missingLines.length})'),
                    Tab(text: 'Errors (${nullProductLines.length})'),
                    if (hasNoConfirmTab) Tab(text: 'NoConfirm (${noConfirmLines.length})'),
                  ],
                ),

                const SizedBox(height: 8),

                Flexible(
                  child: TabBarView(
                    children: [
                      // Repeated
                      repeated.isEmpty
                          ? const Center(child: Text('No hay líneas repetidas.'))
                          : ListView.separated(
                        itemCount: repeated.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final l = repeated[i];
                          return ListTile(
                            dense: true,
                            title: Text(
                              'Line: ${l.line ?? '-'}   |   ID: ${l.id ?? '-'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'UPC: ${(l.upc ?? '').trim().isEmpty ? '-' : l.upc}\n'
                                  'Product: ${(l.productName ?? '').trim().isEmpty ? '-' : l.productName}',
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),

                      // Missing
                      missingLines.isEmpty
                          ? const Center(child: Text('No hay líneas faltantes.'))
                          : ListView.separated(
                        itemCount: missingLines.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final lineValue = missingLines[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            title: Text(
                              'Missing line: $lineValue',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),

                      // Null productId
                      nullProductLines.isEmpty
                          ? const Center(child: Text('No hay errores de Product ID.'))
                          : ListView.separated(
                        itemCount: nullProductLines.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final l = nullProductLines[i];
                          final upc = (l.upc ?? '').trim();
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.error_rounded, color: Colors.red),
                            title: Text(
                              'ID: ${l.id ?? '-'}   |   Line: ${l.line ?? '-'}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text('UPC: ${upc.isEmpty ? '-' : upc}'),
                          );
                        },
                      ),

                      // NoConfirm (solo si existe)
                      if (hasNoConfirmTab)
                        noConfirmLines.isEmpty
                            ? const Center(child: Text('No hay líneas sin confirmación.'))
                            : ListView.separated(
                          itemCount: noConfirmLines.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final l = noConfirmLines[i];
                            final upc = (l.upc ?? '').trim();
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.help_outline_rounded, color: Colors.deepOrange),
                              title: Text(
                                'NO CONFIRM  |  ID: ${l.id ?? '-'}  |  Line: ${l.line ?? '-'}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'UPC: ${upc.isEmpty ? '-' : upc}\n'
                                    'Product: ${(l.productName ?? '').trim().isEmpty ? '-' : l.productName}',
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


// ---------------- existing helpers ----------------

List<int> calculateMissingLines(List<Line> allLines) {
  if (allLines.isEmpty) return [];

  final existing = allLines.map((l) => l.line).whereType<int>().toSet();

  final maxExpected = allLines.length * 10;

  final List<int> missing = [];
  for (int v = 10; v <= maxExpected; v += 10) {
    if (!existing.contains(v)) missing.add(v);
  }
  return missing;
}
// Lines without confirmId (confirm flow mismatch)
final lineWithoutConfirmIdProvider = StateProvider<List<Line>>((ref) => []);

List<Line> findLinesWithoutConfirmId(List<Line> allLines) {
  return allLines.where((l) => l.confirmId == null).toList();
}

void updateLinesWithoutConfirmId(WidgetRef ref, List<Line> allLines) {
  ref.read(lineWithoutConfirmIdProvider.notifier).state =
      findLinesWithoutConfirmId(allLines);
}


final confirmedLinesProvider = Provider<int>((ref) {
  final s = ref.watch(mInOutProvider);

  final validStatuses = <String>{
    'correct',
    'manually-correct',
    if (s.rolCompleteLow) 'minor',
    if (s.rolCompleteLow) 'manually-minor',
    if (s.rolCompleteOver) 'over',
    if (s.rolCompleteOver) 'manually-over',
  };

  final lines = s.mInOut?.lines ?? const <Line>[];

  return lines.where((l) =>
  l.verifiedStatus != 'pending' && validStatuses.contains(l.verifiedStatus)
  ).length;
});


