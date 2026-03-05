import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/unsorted_storage_on__hand_read_only_screen.dart';

import '../../../../shared/data/memory.dart';
import '../../providers/locator_provider.dart';
import '../../providers/product_provider_common.dart';
import '../inventory/create/unsorted_storage_on_hand_screen_for_inventory.dart';
import '../movement/create/unsorted_storage_on_hand_screen_for_movement.dart';
import 'memory_products.dart';

Future<void> showUnsortedStorageSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String productUPC,
  required bool readStockOnly,
  required bool isInventory,
}) async {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_GET_LOCATOR_TO_VALUE;
    ref.invalidate(selectedLocatorToProvider);
  });

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {},
        child: FractionallySizedBox(
          heightFactor: Memory.FRACTIONNALLY_SIZE_SHEET_HEIGHT,
          child: readStockOnly
              ? UnsortedStorageOnHandReadOnlyScreen(
            productUPC: productUPC,
            index: MemoryProducts.index,
            storage: MemoryProducts.storage,
            width: MemoryProducts.width,
          )
              : isInventory
              ? UnsortedStorageOnHandScreenForInventory(
            index: MemoryProducts.index,
            storage: MemoryProducts.storage,
            width: MemoryProducts.width,
          )
              : UnsortedStorageOnHandScreenForMovement(
            index: MemoryProducts.index,
            storage: MemoryProducts.storage,
            width: MemoryProducts.width,
          ),
        ),
      );
    },
  );
}
