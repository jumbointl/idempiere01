

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_attribute_set_instance.dart';

import '../../../products/domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../providers/line_provider.dart';


class StorageOnHandCardForMInOutLine extends ConsumerStatefulWidget {
  final IdempiereStorageOnHande storage;
  final double width;



  /// English: Used to restrict warehouses in some flows
  final String allowedWarehouseFrom;
  final IdempiereAttributeSetInstance? allowedAttSet;

  const StorageOnHandCardForMInOutLine(
       {
        super.key,
        required this.width,
        required this.storage,
        required this.allowedWarehouseFrom,
        this.allowedAttSet
      });

  @override
  ConsumerState<StorageOnHandCardForMInOutLine> createState() =>
      _StorageOnHandCardForLineState();
}

class _StorageOnHandCardForLineState
    extends ConsumerState<StorageOnHandCardForMInOutLine> {





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
    final storageAttSet = s.mAttributeSetInstanceID?.id ?? -1;
    final allowedAttSet = widget.allowedAttSet?.id ?? -1;

    bool canMove = warehouseId.toString() == widget.allowedWarehouseFrom && warehouseId>0;
    if(canMove && allowedAttSet>0){
      canMove = storageAttSet == allowedAttSet;
    }

    final qty = s.qtyOnHand ?? 0;

    // English: Basic "card item" UI, tappable
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: !canMove ? null : () async {
        ref.read(selectedLocatorForMinOutProvider.notifier).state = s.mLocatorID ;
        Navigator.of(context).pop();
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
            Text(Messages.SELECT_LOCATOR_TO,
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
