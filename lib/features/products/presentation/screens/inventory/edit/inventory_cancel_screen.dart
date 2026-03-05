import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../provider/new_inventory_provider.dart';
import 'inventory_confirm_screen.dart';

class InventoryCancelScreen extends InventoryConfirmScreen {
  InventoryCancelScreen({
    super.key,
    required super.inventoryAndLines,
    required super.argument,
  });

  @override
  ConsumerState<InventoryConfirmScreen> createState() =>
      InventoryCancelScreenState();
}

class InventoryCancelScreenState extends InventoryConfirmScreenState {
  @override
  AsyncValue get actionAsync => ref.watch(cancelInventoryProvider);

  @override
  String get getTitleMessage => Messages.CANCEL_INVENTORY;

  @override
  bool get isActionSuccess {
    final doc = widget.inventoryAndLines.docStatus?.id ?? '';
    return doc == Memory.IDEMPIERE_DOC_TYPE_CANCEL;
  }

  @override
  Future<void> actionAfterShow(WidgetRef ref) async {
    if (widget.inventoryAndLines.canCancelInventory == false) {
      showErrorMessage(
        context,
        ref,
        Messages.ERROR_CANNOT_CANCEL_INVENTORY,
        durationSeconds: 5,
      );
      return;
    }

    if (!started) {
      started = true;
      ref.read(inventoryIdForCancelProvider.notifier).state =
          widget.inventoryAndLines.id;
    }
  }
}