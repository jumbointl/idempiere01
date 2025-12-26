import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:monalisa_app_001/features/products/domain/idempiere/sales_order_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../products/common/barcode_list_screen.dart';
import '../../products/domain/models/barcode_models.dart';

class SalesOrderBarcodeListScreen
    extends BarcodeListScreen<SalesOrderAndLines> {
  SalesOrderBarcodeListScreen({
    super.key,
    required super.argument,
    required SalesOrderAndLines salesOrder,
  }) : super(initialModel: salesOrder);

  @override
  SalesOrderAndLines parseArgument(String argument) {
    return SalesOrderAndLines.fromJson(jsonDecode(argument));
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SalesOrderBarcodeListScreenState();
}
class _SalesOrderBarcodeListScreenState
    extends BarcodeListScreenState<
        SalesOrderBarcodeListScreen,
        SalesOrderAndLines> {

  SalesOrderAndLines get d => model;

  // =========================================================
  // Flags del documento
  // =========================================================
  @override
  bool get hasDocument => (d.id != null && d.id! > 0);

  @override
  bool get hasProducts =>
      d.salesOrderLines != null && d.salesOrderLines!.isNotEmpty;

  @override
  bool get hasLocations =>
      d.salesOrderLines != null && d.salesOrderLines!.isNotEmpty;

  // =========================================================
  // Info principal
  // =========================================================
  @override
  String get documentTitle => 'SALES ORDER';

  @override
  String get documentNo => d.documentNo ?? '';

  @override
  String get documentStatusText =>
      d.docStatus?.identifier ?? d.docStatus?.id ?? '';

  @override
  Color get documentCardColor => Colors.orange[200]!;

  // =========================================================
  // QR extra del documento (por ahora ninguno)
  // =========================================================
  @override
  List<DocumentQrItem> get documentExtraQrs => const [];

  // =========================================================
  // Códigos de productos (UPC / SKU)
  // =========================================================
  @override
  List<BarcodeItem> get productBarcodes {
    final lines = d.salesOrderLines ?? [];

    final filtered = lines
        .where((l) => (l.uPC ?? '').trim().isNotEmpty)
        .toList();

    return filtered.map((l) {
      final code = (l.uPC ?? '').trim();
      final subtitle =
      (l.productName ?? l.mProductID?.identifier ?? '').trim();

      return BarcodeItem(
        code: code,
        title: code,
        subtitle: subtitle,
      );
    }).toList();
  }

  // =========================================================
  // Locators (Sales Order normalmente no tiene locators)
  // =========================================================
  @override
  List<LocatorQrItem> get locatorQrs {
    final whIdentifier =
    (d.mWarehouseID?.identifier ?? '').trim();

    if (whIdentifier.isEmpty) return const [];

    return [
      LocatorQrItem(
        locator: whIdentifier,
        warehouse: whIdentifier,
        backgroundColor: Colors.orange[200]!,
      ),
    ];
  }
  // =========================================================
  // Hooks heredados (no usados por ahora)
  // =========================================================
  @override
  int get actionScanTypeInt => 0;

  @override
  void executeAfterShown() {}

  @override
  double getWidth() => MediaQuery.of(context).size.width - 30;

  @override
  void initialSetting(BuildContext context, WidgetRef ref) {}

  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {}

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {}

  @override
  void afterAsyncValueAction(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {}

  @override
  Widget asyncValueErrorHandle(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    return Text(result.message ?? Messages.ERROR);
  }

  @override
  Widget asyncValueSuccessPanel(
      WidgetRef ref, {
        required ResponseAsyncValue result,
      }) {
    return const SizedBox.shrink();
  }
}
