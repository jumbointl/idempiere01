import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import '../../../../common/barcode_list_screen.dart';
import '../../../../domain/models/barcode_models.dart';

import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_confirm.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

class MovementBarcodeListScreen extends BarcodeListScreen<MovementAndLines> {
  const MovementBarcodeListScreen({
    super.key,
    required super.argument,
    required MovementAndLines movementAndLines,
  }) : super(initialModel: movementAndLines);

  @override
  MovementAndLines parseArgument(String argument) {
    return MovementAndLines.fromJson(jsonDecode(argument));
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MovementBarcodeListScreenState();
}

class _MovementBarcodeListScreenState
    extends BarcodeListScreenState<MovementBarcodeListScreen, MovementAndLines> {

  MovementAndLines get m => model;

  @override
  bool get hasDocument => m.hasMovement;

  @override
  bool get hasProducts => m.hasMovementLines;

  @override
  bool get hasLocations => m.hasMovementLines;

  @override
  String get documentTitle => Messages.MOVEMENT;

  @override
  String get documentNo => m.documentNo ?? '';

  @override
  String get documentStatusText => m.docStatus?.identifier ?? '';

  @override
  Color get documentCardColor => Colors.cyan[200]!;

  @override
  List<DocumentQrItem> get documentExtraQrs {
    final List<IdempiereMovementConfirm> confirms = m.movementConfirms ?? [];
    final filtered = confirms.where((c) => (c.documentNo ?? '').trim().isNotEmpty).toList();

    return filtered.map((c) {
      return DocumentQrItem(
        title: Messages.MOVEMENT_CONFIRM,
        code: c.documentNo ?? '',
        subtitle: c.docStatus?.identifier ?? '',
      );
    }).toList();
  }

  @override
  List<BarcodeItem> get productBarcodes {
    final List<IdempiereMovementLine> lines = m.movementLines ?? [];
    final filtered = lines.where((l) => (l.uPC ?? '').trim().isNotEmpty).toList();

    return filtered.map((l) {
      String name = l.mProductID?.identifier ?? '';
      if (name.contains('_')) name = name.split('_').last;
      final upc = l.uPC ?? '';

      return BarcodeItem(
        line: l.line,
        code: upc,
        title: upc,
        subtitle: name,
      );
    }).toList();
  }

  @override
  List<LocatorQrItem> get locatorQrs {
    final fromName = m.warehouseFrom?.identifier ?? 'FROM';
    final toName = m.warehouseTo?.identifier ?? 'TO';

    final List<IdempiereMovementLine> lines = m.movementLines ?? [];
    final result = <LocatorQrItem>[];

    for (final line in lines) {
      final locFrom = line.mLocatorID;
      final locTo = line.mLocatorToID;

      final fromValue = (locFrom?.value ?? locFrom?.identifier ?? '').trim();
      if (fromValue.isNotEmpty) {
        result.add(LocatorQrItem(
          locator: fromValue,
          warehouse: fromName,
          backgroundColor: Colors.cyan[200]!,
        ));
      }

      final toValue = (locTo?.value ?? locTo?.identifier ?? '').trim();
      if (toValue.isNotEmpty) {
        result.add(LocatorQrItem(
          locator: toValue,
          warehouse: toName,
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
  }

  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {
    print('setDefaultValues');
  }





}



