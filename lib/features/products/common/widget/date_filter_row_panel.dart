import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/router/app_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../presentation/providers/common_provider.dart';
import '../time_utils.dart';

class DateFilterRowPanel extends ConsumerWidget {
  final bool orientationUpper;

  const DateFilterRowPanel({
    super.key,
    required this.onOk,
    required this.onScanButtonPressed,
    this.orientationUpper = true,
  });

  /// Agora o callback recebe `String inOut` em vez de `bool?`
  final void Function(DateTime date, String inOut) onOk;
  final VoidCallback? onScanButtonPressed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final inOutValue = ref.watch(inOutFilterProvider); // 'ALL', 'IN', 'OUT', 'SWAP'
    final dateText = DateFormat('dd/MM/yyyy').format(selectedDate);

    // --------- PRIMEIRA LINHA (data / hoje / scan) ----------
    final firstRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              ref.read(selectedDateProvider.notifier).state = picked;
              final date = ref.read(selectedDateProvider);
              final inOut = ref.read(inOutFilterProvider);
              onOk(date, inOut);
            }
          },
          child: Text(
            dateText,
            style: const TextStyle(color: Colors.purple),
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            ref.read(selectedDateProvider.notifier).state = today;
            final date = ref.read(selectedDateProvider);
            final inOut = ref.read(inOutFilterProvider);
            onOk(date, inOut);
          },
          child: Text(
            Messages.TODAY,
            style: const TextStyle(color: Colors.purple),
          ),
        ),
        OutlinedButton(
          onPressed: () {
            if (onScanButtonPressed != null) {
              onScanButtonPressed!();
            }

          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: themeColorPrimary,
            visualDensity: VisualDensity.compact,
          ),
          child: const Text(
            'SCAN',
            style: TextStyle(color: Colors.white),
          ),
        ),

        Container(
          height: 32, // Altura similar a OutlinedButton con VisualDensity.compact
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh, color: Colors.purple),
            onPressed: () {
              final date = ref.read(selectedDateProvider);
              final inOut = ref.read(inOutFilterProvider);
              onOk(date, inOut);
            },
          ),
        ),
      ],
    );

    // --------- SEGUNDA LINHA (filtro IN/OUT/...) ----------
    final secondRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SegmentedButton<String>(
            segments: <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'ALL',
                icon: const Icon(Icons.all_inclusive, size: 20),
                label: Text(
                  'ALL',
                  style: TextStyle(fontSize: themeFontSizeSmall),
                ),
              ),
              ButtonSegment<String>(
                value: 'IN',
                icon: const Icon(Icons.arrow_downward, size: 20),
                label: Text(
                  'IN',
                  style: TextStyle(fontSize: themeFontSizeSmall),
                ),
              ),
              ButtonSegment<String>(
                value: 'OUT',
                icon: const Icon(Icons.arrow_upward, size: 20),
                label: Text(
                  'OUT',
                  style: TextStyle(fontSize: themeFontSizeSmall),
                ),
              ),
              ButtonSegment<String>(
                value: 'SWAP',
                icon: const Icon(Icons.swap_horiz, size: 20),
                label: Text(
                  'SWAP',
                  style: TextStyle(fontSize: themeFontSizeSmall),
                ),
              ),
            ],
            selected: <String>{inOutValue},
            onSelectionChanged: (newSelection) {
              final value = newSelection.first; // 'ALL' | 'IN' | 'OUT' | 'SWAP'
              ref.read(inOutFilterProvider.notifier).state = value;

              final date = ref.read(selectedDateProvider);
              onOk(date, value);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ),

      ],
    );

    return Column(
      children: orientationUpper ? [secondRow, firstRow] : [firstRow, secondRow],
    );
  }
}