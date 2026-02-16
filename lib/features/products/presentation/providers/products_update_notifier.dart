

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_search_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_update_upc_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common/app_action_notifier.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../common/messages_dialog.dart';



class ProductsUpdateNotifier extends AppActionNotifier<void> {
  ProductsUpdateNotifier(Ref ref) : super(ref, null);

  Future<void> _updateProductUPC({required BuildContext context,
    required WidgetRef ref,required String newUPC}) async {
    debugPrint('_updateProductUPC start');
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
      showErrorMessage(
        context,
        ref,
        '${Messages.DATA_NOT_VALID}\nID: $id , UPC: $newUPC',
        durationSeconds: 5,
      );

      return;
    }
    debugPrint('_updateProductUPC 2');
    // English: Prepare payload for update flow.
    final updateData = <String>[id, newUPC];
    ref.read(dataToUpdateUPCProvider.notifier).state = updateData;
    debugPrint('_updateProductUPC ${ref.read(fireUpdateUPCProvider)}');
    ref.read(fireUpdateUPCProvider.notifier).state++;
    debugPrint('_updateProductUPC ${ref.read(fireUpdateUPCProvider)}');
    debugPrint('_updateProductUPC end');
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
    debugPrint('handleInputString $inputData $actionScan');

    switch (actionScan) {
      case Memory.ACTION_FIND_BY_UPC_SKU:
        _addBarcodeByUPCOrSKUForSearch(value);
        break;

      case Memory.ACTION_FILL_NEW_UPC_TO_UPDATE:
        final product = ref.read(productForUpcUpdateProvider);
        ref.read(newUPCToUpdateProvider.notifier).state = value ;
        String message = 'From\n${product.uPC ?? 'NO OLD UPC'} \n=>\n$value' ;
        String title = '${Messages.NEW_UPC}=>\n$value' ;
        final bool ok = await showConfirmDialog(ref.context, title: title, message: message);
        if(!ok){
          return;
        }
        if(!ref.context.mounted) return ;
        await _updateProductUPC(ref: ref ,context:ref.context,newUPC: value);
        break;

      default:
      // English: No-op for unsupported actions.
        break;
    }

  }
}

