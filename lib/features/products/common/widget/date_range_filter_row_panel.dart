import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/router/app_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../domain/models/m_in_out_list_type.dart';
import '../../presentation/providers/common_provider.dart';
import '../time_utils.dart';

class DateRangeFilterRowPanel extends ConsumerWidget {
  final bool orientationUpper;
  List<String> values = ['ALL', 'IN', 'OUT', 'SWAP'];
  StateProvider<DateTimeRange> selectedDatesProvider;


  DateRangeFilterRowPanel({
    super.key,
    required this.onOk,
    required this.onScanButtonPressed,
    this.orientationUpper = true,
    required this.values,
    required this.selectedDatesProvider,
  });

  final void Function(DateTimeRange dateRange, String inOut) onOk;
  final VoidCallback? onScanButtonPressed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDates = ref.watch(selectedDatesProvider);
    final inOutValue = ref.watch(inOutFilterProvider); // 'ALL', 'IN', 'OUT', 'SWAP'
    final dateTexts = [DateFormat('dd/MM/yyyy').format(selectedDates.start),
                DateFormat('dd/MM/yyyy').format(selectedDates.end)];

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
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final current = ref.read(selectedDatesProvider);
            final initialStart = current.start;
            final initialEnd = current.end.isAfter(today) ? today : current.end;

            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: today,
              initialDateRange: DateTimeRange(
                start: initialStart.isAfter(today) ? today : initialStart,
                end: initialEnd,
              ),
              builder: (context, child) {
                final base = Theme.of(context);

                return Theme(
                  data: base.copyWith(
                    colorScheme: base.colorScheme.copyWith(
                      primary: Colors.purple,        // color principal (botón Save, header, selección)
                      onPrimary: Colors.white,       // texto sobre el primary
                      secondary: Colors.purple,
                      onSecondary: Colors.white,
                    ),

                    // Ajustes específicos del DateRangePicker
                    datePickerTheme: DatePickerThemeData(
                      // Texto de los días seleccionados (números dentro del calendario)
                      dayStyle: const TextStyle(fontSize: 16),
                      // Texto dentro del “círculo” seleccionado
                      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return Colors.white;
                        return null;
                      }),
                      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return Colors.purple;
                        return null;
                      }),

                      // Texto del rango (las fechas que se muestran arriba: start/end)
                      rangeSelectionBackgroundColor: Colors.purple.shade50,
                      rangeSelectionOverlayColor: WidgetStatePropertyAll(Colors.purple.shade50),
                      rangePickerHeaderHeadlineStyle: TextStyle(fontSize: themeFontSizeLarge, color: Colors.purple,),


                      // Estilo de los textos de entrada (en Material 3 a veces aparece como campos)
                      headerHeadlineStyle: const TextStyle(fontSize: themeFontSizeLarge, color: Colors.purple,fontWeight: FontWeight.bold),
                      headerHelpStyle: const TextStyle(fontSize: themeFontSizeLarge, color: Colors.purple,fontWeight: FontWeight.bold),

                      // Botones (Save/Cancel)
                      cancelButtonStyle: ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(Colors.purple),
                        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 16)),
                      ),
                      confirmButtonStyle: ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(Colors.purple), // texto "Save"
                        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 16)),
                      ),
                    ),

                    textButtonTheme: TextButtonThemeData(
                      style: ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(Colors.purple), // Save/Cancel
                        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              //final start = DateTime(picked.start.year, picked.start.month, picked.start.day);
              //final end = DateTime(picked.end.year, picked.end.month, picked.end.day);

              ref.read(selectedDatesProvider.notifier).state = picked;

              final inOut = ref.read(inOutFilterProvider);
              onOk(picked, inOut);
            }
          },
          child: Text(dateTexts[0]==dateTexts[1] ? dateTexts[0] :
            '${dateTexts[0].substring(0,5)}-${dateTexts[1].substring(0,5)}',
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
            ref.read(selectedDatesProvider.notifier).state = DateTimeRange(start: today, end: today);
            final dates = ref.read(selectedDatesProvider);
            final inOut = ref.read(inOutFilterProvider);
            onOk(dates, inOut);
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
              final dates = ref.read(selectedDatesProvider);
              final inOut = ref.read(inOutFilterProvider);
              onOk(dates, inOut);
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
            segments: values.map((value) {
              return ButtonSegment<String>(
                value: value,
                icon: Icon(_iconFor(value), size: 20),
                label: Text(
                  value,
                  style: TextStyle(fontSize: themeFontSizeSmall),
                ),
              );
            }).toList(),
            selected: <String>{inOutValue},
            onSelectionChanged: (newSelection) {
              final value = newSelection.first;
              ref.read(inOutFilterProvider.notifier).state = value;

              final dates = ref.read(selectedDatesProvider);
              onOk(dates, value);
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
  IconData _iconFor(String value) {
    switch (value) {
      case 'IN':
      case MInOutListTypeX.RECEIVE:
        return Icons.arrow_downward;
      case 'OUT':
      case MInOutListTypeX.SHIPPING:
        return Icons.arrow_upward;
      case 'SWAP':
        return Icons.swap_horiz;
      case 'ALL':
        return Icons.all_inclusive;
      default:
        return Icons.question_mark;
    }
  }
}