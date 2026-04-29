import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:monalisapy_core/models/idempiere/idempiere_locator.dart';
import 'package:monalisapy_features/printer/printable/zpl_printable.dart';

import '../../printer/zpl/old/zpl_label_printer_100x150.dart';

/// Adapts a list of locators to the package's [ZplPrintable] contract —
/// locator labels are ZPL only (no PDF flow).
///
/// The list is held as `List<dynamic>` because two parallel
/// `IdempiereLocator` definitions still coexist in the workspace (one in
/// `monalisa_app_001`, one in `monalisapy_features`). The downstream ZPL
/// sender narrows back to the package type.
class LocatorListPrintable implements ZplPrintable {
  final List<dynamic> _locators;

  LocatorListPrintable(this._locators);

  List<IdempiereLocator> get locators => _locators.cast<IdempiereLocator>();

  @override
  String get documentNo {
    if (_locators.isEmpty) return '';
    final dynamic l = _locators[0];
    return (l.value ?? l.identifier ?? '') as String;
  }

  @override
  IconData get dataPanelIcon => Symbols.fork_left;

  @override
  String get dataPanelTitle {
    if (_locators.length == 1) {
      final dynamic l = _locators[0];
      return 'Locator to print : ${l.value ?? l.identifier ?? ''}';
    }
    return 'Total Locator to print : ${_locators.length}';
  }

  @override
  String get dataPanelSubtitle {
    if (_locators.isEmpty) return '';
    final dynamic l = _locators[0];
    final wh = l.mWarehouseID?.identifier ?? '';
    return _locators.length == 1
        ? 'Warehouse: $wh'
        : 'Warehouse: $wh may others';
  }

  @override
  Future<void> printZpl(WidgetRef ref) {
    return printListLocatorZplDirectOrConfigure(ref, locators);
  }
}
