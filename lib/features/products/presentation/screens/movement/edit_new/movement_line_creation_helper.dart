import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/locator_provider.dart';
import '../../store_on_hand/memory_products.dart';
import '../provider/new_movement_provider.dart';

mixin MovementLineCreationHelper<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Future<void> createMovementLineOnly({
    required BuildContext context,
    required WidgetRef ref,
    required MovementAndLines movementAndLines,
    required IdempiereStorageOnHande sourceStorage,
    required String argument,
    required double lines,
  }) async {
    final movementId = movementAndLines.id ?? -1;
    if (movementId <= 0) {
      showErrorMessage(context, ref, Messages.MOVEMENT_ID);
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

    final locatorTo = ref.read(selectedLocatorToProvider).id ?? -1;
    if (locatorTo <= 0) {
      showErrorMessage(
        context,
        ref,
        Messages.ERROR_LOCATOR_TO,
        durationSeconds: 3,
      );
      return;
    }

    final movementQty = ref.read(quantityToMoveProvider);
    if (movementQty <= 0) {
      showErrorMessage(context, ref, Messages.ERROR_QUANTITY);
      return;
    }

    final movementLine = SqlDataMovementLine();
    Memory.sqlUsersData.copyToSqlData(movementLine);

    movementLine.mMovementID = IdempiereMovement(id: movementId);
    movementLine.mLocatorID = sourceStorage.mLocatorID;
    movementLine.mProductID = sourceStorage.mProductID;
    movementLine.mLocatorToID = ref.read(selectedLocatorToProvider);
    movementLine.movementQty = movementQty;
    movementLine.mAttributeSetInstanceID = sourceStorage.mAttributeSetInstanceID;
    movementLine.productName =
        sourceStorage.mProductID?.name ?? sourceStorage.mProductID?.identifier;
    movementLine.line = lines;

    if (movementLine.mMovementID?.id == null) {
      showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
      return;
    }

    if (movementLine.mLocatorID?.id == null) {
      showErrorMessage(context, ref, Messages.ERROR_LOCATOR_FROM);
      return;
    }

    if (movementLine.mProductID?.id == null) {
      showErrorMessage(context, ref, Messages.ERROR_PRODUCT);
      return;
    }

    if (movementLine.mLocatorToID?.id == null) {
      showErrorMessage(context, ref, Messages.ERROR_LOCATOR_TO);
      return;
    }

    MemoryProducts.newSqlDataMovementLineToCreate = movementLine;
    MemoryProducts.movementAndLines.movementLineToCreate = movementLine;

    MovementAndLines m;
    if (argument.isNotEmpty) {
      m = MovementAndLines.fromJson(jsonDecode(argument));
      if (!m.hasMovement) {
        showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
        return;
      }
    } else {
      m = movementAndLines;
      if (!m.hasMovement) {
        showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
        return;
      }
    }

    m.movementLineToCreate = movementLine;
    MemoryProducts.movementAndLines = m;

    if (context.mounted) {
      context.go(AppRouter.PAGE_CREATE_MOVEMENT_LINE, extra: m);
    }
  }
}