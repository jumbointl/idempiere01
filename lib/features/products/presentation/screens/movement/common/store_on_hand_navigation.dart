import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/product_store_on_hand_screen_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/unsorted_storage_on__hand_select_locator_screen.dart';

import '../../../../../../config/constants/roles_app.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/product_provider_common.dart';


// Screens
import '../../store_on_hand/memory_products.dart';
import '../provider/new_movement_provider.dart';
import '../edit_new/movement_lines_create_screen.dart';

/// English: Centralized navigation helper for Store On Hand flows.
class StoreOnHandNavigation {
  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// English: Open ProductStoreOnHandScreenForLine as a bottom sheet (replacing PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE route).
  static Future<void> openProductStoreOnHandForLineSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String productUPC,
    required MovementAndLines movementAndLines,
  }) async {
    if (!_hasPrivilegeForLine()) {
      // English: Fallback - do nothing or show home
      return;
    }

    // English: Prepare providers/state exactly like your GoRoute.builder
    _prepareForProductStoreOnHandForLine(ref);

    // English: Prepare movement payload + argument
    movementAndLines.nextProductIdUPC = productUPC;
    final String argument = jsonEncode(movementAndLines.toJson());

    await _showSheet(
      context: context,
      child: ProductStoreOnHandScreenForLine(
        productId: productUPC,
        movementAndLines: movementAndLines,
        argument: argument,
      ),
    );
  }

  /// English: Open UnsortedStorageOnHandSelectLocatorScreen as a bottom sheet
  /// (replacing PAGE_UNSORTED_STORAGE_ON_HAND_FOR_LINE_SELECT_LOCATOR route).
  static Future<void> openSelectLocatorSheet({
    required BuildContext context,
    required WidgetRef ref,
    required MovementAndLines movementAndLines,
    required String argument, // you can pass prebuilt or we rebuild from movement
    required int index,
    required double width,
    required dynamic storage, // keep your current type (IdempiereStorageOnHande)
  }) async {
    if (!_hasPrivilegeForSelectLocator()) {
      return;
    }

    // English: Persist MemoryProducts values (same behavior as your flow)
    MemoryProducts.index = index;
    MemoryProducts.width = width;
    MemoryProducts.storage = storage;
    MemoryProducts.movementAndLines = movementAndLines;

    final String upc = MemoryProducts.storage.mProductID?.uPC ?? '-1';

    // English: Prepare providers/state exactly like your GoRoute.builder
    _prepareForSelectLocator(ref);

    // English: If you want to ensure argument always matches movement state:
    final String safeArgument = (argument.isNotEmpty && argument != '-1')
        ? argument
        : jsonEncode(movementAndLines.toJson());

    await _showSheet(
      context: context,
      child: UnsortedStorageOnHandSelectLocatorScreen(
        argument: safeArgument,
        movementAndLines: movementAndLines,
        index: MemoryProducts.index,
        storage: MemoryProducts.storage,
        productUPC: upc,
        width: MemoryProducts.width,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Provider preparation (copied from your routes)
  // ---------------------------------------------------------------------------

  static void _prepareForProductStoreOnHandForLine(WidgetRef ref) {
    // English: Same as your Future.delayed(Duration.zero, ...)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(allowedMovementDocumentTypeProvider);

      ref.read(actionScanProvider.notifier).update(
            (_) => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND,
      );

      ref.read(isDialogShowedProvider.notifier).update((_) => false);
      ref.read(isScanningProvider.notifier).update((_) => false);
    });
  }

  static void _prepareForSelectLocator(WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final copyTo = ref.read(copyLastLocatorToProvider);
      if (!copyTo) {
        ref.invalidate(selectedLocatorToProvider);
      }


      ref.read(actionScanProvider.notifier).update(
            (_) => Memory.ACTION_GET_LOCATOR_TO_VALUE,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Sheet UI helper
  // ---------------------------------------------------------------------------

  static Future<void> _showSheet({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.95,
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Privileges
  // ---------------------------------------------------------------------------

  static bool _hasPrivilegeForLine() {
    return RolesApp.canCreateMovementInSameOrganization ||
        RolesApp.canCreateDeliveryNote ||
        RolesApp.canEditMovement;
  }

  static bool _hasPrivilegeForSelectLocator() {
    return RolesApp.canCreateMovementInSameOrganization ||
        RolesApp.canCreateDeliveryNote;
  }
}

double get cardGap => 8;
Future<void> openMovementLinesCreateBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required MovementAndLines movementAndLines,
  required String argument,
}) async {
  // English: Ensure focus/scan flags are reset before opening
  ref.read(isDialogShowedProvider.notifier).state = false;
  ref.read(isScanningProvider.notifier).state = false;

  final double width = MediaQuery.of(context).size.width;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return FractionallySizedBox(
        heightFactor: 0.95, // English: almost full-screen
        child: MovementLinesCreateScreen(
          argument: argument,
          movementAndLines: movementAndLines,
          width: width,
        ),
      );
    },
  );
}







