import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/locator_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand/action_notifier.dart';

import '../../../../../config/router/app_router.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../common/messages_dialog.dart';
import '../../providers/product_provider_common.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../store_on_hand/memory_products.dart';

class LocatorCard extends ConsumerStatefulWidget {
  bool? selected = false;
  final IdempiereLocator data;

  final int index;

  String? title;
  double? width;
  final bool readOnly;

  LocatorCard({
    required this.readOnly,
    required this.data,
    this.selected,
    this.title,
    super.key,
    required this.index,
    this.width,
  });

  @override
  ConsumerState<LocatorCard> createState() => LocatorCardState();
}

class LocatorCardState extends ConsumerState<LocatorCard> {
  late var saveDataToState;

  @override
  Widget build(BuildContext context) {
    if (widget.data.mWarehouseID?.name != null) {
      widget.data.mWarehouseID?.identifier = widget.data.mWarehouseID?.name;
    }
    widget.data.value ??= widget.data.identifier;

    final String warehouseName = widget.data.mWarehouseID?.identifier ?? '';
    final String locatorName = widget.data.value ?? '';
    final Color backGroundColor = Colors.white;

    // ✅ READONLY = MULTI-SELECT
    if (widget.readOnly) {
      final key = SelectedLocatorsNotifier.keyOf(widget.data);
      final selectedKeys = ref.watch(selectedLocatorsProvider);
      final isChecked = key.isNotEmpty && selectedKeys.contains(key);

      return Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: backGroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: themeColorPrimary, width: 1),
        ),
        child: ListTile(
          leading: Checkbox(
            value: isChecked,
            onChanged: key.isEmpty
                ? null
                : (_) => ref.read(selectedLocatorsProvider.notifier).toggle(widget.data),
          ),
          onTap: key.isEmpty
              ? null
              : () => ref.read(selectedLocatorsProvider.notifier).toggle(widget.data),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          title: Text(locatorName, style: const TextStyle(color: Colors.purple)),
          subtitle: Text(warehouseName),
          trailing: IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {

              MemoryProducts.LAST_PAGE = 'AppRouter.PAGE_SEARCH_LOCATOR_LIST';
              ref.read(actionScanProvider.notifier).state =
                  Memory.ACTION_FIND_PRINTER_BY_QR_WIFI_BLUETOOTH;
              context.push(
                AppRouter.PAGE_LOCATOR_LABEL_PRINTER_SELECT_PAGE,
                extra: widget.data,
              );
            },
          ),
        ),
      );
    }

    // ✅ NORMAL (no readonly)
    return GestureDetector(
      onTap: () {
        if (widget.data.id == null || widget.data.id! <= 0) {
          showErrorMessage(context, ref, Messages.NO_DATA_AVAILABLE);
          return;
        }

        ref.invalidate(selectedLocatorToProvider);
        ref.read(findLocatorToActionProvider).handleInputString(
          ref: ref,
          inputData: widget.data.value ?? '',
          actionScan: Memory.ACTION_GET_LOCATOR_TO_VALUE,
        );

        ref.read(isDialogShowedProvider.notifier).state = false;
        Future.delayed(const Duration(microseconds: 100));
        Navigator.pop(context);
      },
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: backGroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: themeColorPrimary, width: 1),
        ),
        padding: const EdgeInsets.all(10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          title: Text(locatorName, style: const TextStyle(color: Colors.purple)),
          subtitle: Text(warehouseName),
          trailing: IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              MemoryProducts.LAST_PAGE = 'AppRouter.PAGE_SEARCH_LOCATOR_LIST';
              context.push(
                AppRouter.PAGE_LOCATOR_LABEL_PRINTER_SELECT_PAGE,
                extra: widget.data,
              );
            },
          ),
        ),
      ),
    );
  }
}