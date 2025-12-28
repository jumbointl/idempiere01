import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

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

    for (final line in d.lines) {
      final locFrom = (line.mLocatorId?.identifier ?? '').trim();
      if (locFrom.isNotEmpty) {
        result.add(LocatorQrItem(
          locator: locFrom,
          warehouse: fromWh,
          backgroundColor: Colors.cyan[200]!,
        ));
      }

      final locTo = (line.mLocatorToId?.identifier ?? '').trim();
      if (locTo.isNotEmpty) {
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
  // TODO: implement actionScanTypeInt
  int get actionScanTypeInt => throw UnimplementedError();

  @override
  void afterAsyncValueAction(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement afterAsyncValueAction
  }

  @override
  Widget asyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueErrorHandle
    throw UnimplementedError();
  }

  @override
  Widget asyncValueSuccessPanel(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueSuccessPanel
    throw UnimplementedError();
  }

  @override
  void executeAfterShown() {
    // TODO: implement executeAfterShown
  }


  @override
  double getWidth() {
    // TODO: implement getWidth
    throw UnimplementedError();
  }

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData, required int actionScan}) {
    // TODO: implement handleInputString
    throw UnimplementedError();
  }

  @override
  void initialSetting(BuildContext context, WidgetRef ref) {
    // TODO: implement initialSetting
  }

  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) {
    // TODO: implement setDefaultValues
    throw UnimplementedError();
  }

}
