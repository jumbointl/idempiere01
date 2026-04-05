import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/delete_request.dart';
import '../../../../domain/idempiere/idempiere_inventory_line.dart';
import '../../../providers/actions/find_inventory_by_id_action_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../provider/new_inventory_provider.dart' hide inventoryAndLinesProvider;

class NewInventoryLineCard extends ConsumerStatefulWidget {
  final IdempiereInventoryLine inventoryLine;
  final double width;
  final int index;
  final int totalLength;
  final bool canEdit;

  const NewInventoryLineCard({
    super.key,
    required this.width,
    required this.inventoryLine,
    required this.index,
    required this.totalLength,
    required this.canEdit,
  });

  @override
  ConsumerState<NewInventoryLineCard> createState() =>
      _NewInventoryLineCardState();
}

class _NewInventoryLineCardState extends ConsumerState<NewInventoryLineCard> {
  ProviderSubscription<DeleteRequest?>? _deleteTriggerSub;
  ProviderSubscription<int?>? _updateTriggerSub;
  ProviderSubscription<AsyncValue<bool>>? _deleteOpSub;
  ProviderSubscription<AsyncValue<double?>>? _updateOpSub;

  int get _lineId => widget.inventoryLine.id ?? -1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = widget.inventoryLine.qtyCount ?? 0.0;
      ref
          .read(inventoryLineQuantityToCountProvider(_lineId).notifier)
          .state = initial;
    });

    _attachManualListeners();
  }

  @override
  void didUpdateWidget(covariant NewInventoryLineCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.inventoryLine.id ?? -1;
    if (oldId != _lineId) {
      _disposeManualListeners();
      _attachManualListeners();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final initial = widget.inventoryLine.qtyCount ?? 0.0;
        ref
            .read(inventoryLineQuantityToCountProvider(_lineId).notifier)
            .state = initial;
      });
    }
  }

  void _attachManualListeners() {
    _deleteTriggerSub = ref.listenManual<DeleteRequest?>(
      deleteInventoryRequestProvider,
          (prev, next) {
        if (next == null) return;
        if (next.lineId != _lineId) return;

        ref.read(editingInventoryLineProvider(_lineId).notifier).state = true;

        _deleteOpSub?.close();
        _deleteOpSub = ref.listenManual<AsyncValue<bool>>(
          deleteInventoryLineProvider(next),
              (p, n) {
            n.whenOrNull(
              data: (deleted) async {
                _deleteOpSub?.close();
                _deleteOpSub = null;

                ref.read(deleteInventoryRequestProvider.notifier).state = null;
                ref.read(editingInventoryLineProvider(_lineId).notifier).state =
                false;

                if (deleted != true) {
                  if (!mounted) return;
                  showErrorMessage(
                    context,
                    ref,
                    Messages.ERROR_LINE_NOT_DELETED,
                  );
                  return;
                }

                final counter = ref.read(inventoryLineDeletedCounterProvider);
                ref.read(inventoryLineDeletedCounterProvider.notifier).state =
                    counter + 1;

                final currentFire = ref.read(fireFindInventoryByIdProvider);
                ref.read(fireFindInventoryByIdProvider.notifier).state = currentFire + 1;

                if (!mounted) return;
                await showSuccessMessage(
                  durationSeconds: 1,
                  context,
                  ref,
                  Messages.DELETED,
                );


              },
              error: (e, st) {
                _deleteOpSub?.close();
                _deleteOpSub = null;
                ref.read(deleteInventoryRequestProvider.notifier).state = null;
                ref.read(editingInventoryLineProvider(_lineId).notifier).state =
                false;

                if (!mounted) return;
                showErrorMessage(
                  context,
                  ref,
                  Messages.ERROR_LINE_NOT_DELETED,
                );
              },
            );
          },
        );
      },
    );

    _updateTriggerSub = ref.listenManual<int?>(
      updateInventoryLineIdProvider,
          (prev, next) {
        if (next != _lineId) return;

        ref.read(editingInventoryLineProvider(_lineId).notifier).state = true;

        _updateOpSub?.close();
        _updateOpSub = ref.listenManual<AsyncValue<double?>>(
          editInventoryLineQuantityProvider(_lineId),
              (p, n) {
            n.whenOrNull(
              data: (result) {
                ref.read(updateInventoryLineIdProvider.notifier).state = null;
                ref.read(quantityOfInventoryLineToEditProvider.notifier).state =
                null;
                ref.read(editingInventoryLineProvider(_lineId).notifier).state =
                false;

                _updateOpSub?.close();
                _updateOpSub = null;

                if (result == null) return;

                final isSuccess = result >= 0;
                if (isSuccess) {
                  widget.inventoryLine.qtyCount = result;
                  ref
                      .read(inventoryLineQuantityToCountProvider(_lineId).notifier)
                      .state = result;

                  final current = ref.read(inventoryAndLinesProvider);
                  final lines = List<IdempiereInventoryLine>.from(
                    current.inventoryLines ?? const [],
                  );
                  final idx = lines.indexWhere((e) => (e.id ?? -1) == _lineId);
                  if (idx >= 0) {
                    lines[idx].qtyCount = result;
                    current.inventoryLines = lines;
                    ref.read(inventoryAndLinesProvider.notifier).state = current;
                  }

                  if (!mounted) return;
                  showSuccessMessage(
                    context,
                    ref,
                    Messages.UPDATED_QUANTITY,
                  );
                  setState(() {});
                } else {
                  if (!mounted) return;
                  showErrorMessage(
                    context,
                    ref,
                    Messages.ERROR_UPDATE_QUANTITY,
                  );
                }
              },
              error: (_, _) {
                ref.read(updateInventoryLineIdProvider.notifier).state = null;
                ref.read(quantityOfInventoryLineToEditProvider.notifier).state =
                null;
                ref.read(editingInventoryLineProvider(_lineId).notifier).state =
                false;

                _updateOpSub?.close();
                _updateOpSub = null;

                if (!mounted) return;
                showErrorMessage(
                  context,
                  ref,
                  Messages.ERROR_UPDATE_QUANTITY,
                );
              },
            );
          },
        );
      },
    );
  }

  void _disposeManualListeners() {
    _deleteOpSub?.close();
    _updateOpSub?.close();
    _deleteTriggerSub?.close();
    _updateTriggerSub?.close();

    _deleteOpSub = null;
    _updateOpSub = null;
    _deleteTriggerSub = null;
    _updateTriggerSub = null;
  }

  @override
  void dispose() {
    _disposeManualListeners();
    super.dispose();
  }

  Future<void> _editQuantity() async {
    final currentQty = widget.inventoryLine.qtyCount ?? 0.0;
    Memory.lastSearch = currentQty.toString();
    final String? quantity = await openInputDialogWithResult(
      context,
      ref,
      false,
      title: 'Qty Count',
      value: currentQty.toString(),
      numberOnly: true,
    );

    if (quantity == null || quantity.isEmpty) return;

    final aux = double.tryParse(quantity);
    if (aux == currentQty) return;

    // English: Inventory allows zero, only negative is invalid.
    if (aux != null && aux >= 0) {
      final lineId = widget.inventoryLine.id ?? widget.index;
      ref.read(quantityOfInventoryLineToEditProvider.notifier).state = [
        lineId,
        aux,
      ];
      ref.read(updateInventoryLineIdProvider.notifier).state = lineId;
    } else {
      final message =
          '${Messages.ERROR_QUANTITY} ${aux == null ? Messages.EMPTY : quantity}';
      if (!mounted) return;
      showErrorMessage(context, ref, message);
    }

    ref.read(isDialogShowedProvider.notifier).state = false;
  }

  Future<void> _deleteLine() async {
    final lineId = widget.inventoryLine.id ?? -1;
    if (lineId <= 0) {
      showErrorMessage(context, ref, Messages.ERROR_LINE_NOT_DELETED);
      return;
    }

    final current = ref.read(inventoryAndLinesProvider);
    final isLastLine = (current.inventoryLines?.length ?? 0) == 1;
    final inventoryId = widget.inventoryLine.mInventoryID?.id ?? -1;

    final bool? confirm = await openBottomSheetConfirmationDialog(
      ref: ref,
      title: Messages.DELETE,
      subtitle: '${Messages.LINE} ${widget.inventoryLine.line ?? widget.index}',
      message: Messages.DO_YOU_WANT_REALY_TO_DELETE_LINE,
    );

    if (confirm != true) return;

    final req = DeleteRequest(
      lineId: lineId,
      headerIdToDelete: isLastLine && inventoryId > 0 ? inventoryId : null,
    );

    ref.read(deleteInventoryRequestProvider.notifier).state = req;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = ref.watch(editingInventoryLineProvider(_lineId));
    final qtyCountState = ref.watch(inventoryLineQuantityToCountProvider(_lineId));

    final qtyBook = Memory.numberFormatter0Digit.format(
      widget.inventoryLine.qtyBook ?? 0,
    );

    final qtyCount = Memory.numberFormatter0Digit.format(
      qtyCountState ?? widget.inventoryLine.qtyCount ?? 0,
    );

    final diff = ((qtyCountState ?? widget.inventoryLine.qtyCount ?? 0) -
        (widget.inventoryLine.qtyBook ?? 0))
        .toDouble();

    final diffString = Memory.numberFormatter0Digit.format(diff);

    final backGroundColor = Colors.cyan[800]!;
    final textStyleTitle = const TextStyle(
      fontSize: themeFontSizeNormal,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
    final textStyle = const TextStyle(
      fontSize: themeFontSizeSmall,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
    final textStyleTitleBlue = const TextStyle(
      fontSize: themeFontSizeNormal,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      backgroundColor: themeColorPrimary,
    );
    String att = '${widget.inventoryLine.mAttributeSetInstanceID?.identifier ?? '--'}'
        ' (${widget.inventoryLine.mAttributeSetInstanceID?.id ??''})';

    final int line = widget.inventoryLine.line?.toInt() ?? widget.index;
    double rowHeight = 25;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: backGroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Text(
            widget.inventoryLine.productName ??
                widget.inventoryLine.mProductID?.identifier ??
                '--',
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: widget.width / 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SizedBox(
                        height: rowHeight,
                        child: Text(Messages.ID, style: textStyleTitle)),
                    if (widget.canEdit)
                      GestureDetector(
                        onTap: _editQuantity,
                        child: Text('Qty Count', style: textStyleTitleBlue),
                      )
                    else
                      Text('Qty Count', style: textStyleTitle),
                    Text('Qty Book', style: textStyleTitle),
                    Text('Difference', style: textStyleTitle),
                    Text(Messages.LOCATOR, style: textStyleTitle),
                    Text(Messages.ATTRIBUET_INSTANCE, style: textStyleTitle),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: rowHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.inventoryLine.id ?? '--'}',
                              style: textStyleTitle,
                            ),
                          ),
                          Text(
                            '${Messages.LINE} : $line',
                            style: textStyleTitle,
                          ),
                          if (widget.canEdit)
                            IconButton(
                              onPressed: _deleteLine,
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              tooltip: Messages.DELETE,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),

                        ],
                      ),
                    ),


                    if (widget.canEdit)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              qtyCount,
                              style: textStyleTitle,
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: isEditing
                                ? const LinearProgressIndicator(minHeight: 24)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      )
                    else
                      Text(qtyCount, style: textStyleTitle),
                    Text(qtyBook, style: textStyleTitle),
                    Text(
                      diffString,
                      style: TextStyle(
                        fontSize: themeFontSizeNormal,
                        fontWeight: FontWeight.bold,
                        color: diff == 0 ? Colors.white : Colors.amber[200],
                      ),
                    ),
                    Text(
                      widget.inventoryLine.mLocatorID?.identifier ??
                          widget.inventoryLine.mLocatorID?.value ??
                          '--',
                      style: textStyleTitle,
                    ),
                    Text(
                      att,
                      style: textStyleTitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}