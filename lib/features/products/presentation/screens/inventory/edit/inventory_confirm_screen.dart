import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/common_consumer_state.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_inventory.dart';
import '../../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../../domain/idempiere/inventory_and_lines.dart';
import '../../../providers/product_provider_common.dart';
import '../provider/new_inventory_provider.dart';
import '../../store_on_hand/memory_products.dart';

class InventoryConfirmScreen extends ConsumerStatefulWidget {
  InventoryAndLines inventoryAndLines;
  final String argument;

  double height = 300.0;
  double width = double.infinity;
  Color bgColor = themeColorPrimary;

  TextStyle inventoryStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: themeFontSizeLarge,
  );

  InventoryConfirmScreen({
    super.key,
    required this.inventoryAndLines,
    required this.argument,
  });

  @override
  ConsumerState<InventoryConfirmScreen> createState() =>
      InventoryConfirmScreenState();
}

class InventoryConfirmScreenState
    extends CommonConsumerState<InventoryConfirmScreen> {
  AsyncValue get actionAsync => ref.watch(confirmInventoryProvider);

  bool started = false;
  bool success = false;
  bool canConfirm = false;

  late IdempiereWarehouse warehouse;
  InventoryAndLines? inventoryAndLines;

  String get getTitleMessage => Messages.COMPLETE_INVENTORY;

  bool get isActionSuccess {
    final doc = widget.inventoryAndLines.docStatus?.id ?? '';
    return doc == Memory.IDEMPIERE_DOC_TYPE_COMPLETED;
  }

  String get getErrorMessagesTitle => Messages.INVENTORY_NOT_COMPLETED;
  String get getSuccessMessagesTitle => Messages.INVENTORY_COMPLETED;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      actionAfterShow(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.argument.isNotEmpty) {
      inventoryAndLines = InventoryAndLines.fromJson(jsonDecode(widget.argument));
    }

    if (!(widget.inventoryAndLines.hasInventoryLines) &&
        inventoryAndLines != null &&
        inventoryAndLines!.hasInventoryLines) {
      widget.inventoryAndLines = inventoryAndLines!;
    }

    warehouse = widget.inventoryAndLines.mWarehouseID ?? IdempiereWarehouse();
    canConfirm = widget.inventoryAndLines.canCompleteInventory;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: success ? Colors.green[200] : Colors.white,
        title: ListTile(
          title: Text(
            getTitleMessage,
            style: const TextStyle(fontSize: themeFontSizeLarge),
          ),
          subtitle: Text(
            'INV : ${widget.inventoryAndLines.id ?? ''}',
            style: const TextStyle(fontSize: themeFontSizeNormal),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popScopeAction(context, ref),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) return;
          popScopeAction(context, ref);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: widget.height,
              width: widget.width,
              padding: const EdgeInsets.all(10),
              child: actionAsync.when(
                data: (data) {
                  if (data == null) {
                    return Container(
                      decoration: BoxDecoration(
                        color: widget.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          getInventoryCard(context, ref),
                        ],
                      ),
                    );
                  }

                  started = true;
                  widget.inventoryAndLines.docStatus = data.docStatus;

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (data.id != null && data.id! > 0) {
                      success = isActionSuccess;

                      ref.read(actionScanProvider.notifier).state =
                          Memory.ACTION_FIND_INVENTORY_BY_ID;

                      final id = widget.inventoryAndLines.id ?? -1;

                      await Future.delayed(
                        Duration(
                          seconds: MemoryProducts.delayOnSwitchPageInSeconds,
                        ),
                      );

                      if (context.mounted) {
                        context.go('${AppRouter.PAGE_INVENTORY_EDIT}/$id/1');
                      }
                    }
                  });

                  return getResultCard(context, ref, data);
                },
                error: (error, stackTrace) => Text('Error: $error'),
                loading: () => const LinearProgressIndicator(minHeight: 36),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getInventoryCard(BuildContext context, WidgetRef ref) {
    final IdempiereInventory inventory = widget.inventoryAndLines;
    final id = inventory.documentNo ?? 'XXX';
    final date = inventory.movementDate?.toString() ?? '';
    final warehouseName = inventory.mWarehouseID?.identifier ?? '';
    final subtitleLeft =
        '${Messages.DOC_STATUS}: ${inventory.docStatus?.identifier ?? ''}';

    return Container(
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: widget.inventoryStyle, overflow: TextOverflow.ellipsis),
              Text(date, style: widget.inventoryStyle, overflow: TextOverflow.ellipsis),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${Messages.WAREHOUSE}: $warehouseName',
                  style: widget.inventoryStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitleLeft,
                style: widget.inventoryStyle,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                canConfirm ? Messages.CONFIRM : '',
                textAlign: TextAlign.end,
                style: widget.inventoryStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget getResultCard(
      BuildContext context,
      WidgetRef ref,
      InventoryAndLines data,
      ) {
    String title = getErrorMessagesTitle;
    Color bgColor = Colors.yellow[200]!;
    String subtitle = 'INV: ${data.documentNo ?? ''}';

    if (isActionSuccess) {
      title = getSuccessMessagesTitle;
      bgColor = Colors.green[200]!;
    } else {
      subtitle = '$subtitle : ${data.name ?? ''}';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        spacing: 10,
        children: [
          Text(title, style: const TextStyle(fontSize: themeFontSizeLarge)),
          Text(subtitle, style: const TextStyle(fontSize: themeFontSizeNormal)),
        ],
      ),
    );
  }

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    throw UnimplementedError();
  }

  Future<void> actionAfterShow(WidgetRef ref) async {
    if (widget.inventoryAndLines.canCompleteInventory == false) {
      showErrorMessage(
        context,
        ref,
        Messages.ERROR_CANNOT_COMPLETE_INVENTORY,
        durationSeconds: 5,
      );
      return;
    }

    if (!started) {
      started = true;
      ref.read(inventoryIdForConfirmProvider.notifier).state =
          widget.inventoryAndLines.id;
    }
  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    final inventoryId = widget.inventoryAndLines.id ?? -1;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_MOVEMENT_BY_ID;

    context.go('${AppRouter.PAGE_INVENTORY_EDIT}/$inventoryId/1');
  }
}