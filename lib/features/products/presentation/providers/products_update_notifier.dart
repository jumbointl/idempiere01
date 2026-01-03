

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_search_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_update_upc_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common/app_action_notifier.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';



class ProductsUpdateNotifier extends AppActionNotifier<void> {
  ProductsUpdateNotifier(Ref ref) : super(ref, null);

  Future<void> _updateProductUPC(BuildContext context) async {
    // English: Read the current selected product + new UPC from providers.
    final product = ref.read(productForUpcUpdateProvider);
    final String id = product.id?.toString() ?? '';
    final String newUPC = ref.read(newUPCToUpdateProvider);

    final int? idInt = int.tryParse(id);
    final int? upcInt = int.tryParse(newUPC);

    final bool invalid =
        id.isEmpty || idInt == null || idInt == 0 || newUPC.isEmpty || upcInt == null || upcInt == 0;

    if (invalid) {
      // English: Show validation dialog and exit.
      await AwesomeDialog(
        context: context,
        animType: AnimType.scale,
        dialogType: DialogType.error,
        body: Center(
          child: Text(
            Messages.DATA_NOT_VALID,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        title: 'ID: $id ,UPC: $newUPC',
        desc: 'ID: $id ,UPC: $newUPC',
        autoHide: const Duration(seconds: 5),
        btnOkOnPress: () {},
        btnOkColor: Colors.amber,
        btnCancelText: Messages.CANCEL,
        btnOkText: Messages.OK,
      ).show();
      return;
    }

    // English: Prepare payload for update flow.
    final updateData = <String>[id, newUPC];
    ref.read(dataToUpdateUPCProvider.notifier).state = updateData;
  }

  void _addBarcodeByUPCOrSKUForSearch(String data) {
    // English: Normalize UPC if needed (EAN13 padding).
    final value = normalizeUPC(data);

    setScanning(true);

    // English: Reset update state.
    ref.read(dataToUpdateUPCProvider.notifier).state = <String>[];
    ref.read(newUPCToUpdateProvider.notifier).state = '';

    // English: Store last search and trigger product search.
    setLastSearch(value);
    ref.read(scannedCodeForSearchByUPCOrSKUProvider.notifier).state = value;

    increaseScanCounter();
    ref.read(fireSearchByUPCOrSKUProvider.notifier).state++;
  }

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    // English: Always normalize input once.
    final value = normalizeUPC(inputData);

    switch (actionScan) {
      case Memory.ACTION_FIND_BY_UPC_SKU:
        _addBarcodeByUPCOrSKUForSearch(value);
        break;

      case Memory.ACTION_UPDATE_UPC:
        await _updateProductUPC(ref.context);
        break;

      default:
      // English: No-op for unsupported actions.
        break;
    }

    setScanning(false);
  }
}

