import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';


class StorageOnHandSelectableCard extends StatelessWidget {
  final WidgetRef ref;
  final IdempiereStorageOnHande storage;
  final double width;
  final bool isSelected;
  final bool isInventory;
  final VoidCallback onTap;
  final VoidCallback? onSendTap;
  final Color selectedColor;
  final Color unselectedColor;

  const StorageOnHandSelectableCard({
    super.key,
    required this.ref,
    required this.storage,
    required this.width,
    required this.isSelected,
    required this.isInventory,
    required this.onTap,
    required this.selectedColor,
    this.unselectedColor = const Color(0xFFE0E0E0),
    this.onSendTap,
  });

  @override
  Widget build(BuildContext context) {
    final qtyOnHand = storage.qtyOnHand ?? 0;
    final quantity = Memory.numberFormatter0Digit.format(qtyOnHand);
    final warehouseName = storage.mLocatorID?.mWarehouseID?.identifier ?? '--';
    final locatorName = storage.mLocatorID?.value ?? '--';
    final attributeName =
        '${storage.mAttributeSetInstanceID?.identifier ?? '--'} (${storage.mAttributeSetInstanceID?.id ?? ''})';

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isSelected ? selectedColor : unselectedColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Messages.WAREHOUSE_SHORT),
                  SizedBox(height: 2),
                  Text(Messages.LOCATOR_SHORT),
                  SizedBox(height: 2),
                  Text(Messages.QUANTITY_SHORT),
                  SizedBox(height: 2),
                  Text(Messages.ATTRIBUET_INSTANCE),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locatorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          quantity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: qtyOnHand < 0 ? Colors.redAccent : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (onSendTap != null && qtyOnHand > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: FilledButton.icon(
                            onPressed: onSendTap,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text(
                              'Send',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    attributeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}