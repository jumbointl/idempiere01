import 'package:flutter/material.dart';

import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/put_away_inventory.dart';
import '../../inventory/create/inventory_create_screen.dart';
import 'movement_create_validation_result.dart';

Future<void> openInventoryCreateBottomSheet({
  required BuildContext context,
  required PutAwayInventory putAwayInventory,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return FractionallySizedBox(
        heightFactor: 0.95,
        child: InventoryCreateScreen(
          inventoryAndLines: putAwayInventory,
        ),
      );
    },
  );
}

PutAwayValidationResult mapPutAwayInventoryCheckToUi(int check) {
  switch (check) {
    case PutAwayInventory.SUCCESS:
      return const PutAwayValidationResult.ok();
    case PutAwayInventory.ERROR_LOCATOR_FROM:
      return PutAwayValidationResult.error(
        message: Messages.ERROR_LOCATOR_FROM,
      );
    case PutAwayInventory.ERROR_QUANTITY:
      return PutAwayValidationResult.error(
        message: Messages.ERROR_QUANTITY,
      );
    case PutAwayInventory.ERROR_PRODUCT:
      return PutAwayValidationResult.error(
        message: Messages.ERROR_PRODUCT,
      );
    case PutAwayInventory.ERROR_WAREHOUSE_FROM:
      return PutAwayValidationResult.error(
        message: Messages.ERROR_WAREHOUSE_FROM,
      );
    case PutAwayInventory.ERROR_ORG_WAREHOUSE_FROM:
      return PutAwayValidationResult.error(
        message: Messages.ERROR_ORG_WAREHOUSE_FROM,
      );
    case PutAwayInventory.ERROR_DOCUMENT_TYPE:
      return PutAwayValidationResult.error(
        message: Messages.ERROR_DOCUMENT_TYPE,
      );
    case PutAwayInventory.ERROR_INVENTORY_NULL:
      return PutAwayValidationResult.error(
        message: 'Inventory is null',
      );
    case PutAwayInventory.ERROR_INVENTORY:
      return PutAwayValidationResult.error(
        message: 'Inventory already created or invalid',
      );
    case PutAwayInventory.ERROR_INVENTORY_LINE:
      return PutAwayValidationResult.error(
        message: 'Inventory line already created or invalid',
      );
    case PutAwayInventory.ERROR_START_CREATE:
      return PutAwayValidationResult.error(
        message: Messages.ERROR_START_CREATE,
      );
    default:
      return PutAwayValidationResult.error(
        message: Messages.ERROR,
      );
  }
}
