// --------- Helpers comunes: business days (si querés que sea común) ----------
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

DateTime subtractBusinessDays(DateTime from, int days) {
  var date = DateTime(from.year, from.month, from.day);
  var remaining = days;

  while (remaining > 0) {
    date = date.subtract(const Duration(days: 1));
    if (date.weekday != DateTime.saturday &&
        date.weekday != DateTime.sunday) {
      remaining--;
    }
  }
  return date;
}

DateTime initialBusinessDate() {
  final now = DateTime.now();
  return subtractBusinessDays(now, 3);
}

/// Riverpod provider to hold the selected date
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return initialBusinessDate();
});

final selectedDatesProvider = StateProvider<DateTimeRange>((ref) {
  return DateTimeRange(start: initialBusinessDate(), end: DateTime.now());
});
final selectedMInOutDatesProvider = StateProvider<DateTimeRange>((ref) {
  return DateTimeRange(start: initialBusinessDate(), end: DateTime.now());
});

