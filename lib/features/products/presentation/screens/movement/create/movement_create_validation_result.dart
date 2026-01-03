import 'package:flutter/material.dart';

import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/put_away_movement.dart';


enum PutAwayCloseMode {
  closeOnly, // English: close modal/screen only
  goStoreOnHand, // English: navigate back to StoreOnHand
}
class PutAwayValidationResult {
  final bool ok;
  final String message;
  final IconData icon;
  final Color accent;

  const PutAwayValidationResult.ok()
      : ok = true,
        message = '',
        icon = Icons.check_circle,
        accent = Colors.green;

  const PutAwayValidationResult.error({
    required this.message,
    this.icon = Icons.error,
    this.accent = Colors.red,
  }) : ok = false;
}

// English: Map PutAwayMovement result code to UI-friendly info
PutAwayValidationResult mapPutAwayCheckToUi(int code) {
  switch (code) {
    case PutAwayMovement.SUCCESS:
      return const PutAwayValidationResult.ok();

    case PutAwayMovement.ERROR_START_CREATE:
      return PutAwayValidationResult.error(message: Messages.ERROR_START_CREATE);

    case PutAwayMovement.ERROR_LOCATOR_TO:
      return PutAwayValidationResult.error(message: Messages.ERROR_LOCATOR_TO);

    case PutAwayMovement.ERROR_LOCATOR_FROM:
      return PutAwayValidationResult.error(message: Messages.ERROR_LOCATOR_FROM);

    case PutAwayMovement.ERROR_SAME_LOCATOR:
      return PutAwayValidationResult.error(message: Messages.ERROR_SAME_LOCATOR);

    case PutAwayMovement.ERROR_QUANTITY:
      return PutAwayValidationResult.error(message: Messages.ERROR_QUANTITY);

    case PutAwayMovement.ERROR_WAREHOUSE_FROM:
      return PutAwayValidationResult.error(message: Messages.ERROR_WAREHOUSE_FROM);

    case PutAwayMovement.ERROR_WAREHOUSE_TO:
      return PutAwayValidationResult.error(message: Messages.ERROR_WAREHOUSE_TO);

    case PutAwayMovement.ERROR_ORG_WAREHOUSE_FROM:
      return PutAwayValidationResult.error(message: Messages.ERROR_ORG_WAREHOUSE_FROM);

    case PutAwayMovement.ERROR_ORG_WAREHOUSE_TO:
      return PutAwayValidationResult.error(message: Messages.ERROR_ORG_WAREHOUSE_TO);

    case PutAwayMovement.ERROR_DOCUMENT_TYPE:
      return PutAwayValidationResult.error(message: Messages.ERROR_DOCUMENT_TYPE);

    case PutAwayMovement.ERROR_PRODUCT:
      return PutAwayValidationResult.error(message: Messages.ERROR_PRODUCT);

    case PutAwayMovement.ERROR_MOVEMENT:
      return PutAwayValidationResult.error(message: Messages.ERROR_MOVEMENT);

    case PutAwayMovement.ERROR_MOVEMENT_LINE:
      return PutAwayValidationResult.error(message: Messages.ERROR_MOVEMENT_LINE);

    case PutAwayMovement.ERROR_MOVEMENT_NULL:
      return PutAwayValidationResult.error(message: Messages.ERROR_MOVEMENT_NULL);

    default:
      return PutAwayValidationResult.error(message: '${Messages.ERROR} : $code');
  }
}
