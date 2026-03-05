
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/unsorted_storage_on__hand_screen_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/unsorted_storage_on__hand_select_locator_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../providers/actions/find_locator_to_action_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../provider/new_movement_provider.dart';


class StorageOnHandCardForLine extends ConsumerStatefulWidget {
  final IdempiereStorageOnHande storage;

  final int index;
  final int listLength;

  final double width;

  /// English: Original argument used across navigation (movement json or '-1')
  final String argument;

  final MovementAndLines movementAndLines;

  /// English: Used to restrict warehouses in some flows
  final dynamic allowedWarehouseFrom;

  const StorageOnHandCardForLine(
      this.storage,
      this.index,
      this.listLength, {
        super.key,
        required this.width,
        required this.argument,
        required this.movementAndLines,
        this.allowedWarehouseFrom,
      });

  @override
  ConsumerState<StorageOnHandCardForLine> createState() =>
      _StorageOnHandCardForLineState();
}

class _StorageOnHandCardForLineState
    extends ConsumerState<StorageOnHandCardForLine> {
  bool _opening = false;

  // ---------------------------------------------------------------------------
  // Navigation (BottomSheet instead of GoRouter)
  // ---------------------------------------------------------------------------

  Future<void> _goToNextPage(WidgetRef ref, MovementAndLines movementAndLines) async {
    if (_opening) return;
    _opening = true;

    // English: Persist current selection context
    MemoryProducts.index = widget.index;
    MemoryProducts.listLength = widget.listLength;
    MemoryProducts.storage = widget.storage;
    MemoryProducts.width = widget.width;

    // English: For next page logic, keep what you did (ID or UPC depending your flow)
    movementAndLines.nextProductIdUPC =
        widget.storage.mProductID?.id?.toString() ?? '-1';

    // English: Set scan action + home index (same behavior)
    ref.read(actionScanProvider.notifier).update(
          (_) => Memory.ACTION_GET_LOCATOR_TO_VALUE,
    );

    // English: Build argument (you were using nextProductIdUPC)
    final String argument = movementAndLines.nextProductIdUPC ?? '-1';

    if (!mounted) {
      _opening = false;
      return;
    }

    // English: Decide which sheet to open
    if (movementAndLines.canChangeLocatorForEachLine) {
      // English: Invalidate locator selection if not copying last locator
      ref.invalidate(scannedLocatorToProvider);
      final copyLastLocatorTo = ref.read(copyLastLocatorToProvider);
      if (!copyLastLocatorTo) {
        ref.invalidate(selectedLocatorToProvider);

      }

      await _showSelectLocatorSheet(
        ref: ref,
        movementAndLines: movementAndLines,
        argument: argument,
      );
    } else {
      ref.read(actionScanProvider.notifier).update(
            (_) => Memory.ACTION_NO_SCAN_ACTION,
      );
      await _showUnsortedForLineSheet(
        ref: ref,
        movementAndLines: movementAndLines,
        argument: argument,
      );
    }

    _opening = false;
  }

  Future<void> _showSelectLocatorSheet({
    required WidgetRef ref,
    required MovementAndLines movementAndLines,
    required String argument,
  }) async {
    // English: Keep movement snapshot as json if needed
    final String movementJson = jsonEncode(movementAndLines.toJson());
    final String upc = MemoryProducts.storage.mProductID?.uPC ?? '-1';

    // English: Do provider updates after this frame (avoids build-phase issues)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final copyTo = ref.read(copyLastLocatorToProvider);
      if (!copyTo) {
        ref.invalidate(selectedLocatorToProvider);
      }

      ref.read(actionScanProvider.notifier).update(
            (_) => Memory.ACTION_GET_LOCATOR_TO_VALUE,
      );
    });

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
        child: UnsortedStorageOnHandSelectLocatorScreen(
          movementAndLines: movementAndLines,
          index: MemoryProducts.index,
          storage: MemoryProducts.storage,
          width: MemoryProducts.width,
        ),
      ),
    );
  }

  Future<void> _showUnsortedForLineSheet({
    required WidgetRef ref,
    required MovementAndLines movementAndLines,
    required String argument,
  }) async {
    // English: Keep movement snapshot as json if needed
    final String movementJson = jsonEncode(movementAndLines.toJson());
    final String upc = MemoryProducts.storage.mProductID?.uPC ?? '-1';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(actionScanProvider.notifier).update(
            (_) => Memory.ACTION_GET_LOCATOR_TO_VALUE,
      );
    });

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
        child: UnsortedStorageOnHandScreenForLine(
          argument: movementJson,
          movementAndLines: movementAndLines,
          index: MemoryProducts.index,
          storage: MemoryProducts.storage,
          width: MemoryProducts.width,
        ),
      ),
    );
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
    final lastWarehouseFromId = widget.allowedWarehouseFrom?.id ?? -1;
    bool canMove = warehouseId == lastWarehouseFromId;

    final qty = s.qtyOnHand ?? 0;

    // English: Basic "card item" UI, tappable
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: !canMove ? null : () async {
        // English: Open next step using bottom sheet flow
        await _goToNextPage(ref, widget.movementAndLines);
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
              widget.movementAndLines.canChangeLocatorForEachLine
                  ? Messages.SELECT_LOCATOR_TO
                  : Messages.CONTINUE,
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
