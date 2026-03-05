import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/widget/show_delete_confirmation_sheet.dart';
import '../../../../domain/idempiere/inventory_and_lines.dart';

class NewInventoryCardWithLocator extends ConsumerStatefulWidget {
  Color bgColor;
  final InventoryAndLines inventoryAndLines;
  final double width;

  final TextStyle inventoryStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: themeFontSizeLarge,
  );

  final TextStyle inventoryStyleMedium = const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontSize: themeFontSizeNormal,
  );

  NewInventoryCardWithLocator({
    super.key,
    required this.bgColor,
    required this.width,
    required this.inventoryAndLines,
  });

  @override
  ConsumerState<NewInventoryCardWithLocator> createState() =>
      _NewInventoryCardWithLocatorState();
}

class _NewInventoryCardWithLocatorState
    extends ConsumerState<NewInventoryCardWithLocator> {
  late final InventoryAndLines inventoryAndLinesSaved;

  @override
  void initState() {
    super.initState();
    inventoryAndLinesSaved = widget.inventoryAndLines;
  }

  Widget get getActionCompleteMessage {
    if (widget.inventoryAndLines.canCompleteInventory) {
      return GestureDetector(
        onTap: () async {
          final confirm = await showConfirmDialog(
            context,
            title: Messages.COMPLETE_INVENTORY,
            message: 'Completar inventario?',
            icon: Icons.help_outline_rounded,
            iconColor: themeColorWarning,
            okText: Messages.OK,
            cancelText: Messages.CANCEL,
            okColor: themeColorSuccessful,
            cancelColor: themeColorError,
          );

          if (confirm && context.mounted) {
            context.go(
              AppRouter.PAGE_INVENTORY_CONFIRM_SCREEN,
              extra: widget.inventoryAndLines,
            );
          }
        },
        child: Container(
          color: Colors.green,
          child: SizedBox(
            width: 100,
            child: Text(
              Messages.COMPLETE,
              textAlign: TextAlign.end,
              style: widget.inventoryStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget get getActionCancelMessage {
    if (widget.inventoryAndLines.canCancelInventory) {
      return GestureDetector(
        onTap: () {
          showDeleteConfirmationSheet(
            context: context,
            ref: ref,
            onConfirm: ({
              required BuildContext context,
              required WidgetRef ref,
            }) async {
              context.go(
                AppRouter.PAGE_INVENTORY_CANCEL_SCREEN,
                extra: inventoryAndLinesSaved,
              );
            },
          );
        },
        child: Container(
          color: Colors.red,
          child: SizedBox(
            width: 100,
            child: Text(
              Messages.CANCEL,
              textAlign: TextAlign.end,
              style: widget.inventoryStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.bgColor = themeColorPrimary;


    String id = '';
    String date = '';
    String titleLeft = '';
    String subtitleLeft = '';
    String documentType =
        widget.inventoryAndLines.cDocTypeID?.identifier ?? 'DOC';

    if (widget.inventoryAndLines.hasInventory) {
      id = widget.inventoryAndLines.documentNo ?? '';
      date = widget.inventoryAndLines.movementDate?.toString() ?? '';
      titleLeft =
      '${Messages.WAREHOUSE}: ${widget.inventoryAndLines.mWarehouseID?.identifier ?? ''}';
      subtitleLeft =
      '${Messages.DOC_STATUS}: ${widget.inventoryAndLines.docStatus?.identifier ?? ''}';
    } else {
      id = widget.inventoryAndLines.name ?? Messages.EMPTY;
      titleLeft = widget.inventoryAndLines.identifier ?? Messages.EMPTY;
    }

    final textStyle = documentType.length > 20
        ? widget.inventoryStyleMedium
        : widget.inventoryStyle;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color:widget.bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  id,
                  style: widget.inventoryStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                date,
                style: widget.inventoryStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  titleLeft,
                  style: widget.inventoryStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  documentType,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              getActionCancelMessage,
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitleLeft,
                  style: widget.inventoryStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              getActionCompleteMessage,
            ],
          ),
        ],
      ),
    );
  }
}