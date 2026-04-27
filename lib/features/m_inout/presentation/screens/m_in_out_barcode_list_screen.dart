import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common/code_and_fire_action_notifier.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../../products/common/barcode_list_screen.dart';
import '../../../products/domain/models/barcode_models.dart';

class MInOutBarcodeListScreen extends BarcodeListScreen<MInOut> {
  const MInOutBarcodeListScreen({
    super.key,
    required super.argument,
    required MInOut minOut,
  }) : super(initialModel: minOut);

  @override
  MInOut parseArgument(String argument) {
    return MInOut.fromJson(jsonDecode(argument));
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MInOutBarcodeListScreenState();
}

class _MInOutBarcodeListScreenState
    extends BarcodeListScreenState<MInOutBarcodeListScreen, MInOut> {

  MInOut get d => model;

  @override
  bool get hasDocument => (d.id != null && d.id! > 0);

  @override
  bool get hasProducts => d.lines.isNotEmpty;

  @override
  bool get hasLocations => d.lines.isNotEmpty;

  @override
  String get documentTitle => 'M IN OUT';

  @override
  String get documentNo => d.documentNo ?? '';

  @override
  String get documentStatusText => d.docStatus.identifier ?? d.docStatus.id ?? '';

  @override
  Color get documentCardColor => Colors.cyan[200]!;

  @override
  List<DocumentQrItem> get documentExtraQrs {
    // Si en el futuro tienes “confirms” para MInOut, aquí los agregas.
    return const [];
  }

  @override
  List<BarcodeItem> get productBarcodes {
    final filtered = d.lines.where((l) => (l.upc ?? '').trim().isNotEmpty).toList();

    return filtered.map((l) {
      final upc = (l.upc ?? '').trim();
      final title = upc;
      final subtitle = (l.productName ?? l.mProductId?.identifier ?? '').trim();

      return BarcodeItem(
        line: l.line?.toDouble(),
        code: upc,
        title: title,
        subtitle: subtitle,
      );
    }).toList();
  }

  @override
  List<LocatorQrItem> get locatorQrs {
    final fromWh = (d.mWarehouseId.identifier ?? 'FROM').trim();
    final toWh = (d.mWarehouseToId.identifier ?? 'TO').trim();

    final result = <LocatorQrItem>[];
    final seen = <String>{};

    for (final line in d.lines) {
      final locFrom = (line.mLocatorId?.identifier ?? '').trim();
      if (locFrom.isNotEmpty && seen.add('FROM|$locFrom|$fromWh')) {
        result.add(LocatorQrItem(
          locator: locFrom,
          warehouse: fromWh,
          backgroundColor: Colors.cyan[200]!,
        ));
      }

      final locTo = (line.mLocatorToId?.identifier ?? '').trim();
      if (locTo.isNotEmpty && seen.add('TO|$locTo|$toWh')) {
        result.add(LocatorQrItem(
          locator: locTo,
          warehouse: toWh,
          backgroundColor: Colors.white,
        ));
      }
    }

    return result;
  }

  @override
  int get actionScanTypeInt => 0;

  @override
  void afterAsyncValueAction(WidgetRef ref, {required ResponseAsyncValue result}) {}

  @override
  Widget asyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {
    return Text(result.message ?? Messages.ERROR);
  }

  @override
  Widget asyncValueSuccessPanel(WidgetRef ref, {required ResponseAsyncValue result}) {
    return const SizedBox.shrink();
  }

  @override
  void executeAfterShown() {}

  @override
  double getWidth() => MediaQuery.of(context).size.width - 30;

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData, required int actionScan}) async {}

  @override
  void initialSettingAtBuild(BuildContext context, WidgetRef ref) {}

  @override
  Future<void> setDefaultValuesOnInitState(BuildContext context, WidgetRef ref) async {}

  @override
  CodeAndFireActionNotifier get mainNotifier => throw UnimplementedError();

}
