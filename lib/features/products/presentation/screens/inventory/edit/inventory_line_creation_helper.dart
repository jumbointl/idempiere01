import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_inventory.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/inventory_and_lines.dart';
import '../../../../domain/sql/sql_data_inventory_line.dart';
import '../../../providers/common_provider.dart';
import '../../movement/provider/new_movement_provider.dart';
import '../../store_on_hand/memory_products.dart';
import 'inventory_lines_create_screen.dart';

mixin InventoryLineCreationHelper<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Future<void> createInventoryLineOnly({
    required BuildContext context,
    required WidgetRef ref,
    required InventoryAndLines inventoryAndLines,
    required IdempiereStorageOnHande sourceStorage,
    required double width,
  }) async {
    final inventoryId = inventoryAndLines.id ?? -1;
    if (inventoryId <= 0) {
      showErrorMessage(context, ref, 'Inventory ID');
      return;
    }

    final locatorFrom = sourceStorage.mLocatorID?.id ?? -1;
    if (locatorFrom <= 0) {
      showErrorMessage(
        context,
        ref,
        Messages.ERROR_LOCATOR_FROM,
        durationSeconds: 3,
      );
      return;
    }
    final line = ref.read(inventoryLinesProvider(inventoryAndLines));


    final qtyCount = ref.read(quantityToMoveProvider);
    if (qtyCount < 0) {
      showErrorMessage(
        context,
        ref,
        Messages.ERROR_QUANTITY,
        durationSeconds: 3,
      );
      return;
    }


    final inventoryLine = SqlDataInventoryLine();
    Memory.sqlUsersData.copyToSqlData(inventoryLine);
    inventoryLine.line = line;
    inventoryLine.mInventoryID = IdempiereInventory(id: inventoryId);
    inventoryLine.mLocatorID = sourceStorage.mLocatorID;
    inventoryLine.mProductID = sourceStorage.mProductID;
    inventoryLine.qtyBook = sourceStorage.qtyOnHand ?? 0;
    inventoryLine.qtyCount = qtyCount;
    inventoryLine.mAttributeSetInstanceID = sourceStorage.mAttributeSetInstanceID;
    inventoryLine.productName =
        sourceStorage.mProductID?.name ?? sourceStorage.mProductID?.identifier;

    MemoryProducts.newSqlDataInventoryLineToCreate = inventoryLine;
    inventoryAndLines.inventoryLineToCreate = inventoryLine;

    final argument = jsonEncode(inventoryAndLines.toJson());

    if (context.mounted) {
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
          child: InventoryLinesCreateScreen(
            inventoryAndLines: inventoryAndLines,
            width: width,
            argument: argument,
          ),
        ),
      );
    }
  }
}