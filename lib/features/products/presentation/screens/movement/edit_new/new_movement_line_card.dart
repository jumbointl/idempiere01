import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/delete_request.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../providers/product_provider_common.dart';
import '../provider/new_movement_provider.dart';

class NewMovementLineCard extends ConsumerStatefulWidget {
  late final IdempiereMovementLine movementLine;
  final double width;
  final int index;
  final int totalLength;
  bool? showLocators = false;
  final bool canEdit;

  var productsNotifier;
  NewMovementLineCard( {required this.width, required this.movementLine, super.key,
    required this.index, required this.totalLength, this.showLocators, required this.canEdit});


  @override
  ConsumerState<NewMovementLineCard> createState() => NewMovementLineCardState();
}

class NewMovementLineCardState extends ConsumerState<NewMovementLineCard> {
  bool _resultHandled = false;

  late AsyncValue<double?> quantityAsync;
  late AsyncValue<bool?> deleteAsync;
  late var quantityToMove;
  ProviderSubscription<DeleteRequest?>? _deleteTriggerSub;
  ProviderSubscription<int?>? _updateTriggerSub;

  ProviderSubscription<AsyncValue<bool?>>? _deleteOpSub;
  ProviderSubscription<AsyncValue<double?>>? _updateOpSub;
  late var isScanning;

