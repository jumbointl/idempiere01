import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_inventory.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_inventory_line.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/inventory_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_inventory.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/create/no_data_created_put_away_movement_card.dart';
import 'package:monalisapy_core/monalisapy_core.dart' show SafeBottomBar;
import 'package:monalisa_app_001/features/products/presentation/screens/inventory/provider/new_inventory_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';

import '../../../providers/store_on_hand_for_put_away_movement.dart';

class InventoryCreateScreen extends ConsumerStatefulWidget {
  final PutAwayInventory inventoryAndLines;

  const InventoryCreateScreen({
    super.key,
    required this.inventoryAndLines,
  });

  @override
  ConsumerState<InventoryCreateScreen> createState() =>
      _InventoryCreateScreenState();
}

class _InventoryCreateScreenState extends ConsumerState<InventoryCreateScreen> {
  late AsyncValue inventoryAsync;
  bool startCreate = false;
  String? productUPC;

  @override
  void initState() {
    super.initState();
    productUPC = widget.inventoryAndLines.inventoryLineToCreate?.uPC ?? '-1';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (startCreate) return;

      startCreate = true;

      final act = ref.read(createInventoryAndLinesActionProvider);
      await act.setAndFire(widget.inventoryAndLines);
    });
  }

  @override
  Widget build(BuildContext context) {
    inventoryAsync = ref.watch(newInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          'Inventory : ${Messages.CREATE}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      bottomNavigationBar: SafeBottomBar(
        child: BottomAppBar(
          height: Memory.BOTTOM_BAR_HEIGHT,
          color: themeColorPrimary,
          child: Center(
            child: Text(
              Messages.PLEASE_WAIT,
              style: TextStyle(
                fontSize: themeFontSizeLarge,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          width: MediaQuery.of(context).size.width,
          child: _buildBody(context, ref),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return inventoryAsync.when(
      data: (result) {
        if (result == null || result.id == null || result.id! <= 0) {
          if (startCreate) {
            return NoDataPutAwayCreatedCard(
              width: MediaQuery.of(context).size.width,
            );
          }
          return _dataToCreateCard(context);
        }

        final InventoryAndLines data = result;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          ref.read(isDialogShowedProvider.notifier).state = false;
          ref.read(isScanningProvider.notifier).state = false;

          await Future.delayed(
            Duration(seconds: MemoryProducts.delayOnSwitchPageInSeconds),
          );

          if (!mounted) return;

          ref.read(actionScanProvider.notifier).state =
              Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
          ref.invalidate(productStoreOnHandCacheProvider);

          context.go(
            '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_INVENTORY_LINE}/-1',
            extra: data,
          );
        });

        if (data.nothingCreated) {
          return NoDataPutAwayCreatedCard(
            width: MediaQuery.of(context).size.width,
          );
        }

        if (data.onlyInventoryCreated) {
          final inventory = data;
          return _resultCardOnlyInventory(context, inventory);
        }

        return _resultCardInventoryAndLine(
          context,
          data,
          data.inventoryLines!.first,
        );
      },
      error: (error, _) => Text('Error: $error'),
      loading: () => const LinearProgressIndicator(minHeight: 36),
    );
  }

  Widget _dataToCreateCard(BuildContext context) {
    final qty = widget.inventoryAndLines.inventoryLineToCreate?.qtyCount ?? 0;
    final locator =
        widget.inventoryAndLines.inventoryLineToCreate?.mLocatorID?.value ??
            widget.inventoryAndLines.inventoryLineToCreate?.mLocatorID?.identifier ??
            '--';
    final product =
        widget.inventoryAndLines.inventoryLineToCreate?.mProductID?.identifier ??
            '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Messages.PLEASE_WAIT,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${Messages.PRODUCT}: $product'),
            Text('${Messages.LOCATOR}: $locator'),
            Text('${Messages.QUANTITY}: ${Memory.numberFormatter0Digit.format(qty)}'),
          ],
        ),
      ),
    );
  }

  Widget _resultCardOnlyInventory(BuildContext context, IdempiereInventory inventory) {
    final id = inventory.id ?? -1;

    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        children: [
          const Icon(Icons.error_rounded, size: 50, color: Colors.orange),
          Text(
            '${Messages.ID} : $id',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: themeFontSizeTitle,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          _inventoryCard(inventory),
          Text(
            'Inventory line not created',
            style: TextStyle(
              fontSize: themeFontSizeTitle,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCardInventoryAndLine(
      BuildContext context,
      IdempiereInventory inventory,
      IdempiereInventoryLine line,
      ) {
    final id = inventory.id ?? -1;

    return SingleChildScrollView(
      child: Column(
        spacing: 10,
        children: [
          const Icon(Icons.check_circle, size: 100, color: Colors.green),
          Text(
            '${Messages.ID} : $id',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: themeFontSizeTitle,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          _inventoryCard(inventory),
          _inventoryLineCard(line),
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                ref.read(actionScanProvider.notifier).state =
                    Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
                ref.read(isDialogShowedProvider.notifier).state = false;

                if (context.mounted) {
                  context.go(
                    '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productUPC',
                  );
                }
              },
              child: Text(
                Messages.OK,
                style: TextStyle(
                  fontSize: themeFontSizeLarge,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventoryCard(IdempiereInventory inventory) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.cyan[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Messages.ID} ${inventory.id ?? ''}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'Document No: ${inventory.documentNo ?? '--'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '${Messages.DATE}: ${inventory.movementDate ?? '--'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'Warehouse: ${inventory.mWarehouseID?.identifier ?? '--'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _inventoryLineCard(IdempiereInventoryLine line) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Messages.ID} ${line.id ?? ''}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '${Messages.PRODUCT_NAME}: ${line.productName ?? line.mProductID?.identifier ?? '--'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '${Messages.LOCATOR}: ${line.mLocatorID?.value ?? line.mLocatorID?.identifier ?? '--'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'Qty Count: ${Memory.numberFormatter0Digit.format(line.qtyCount ?? 0)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}