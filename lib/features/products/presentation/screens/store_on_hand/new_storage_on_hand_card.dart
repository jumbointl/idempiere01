

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/unsorte_storage_on_hand_provider.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../common/messages_dialog.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../providers/actions/find_locator_to_action_provider.dart';
import '../../providers/locator_provider.dart';
import '../../providers/product_provider_common.dart';



class NewStorageOnHandCard extends ConsumerStatefulWidget {
  final IdempiereStorageOnHande storage;

  final int index;
  final int listLength;
  final bool readStockOnly;
  final double width;
  /// English: Used to restrict warehouses in some flows
  final dynamic allowedWarehouseFrom;

  const NewStorageOnHandCard(
      this.storage,
      this.index,
      this.listLength, {
        required this.readStockOnly,
        super.key,
        required this.width,
        this.allowedWarehouseFrom,
      });

  @override
  ConsumerState<NewStorageOnHandCard> createState() =>
      _StorageOnHandCardForLineState();
}

class _StorageOnHandCardForLineState
    extends ConsumerState<NewStorageOnHandCard> {
  bool _opening = false;

  // ---------------------------------------------------------------------------
  // Navigation (BottomSheet instead of GoRouter)
  // ---------------------------------------------------------------------------

  Future<void> _goToNextPage(WidgetRef ref,IdempiereStorageOnHande storage) async {
    if (_opening) return;
    _opening = true;
    MemoryProducts.index = widget.index;
    MemoryProducts.listLength = widget.listLength;
    MemoryProducts.storage = widget.storage;
    MemoryProducts.width = widget.width;

    ref.read(isDialogShowedProvider.notifier).update((state)=>true);
    ref.read(isScanningFromDialogProvider.notifier).update((state)=>false);
    if(widget.storage.mLocatorID != null){
      ref.read(selectedLocatorFromProvider.notifier).update((state) => widget.storage.mLocatorID!);
      ref.read(isDialogShowedProvider.notifier).update((state)=>false);
      ref.invalidate(scannedLocatorToProvider);
      ref.invalidate(selectedLocatorToProvider);

      String productUPC = widget.storage.mProductID?.identifier ?? '-1';
      productUPC = productUPC.split('_').first;
      if (ref.context.mounted) {
        await showUnsortedStorageSheet(
          context: ref.context,
          ref: ref,
          productUPC: productUPC,
          readStockOnly: widget.readStockOnly,
          notifier: ref.read(scanHandleProvider.notifier),
        );
      }

    } else {
      showErrorMessage(context, ref, Messages.ERROR_LOCATOR_FROM);
      return;
    }

    _opening = false;
  }



  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = widget.storage;

    final locator = s.mLocatorID?.value ??
        s.mLocatorID?.identifier ??
        Messages.NO_DATA_FOUND;

    final warehouseName = s.mLocatorID?.mWarehouseID?.identifier ?? '--';
    final warehouseId = s.mLocatorID?.mWarehouseID?.id ?? -1;
    final userWarehouse = ref.read(authProvider).selectedWarehouse?.id ?? -1;
    bool canMove = warehouseId == userWarehouse;

    final qty = s.qtyOnHand ?? 0;

    // English: Basic "card item" UI, tappable
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: !canMove ? null : () async {
        // English: Open next step using bottom sheet flow
        await _goToNextPage(ref, widget.storage);
      },
      child: Container(
        width: widget.width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: canMove ? Colors.green[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // English: Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    warehouseName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: canMove ? Colors.purple[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: canMove ? Colors.purple[200]! : Colors.grey[300]!),
                  ),
                  child: Text(
                    Memory.numberFormatter0Digit.format(qty),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canMove ? Colors.purple : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // English: Locator
            Text(
              '${Messages.LOCATOR}: $locator',
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 8),

            // English: Small hint
            Text(
              Messages.CONTINUE,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