  int get _lineId => widget.movementLine.id ?? -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = widget.movementLine.movementQty ?? 0.0;
      ref
          .read(movementLineQuantityToMoveProvider(_lineId).notifier)
          .state = initial;
    });
    _attachManualListeners();
  }

  @override
  void didUpdateWidget(covariant NewMovementLineCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambia el lineId (ej. reutilización de widget en list), reatach listeners
    final oldId = oldWidget.movementLine.id ?? -1;
    if (oldId != _lineId) {
      _disposeManualListeners();
      _attachManualListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final initial = widget.movementLine.movementQty ?? 0.0;
        ref
            .read(movementLineQuantityToMoveProvider(_lineId).notifier)
            .state = initial;
      });
    }
  }


  void _attachManualListeners() {
    // 1) Trigger delete
    _deleteTriggerSub = ref.listenManual<DeleteRequest?>(
      deleteRequestProvider,
          (prev, next) {
        if (next == null) return;
        if (next.lineId != _lineId) return;
        ref
            .read(editingMovementLineProvider(_lineId).notifier)
            .state = true;
        _deleteOpSub?.close();
        _deleteOpSub = ref.listenManual<AsyncValue<bool>>(
          deleteMovementLineProvider(next),
              (p, n) {


            n.whenOrNull(
              data: (deleted) async {
                _deleteOpSub?.close();
                _deleteOpSub = null;


                ref.read(deleteRequestProvider.notifier).state = null;
                ref.read(editingMovementLineProvider(_lineId).notifier).state = false;
                if (deleted != true) {
                  print('deleteMovementLineProvider error');
                  if (!mounted) return;
                  showErrorMessage(context, ref, Messages.ERROR_LINE_NOT_DELETED);
                  return;
                }else{
                  print('deleteMovementLineProvider success');
                  late String route;
                  final id = widget.movementLine.mMovementID?.id ?? 1;
                  final counter = ref.read(movementLineDeletedCounterProvider);
                  route = '${AppRouter.PAGE_MOVEMENT_REPAINT}${counter%2}/$id';
                  ref.read(movementLineDeletedCounterProvider.notifier).state++;
                  print('route: $route');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    GoRouter.of(context).go(route); // mejor que context.go en estos casos
                  });

                  return;
                }



              },
              error: (e, st) {
                _deleteOpSub?.close();
                _deleteOpSub = null;
                ref.read(deleteRequestProvider.notifier).state = null;
                ref.read(editingMovementLineProvider(_lineId).notifier).state = false;
                if (!mounted) return;
                showErrorMessage(context, ref, Messages.ERROR_LINE_NOT_DELETED);
                debugPrint('DELETE Dio error: ${e.toString()}');
              },
            );
          },
        );
      },
    );

    // 2) Trigger update qty
    _updateTriggerSub = ref.listenManual<int?>(
      updateMovementLineIdProvider,
          (prev, next) {
        if (next != _lineId) return;
        ref
            .read(editingMovementLineProvider(_lineId).notifier)
            .state = true;
        _updateOpSub?.close();
        _updateOpSub = ref.listenManual<AsyncValue<double?>>(
          editQuantityToMoveProvider(_lineId),
              (p, n) {

            n.whenOrNull(
              data: (result) {
                // limpiar triggers + cerrar one-shot
                ref
                    .read(updateMovementLineIdProvider.notifier)
                    .state = null;
                ref
                    .read(quantityOfLineToEditProvider.notifier)
                    .state = null;
                ref
                    .read(editingMovementLineProvider(_lineId).notifier)
                    .state = false;


                _updateOpSub?.close();
                _updateOpSub = null;

                if (result == null) return;

                final isSuccess = result > 0;
                if (isSuccess) {
                  widget.movementLine.movementQty = result;
                  ref
                      .read(
                      movementLineQuantityToMoveProvider(_lineId).notifier)
                      .state = result;
                  // ✅ repintar esta card (para que el texto cambie)
                  if (mounted) {
                    String message = Messages.UPDATED_QUANTITY;
                    showSuccessMessage(context, ref, message);
                    setState(() {
                      _resultHandled = false;
                    });
                  }
                  widget.movementLine.movementQty = result ;
                  // ✅ opcional: sincronizar movementAndLinesProvider (recomendado)
                  final m = ref.read(movementAndLinesProvider);
                  final lines = List<IdempiereMovementLine>.from(
                      m.movementLines ?? const []);
                  final idx = lines.indexWhere((e) => (e.id ?? -1) == _lineId);
                  if (idx >= 0) {
                    lines[idx].movementQty = result;
                    m.movementLines = lines;
                    ref
                        .read(movementAndLinesProvider.notifier)
                        .state = m;
                  }
                }
              },

              error: (_, __) {
                ref
                    .read(updateMovementLineIdProvider.notifier)
                    .state = null;
                ref
                    .read(quantityOfLineToEditProvider.notifier)
                    .state = null;
                ref
                    .read(editingMovementLineProvider(_lineId).notifier)
                    .state = false;
                _updateOpSub?.close();
                _updateOpSub = null;
                if (!mounted) return;
                showErrorMessage(context, ref, Messages.ERROR_UPDATE_QUANTITY);
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

  @override
  Widget build(BuildContext context) {

    isScanning = ref.watch(editingMovementLineProvider(_lineId));
    quantityToMove = ref.watch(movementLineQuantityToMoveProvider(_lineId));
   /* String categoryName = widget.movementLine.mProductID?.mProductCategoryID?.identifier ?? 'category null';
    String categoryId = widget.movementLine.mProductID?.mProductCategoryID?.id?.toString() ?? 'category id null';
    print('categoryName $categoryId : $categoryName');*/



    widget.productsNotifier =
        ref.watch(scanStateNotifierForLineProvider.notifier);
    String quantity = Memory.numberFormatter0Digit.format(
        widget.movementLine.movementQty ?? 0);
    Color backGroundColor = Colors.cyan[800]!;
    TextStyle textStyleTitle = TextStyle(fontSize: themeFontSizeNormal,
        color: Colors.white,
        fontWeight: FontWeight.bold);
    TextStyle textStyle = TextStyle(fontSize: themeFontSizeSmall,
        color: Colors.white,
        fontWeight: FontWeight.bold);
    TextStyle textStyleTitleBlue = TextStyle(
        fontSize: themeFontSizeNormal, color: Colors.white,
        fontWeight: FontWeight.bold, backgroundColor: themeColorPrimary);
    int line = widget.movementLine.line?.toInt() ?? 0;
    return Container(
      //height: height,
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
              widget.movementLine.productName ?? '--', style: textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 2
          ),
          Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: widget.width / 5,


                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Messages.ID, style: textStyleTitle),
                    if(widget.canEdit)
                      GestureDetector(
                        onTap: () async {
                          double qty = widget.movementLine.movementQty ?? 0;
                          String? quantity = await openInputDialogWithResult
                            (context, ref, false,
                              title: Messages.QUANTITY_TO_MOVE,
                              value: qty.toString(),
                              numberOnly: true);

                          if (quantity == null || quantity.isEmpty) {
                            //String message = '${Messages.ERROR_QUANTITY} ${Messages.EMPTY}';
                            //if(context.mounted) showErrorMessage(context, ref, message);
                            return;
                          }

                          double? aux = double.tryParse(quantity);
                          if (qty == aux) return;
                          if (aux != null && aux >= 0) {
                            _resultHandled = false;
                            final int lineId = widget.movementLine.id ??
                                widget.index;
                            if (aux == 0) {
                              bool? delete = await openBottomSheetConfirmationDialog(
                                  ref: ref,
                                  title: Messages.DELETE,
                                  subtitle: '${Messages.QUANTITY_TO_MOVE} = 0',
                                  message: Messages
                                      .DO_YOU_WANT_REALY_TO_DELETE_LINE);
                              if (delete == true) {
                                final lineId = widget.movementLine.id ?? -1;
                                final movementId = widget.movementLine.mMovementID?.id ?? -1;

                                final m = ref.read(movementAndLinesProvider);
                                final isLastLine = (m.movementLines?.length ?? 0) == 1;

                                final req = DeleteRequest(
                                  lineId: lineId,
                                  movementIdToDelete: isLastLine ? movementId : null,
                                );

                                ref.read(deleteRequestProvider.notifier).state = req;
                                //ref.refresh(deleteMovementLineProvider(req));
                              }
                            } else {
                              print('edit quantity $aux');
                              ref
                                  .read(quantityOfLineToEditProvider.notifier)
                                  .state = [lineId, aux];
                              print('edit quantity ${ref.read(quantityOfLineToEditProvider)}');
                              ref
                                  .read(updateMovementLineIdProvider.notifier)
                                  .state = lineId;
                              print('edit quantity ${ref.read(updateMovementLineIdProvider)}');

                              //ref.refresh(editQuantityToMoveProvider(lineId));
                              //print('edit quantity ${ref.read(editQuantityToMoveProvider(lineId))}');
                            }
                          } else {
                            String message = '${Messages
                                .ERROR_QUANTITY} ${aux == null
                                ? Messages.EMPTY
                                : quantity}';
                            if (context.mounted) {
                              showErrorMessage(
                                  context, ref, message);
                            }
                            return;
                          }
                          ref
                              .read(isDialogShowedProvider.notifier)
                              .state = false;
                        },
                        child: Text(
                            Messages.QUANTITY_SHORT, style: textStyleTitleBlue),
                      )
                    else
                      Text(Messages.QUANTITY_SHORT, style: textStyleTitle),
                    Text(Messages.UPC, style: textStyleTitle),
                    Text(Messages.SKU, style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(
                        Messages.FROM, style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(
                        Messages.TO, style: textStyleTitle),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('${widget.movementLine.id ?? '--'}',
                              style: textStyleTitle),
                        ),
                        SizedBox(
                          width: 150,
                          child:Text('${Messages.LINE} : $line', style: textStyleTitle),
                        )
                      ],
                    ),
                    widget.canEdit ? Row(
                      children: [
                        Expanded(
                            child: Text(quantityToMove?.toString() ?? '',
                                style: textStyleTitle)

                        ),
                        SizedBox(
                          width: 150,
                          child: isScanning ?
                          const LinearProgressIndicator(minHeight: 36)
                              : const SizedBox.shrink(),
                        )
                      ],
                    ) : Text(quantity, style: textStyleTitle),
                    Text(
                        widget.movementLine.uPC ?? '--', style: textStyleTitle),
                    Text(
                        widget.movementLine.sKU ?? '--', style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(
                        widget.movementLine.mLocatorID?.identifier ?? '--',
                        style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(
                        widget.movementLine.mLocatorToID?.identifier ?? '--',
                        style: textStyleTitle),
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

