import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/unsorted_storage_on__hand_read_only_screen.dart';

import '../../../../shared/data/memory.dart';
import '../../providers/locator_provider.dart';
import '../../providers/product_provider_common.dart';
import '../movement/create/unsorted_storage_on__hand_screen.dart';
import 'memory_products.dart';

Future<void> showUnsortedStorageSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String productUPC,
  required bool readStockOnly,
  required dynamic notifier,
   // replace with your notifier type if you have one
}) async {
  // English: Prepare providers before opening the sheet
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_GET_LOCATOR_TO_VALUE;
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
      // English: Wrap with a PopScope to control system back inside the sheet
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          // English: Optional cleanup when sheet closes
        },
        child: FractionallySizedBox(
          heightFactor: Memory.FRACTIONNALLY_SIZE_SHEET_HEIGHT,
          child: readStockOnly
              ? UnsortedStorageOnHandReadOnlyScreen(
            productUPC: productUPC,
            index: MemoryProducts.index,
            storage: MemoryProducts.storage,
            width: MemoryProducts.width,
          )
              : UnsortedStorageOnHandScreen(
            productUPC: productUPC,
            index: MemoryProducts.index,
            storage: MemoryProducts.storage,
            width: MemoryProducts.width,
          ),
        ),
      );
    },
  );
}
