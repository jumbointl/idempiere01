import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';

class DateRangeFilterRowPanel extends ConsumerWidget {
  static const String ALL ='ALL';
  static const String IN ='IN';
  static const String OUT ='OUT';
  static const String SWAP ='SWAP';
  static const String TO_DO ='TO DO';
  static const String DONE ='DONE';
  static const String CANCELLED ='CANCELLED';
  static const String RUNNING ='RUNNING';
  static const String IN_PROGRESS ='IN PROGRESS';
  static const String COMPLETED ='COMPLETED';
  static const String RECEIVE ='RECEIVE';
  static const String SHIPPING ='SHIPPING';
  static const String CANCEL ='CANCEL';


  final bool orientationUpper;
  final List<String> values ;
  StateProvider<DateTimeRange> selectedDatesProvider;
  StateProvider<String>selectionFilterProvider;


  DateRangeFilterRowPanel({
    super.key,
    required this.onOk,
    required this.onScanButtonPressed,
    required this.onReloadButtonPressed,
    this.orientationUpper = true,
    required this.values,
    required this.selectedDatesProvider,
    required this.selectionFilterProvider,
  });

  final void Function(DateTimeRange dateRange, String inOut) onOk;
  final VoidCallback? onScanButtonPressed;
  final VoidCallback? onReloadButtonPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDates = ref.watch(selectedDatesProvider);
    final selectedValue = ref.watch(selectionFilterProvider);
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
              datesPicked(picked, ref);
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
            toDayPressed(context, ref);
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
              refreshButtonPressed(context, ref);

            },
          ),
        ),
      ],
    );

    // --------- SEGUNDA LINHA (filtro IN/OUT/...) ----------
    if(values.isNotEmpty) {
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
              selected: <String>{selectedValue},
              onSelectionChanged: (newSelection) {

                onSelectionChanged(newSelection, ref);

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
    } else {
      return firstRow ;
    }


  }
  IconData _iconFor(String value) {
    switch (value) {
      case DateRangeFilterRowPanel.IN:
      case DateRangeFilterRowPanel.RECEIVE:
        return Icons.arrow_downward;
      case DateRangeFilterRowPanel.OUT:
      case DateRangeFilterRowPanel.SHIPPING:
        return Icons.arrow_upward;
      case DateRangeFilterRowPanel.SWAP:
        return Icons.swap_horiz;
      case DateRangeFilterRowPanel.ALL:
        return Icons.all_inclusive;
      case DateRangeFilterRowPanel.TO_DO:
        return Symbols.pending_rounded;
      case DateRangeFilterRowPanel.DONE:
        return Symbols.done_all_rounded;
      case DateRangeFilterRowPanel.CANCELLED:
        return Icons.cancel;
      case DateRangeFilterRowPanel.RUNNING:
      case DateRangeFilterRowPanel.IN_PROGRESS:
        return Symbols.arrow_upload_progress_rounded;

      default:
        return Icons.question_mark;
    }
  }

  void refreshButtonPressed(BuildContext context, WidgetRef ref) {
    if(onReloadButtonPressed!=null) {
      onReloadButtonPressed!();
    } else {
      final dates = ref.read(selectedDatesProvider);
      final inOut = ref.read(selectionFilterProvider);
      onOk(dates, inOut);
    }
  }

  void datesPicked(DateTimeRange<DateTime> picked, WidgetRef ref) {
    ref.read(selectedDatesProvider.notifier).state = picked;
    final inOut = ref.read(selectionFilterProvider);
    onOk(picked, inOut);
  }

  void toDayPressed(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    ref.read(selectedDatesProvider.notifier).state = DateTimeRange(start: today, end: today);
    final dates = ref.read(selectedDatesProvider);
    final inOut = ref.read(selectionFilterProvider);
    onOk(dates, inOut);
  }

  void onSelectionChanged(Set<String> newSelection, WidgetRef ref) {
    final value = newSelection.first;
    ref.read(selectionFilterProvider.notifier)
        .state = value;
    final dates = ref.read(selectedDatesProvider);
    onOk(dates, value);
  }
}