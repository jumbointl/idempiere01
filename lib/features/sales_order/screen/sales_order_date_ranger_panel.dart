

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/common/widget/date_range_filter_row_panel.dart';

class SalesOrderDateRangerPanel extends DateRangeFilterRowPanel{
  SalesOrderDateRangerPanel({super.key, required super.onOk, required 
  super.onScanButtonPressed, 
    required super.values, 
    required super.selectedDatesProvider,
    required super.selectionFilterProvider,
    super.onReloadButtonPressed,
  });
  @override
  void refreshButtonPressed(BuildContext context, WidgetRef ref) {
    final dates = ref.read(selectedDatesProvider);
    final selection = ref.read(selectionFilterProvider);
    onOk(dates, selection);
  }

  @override
  void datesPicked(DateTimeRange<DateTime> picked, WidgetRef ref) {
    ref.read(selectedDatesProvider.notifier).state = picked;
    final selection = ref.read(selectionFilterProvider);
    onOk(picked, selection);
  }

  @override
  void toDayPressed(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    ref.read(selectedDatesProvider.notifier).state = DateTimeRange(start: today, end: today);
    final dates = ref.read(selectedDatesProvider);
    final selection = ref.read(selectionFilterProvider);
    onOk(dates, selection);
  }
  @override
  void onSelectionChanged(Set<String> newSelection, WidgetRef ref) {
    final value = newSelection.first;
    ref.read(selectionFilterProvider.notifier)
        .state = value;
  }
}

