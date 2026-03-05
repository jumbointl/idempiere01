import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/inventory_and_lines.dart';
import '../../store_on_hand/memory_products.dart';
import 'unsorted_storage_on_hand_screen_for_inventory_line.dart';

class StorageOnHandCardForInventoryLine extends ConsumerStatefulWidget {
  final IdempiereStorageOnHande storage;
  final int index;
  final int listLength;
  final double width;
  final String argument;
  final InventoryAndLines inventoryAndLines;
  final bool isInventory;

  const StorageOnHandCardForInventoryLine(
      this.storage,
      this.index,
      this.listLength, {
        super.key,
        required this.width,
        required this.argument,
        required this.inventoryAndLines,
        required this.isInventory,
      });

  @override
  ConsumerState<StorageOnHandCardForInventoryLine> createState() =>
      _StorageOnHandCardForInventoryLineState();
}

class _StorageOnHandCardForInventoryLineState
    extends ConsumerState<StorageOnHandCardForInventoryLine> {
  bool _opening = false;

  Future<void> _goToNextPage(
      WidgetRef ref,
      InventoryAndLines inventoryAndLines,
      ) async {
    if (_opening) return;
    _opening = true;

    MemoryProducts.index = widget.index;
    MemoryProducts.listLength = widget.listLength;
    MemoryProducts.storage = widget.storage;
    MemoryProducts.width = widget.width;

    inventoryAndLines.nextProductIdUPC =
        widget.storage.mProductID?.id?.toString() ?? '-1';

    final String inventoryJson = jsonEncode(inventoryAndLines.toJson());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: Memory.FRACTIONNALLY_SIZE_SHEET_HEIGHT,
        child: UnsortedStorageOnHandScreenForInventoryLine(
          inventoryAndLines: inventoryAndLines,
          index: MemoryProducts.index,
          storage: MemoryProducts.storage,
          width: MemoryProducts.width,
          isInventory: widget.isInventory,
        ),
      ),
    );

    _opening = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.storage;

    final locator = s.mLocatorID?.value ??
        s.mLocatorID?.identifier ??
        Messages.NO_DATA_FOUND;

    final warehouseName = s.mLocatorID?.mWarehouseID?.identifier ?? '--';
    final qty = s.qtyOnHand ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await _goToNextPage(ref, widget.inventoryAndLines);
      },
      child: Container(
        width: widget.width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Text(
                    Memory.numberFormatter0Digit.format(qty),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${Messages.LOCATOR}: $locator',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
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