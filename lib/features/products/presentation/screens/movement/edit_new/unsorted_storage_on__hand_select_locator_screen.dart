
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common/code_and_fire_action_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/common/store_on_hand_navigation.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/async_value_consumer_screen_state.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/response_async_value.dart';
import '../../../../domain/idempiere/response_async_value_ui_model.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/store_on_hand/action_notifier.dart';
import '../../../widget/response_async_value_messages_card.dart';
import '../../locator/search_locator_dialog.dart';
import '../../store_on_hand/memory_products.dart';
import '../provider/new_movement_provider.dart';
import 'custom_app_bar.dart' hide fontSizeMedium;
/// English: Select 'Locator To' flow for a single movement line.
class UnsortedStorageOnHandSelectLocatorScreen extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final IdempiereStorageOnHande storage;
  final MovementAndLines movementAndLines;
  final int index;
  double width;

  /// English: Optional product UPC to show in UI (fallback uses storage).
  final String? productUPC;

  /// English: Encoded movement payload; if empty, movementAndLines is used.
  final String argument;

  /// English: Scan action used by this screen.
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE;

  UnsortedStorageOnHandSelectLocatorScreen({
    super.key,
    required this.index,
    required this.storage,
    required this.width,
    required this.movementAndLines,
    required this.argument,
    this.productUPC,
  });

  @override
  ConsumerState<UnsortedStorageOnHandSelectLocatorScreen> createState() =>
      UnsortedStorageOnHandScreenSelectLocatorState();

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    // English: This screen relies on the global scan handler.
    final notifier = ref.read(findLocatorToActionProvider);
    notifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }
}

class UnsortedStorageOnHandScreenSelectLocatorState
    extends AsyncValueConsumerState<UnsortedStorageOnHandSelectLocatorScreen> {
  // ---------- Local UI state ----------
  late MovementAndLines movementAndLines;
  late List<IdempiereStorageOnHande> storageList = <IdempiereStorageOnHande>[];
  List<bool> isCardsSelected = [];


  // ---------- AsyncValueConsumerState requirements ----------
  @override
  int get actionScanTypeInt => widget.actionScanType;


  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync {

    return ref.watch(mainNotifier.responseAsyncValueProvider);
  }

  @override
  double getWidth() => MediaQuery.of(context).size.width;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) => Colors.white;

  @override
  Future<void> setDefaultValuesOnInitState(BuildContext context, WidgetRef ref) async {
    movementAndLines = _resolveMovement();


  }
  double get _cardGap => 8;
  Widget sectionCard({required Color? color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }

  Widget quantityCard(WidgetRef ref) {
    final qty = ref.watch(quantityToMoveProvider);
    Color color = qty >0 ? Colors.green[50]! : Colors.grey[200]!;
    return sectionCard(
      color: color,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              Messages.QUANTITY_SHORT,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Memory.numberFormatter0Digit.format(qty),
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget linesCard(WidgetRef ref) {
    final lines = ref.watch(movementLinesProvider(movementAndLines));
    return sectionCard(
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              Messages.LINES,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextButton(
              style: TextButton.styleFrom(
                side: const BorderSide(color: Colors.black, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              onPressed: () async {
                final result = await openInputDialogWithResult(
                  context,
                  ref,
                  false,
                  value: lines.toInt().toString(),
                  title: Messages.LINES,
                  numberOnly: true,
                );
                final aux = double.tryParse(result ?? '') ?? 0;
                if (aux > 0) {
                  ref.read(movementLinesProvider(movementAndLines).notifier).state = aux;
                } else {
                  if (context.mounted) showErrorMessage(context,ref,Messages.ERROR_LINES);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  Memory.numberFormatter0Digit.format(lines),
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget unsortedStorageOnHandList(WidgetRef ref,List<IdempiereStorageOnHande> storageList) {
    if (storageList.isEmpty) {
      return sectionCard(
        color: Colors.grey[300],
        child: Text(Messages.NO_DATA_FOUND),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: storageList.length,
      separatorBuilder: (_, _) => SizedBox(height: cardGap),
      itemBuilder: (ctx, i) => storageOnHandCard(ref, storageList[i], i),
    );
  }
  Widget storageOnHandCard(WidgetRef ref, IdempiereStorageOnHande storage, int index) {
    final warehouse = ref.read(authProvider).selectedWarehouse;
    final int warehouseId = warehouse?.id ?? 0;

    final warehouseStorage = storage.mLocatorID?.mWarehouseID;
    final bool isSameWarehouse = (warehouseStorage?.id ?? 0) == warehouseId;

    final Color background = isSameWarehouse ? themeColorSuccessfulLight : themeColorGrayLight;

    final qtyOnHand = storage.qtyOnHand ?? 0;
    final quantity = Memory.numberFormatter0Digit.format(qtyOnHand);

    return GestureDetector(
      onTap: () {
        if (qtyOnHand <= 0) {
          showErrorMessage(ref.context, ref, '${Messages.ERROR_QUANTITY} $quantity');
          return;
        }
        setState(() {
          isCardsSelected = List<bool>.filled(storageList.length, false);
          isCardsSelected[index] = !isCardsSelected[index];
        });
        unfocus();

        getDoubleDialog(
          ref: ref,
          quantity: qtyOnHand,
          targetProvider: quantityToMoveProvider,
        );

      },
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: isCardsSelected[index] ? background : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Messages.WAREHOUSE_SHORT),
                  Text(Messages.LOCATOR_SHORT),
                  Text(Messages.QUANTITY_SHORT),
                  Text(Messages.ATTRIBUET_INSTANCE),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(warehouseStorage?.identifier ?? '--'),
                  Text(storage.mLocatorID?.value ?? '--', overflow: TextOverflow.ellipsis),
                  Text(
                    quantity,
                    style: TextStyle(color: qtyOnHand < 0 ? Colors.redAccent : Colors.black),
                  ),
                  Text(storage.mAttributeSetInstanceID?.identifier ?? '--', overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  void initialSettingAtBuild(BuildContext context, WidgetRef ref) {
    // English: Keep width updated.
    widget.width = MediaQuery.of(context).size.width;

    // English: Build storage list for current locator/product (same as before).
    final all = ref.read(unsortedStoreOnHandListProvider);
    storageList = all
        .where((e) =>
    e.mLocatorID?.mWarehouseID?.id == widget.storage.mLocatorID?.mWarehouseID?.id &&
        e.mProductID?.id == widget.storage.mProductID?.id &&
        e.mLocatorID?.id == widget.storage.mLocatorID?.id)
        .toList();

    if (isCardsSelected.length != storageList.length) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }
  }

  @override
  void executeAfterShown() {
    // English: Set locator-from context for provider filtering.
    final from = widget.storage.mLocatorID;
    ref.read(actualLocatorFromProvider.notifier).state = (from?.id ?? -1);
    final copyTo = ref.read(copyLastLocatorToProvider);
    if(!copyTo) {
      ref.invalidate(selectedLocatorToProvider);
    }

    ref.read(actionScanProvider.notifier).update((state) =>
    Memory.ACTION_GET_LOCATOR_TO_VALUE);
    // English: Align allowed warehouse to movement warehouseTo (same as your previous route logic).
    final int warehouseToId = movementAndLines.mWarehouseToID?.id ?? 0;
    ref.read(allowedWarehouseToProvider.notifier).state = warehouseToId;

    // English: Reset scanning/dialog flags.
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(isScanningProvider.notifier).state = false;

    // English: Optionally copy last locator-to into selectedLocatorToProvider.
    final copyLast = ref.read(copyLastLocatorToProvider);
    if (copyLast && movementAndLines.hasLastLocatorTo) {
      ref.read(selectedLocatorToProvider.notifier).state = movementAndLines.lastLocatorTo!;
    }
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    // English: Return to previous sheet/screen.
    unfocus();
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(isDialogShowedProvider.notifier).state = false;
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

    Navigator.of(context).pop();
  }

  @override
  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    final canShow = ref.watch(canShowCreateLineBottomBarProvider);
    if (!canShow) return null;

    return BottomAppBar(
      height: 70,
      color: themeColorPrimary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: _CreateLineSlider(
          onConfirm: () => _createMovementLineOnly(ref),
        ),
      ),
    );
  }

  // ---------- Async panels ----------
  @override
  Widget asyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {
    // English: Always use the animated message card for error/idle/empty states.
    late Widget resultCard ;
    final locatorTo = ref.read(selectedLocatorToProvider);

    if(!result.isInitiated){

      resultCard = sectionCard(
        color: locatorTo.id == null || locatorTo.id!<0 ? Colors.amber[50] : Colors.green[50],
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${Messages.TO}: ${locatorTo.value ?? locatorTo.identifier ?? '--'}',
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed:(){
                showDialog(
                  context: context,
                  builder: (_) {
                    return SearchLocatorDialog(
                      readOnly: false,
                      forCreateLine: false,
                    );
                  },
                );
              },
              icon: const Icon(Icons.search, color: Colors.purple),
            ),
          ],
        ),
      );

    } else {
      final ui = mapResponseAsyncValueToUi(
        result: result,
        title: Messages.LOCATOR_TO,
        subtitle: result.message ?? Messages.ERROR_LOCATOR_TO,
      );
      resultCard = Column(
        children: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) {
                  return SearchLocatorDialog(
                    readOnly: false,
                    forCreateLine: false,
                  );
                },
              );
            },
            icon: const Icon(Icons.search),
            label: Text(Messages.FIND_LOCATOR),
            style: TextButton.styleFrom(
              side: const BorderSide(
                color: Colors.blue, // cambiá al color que quieras
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),

          SizedBox(height: _cardGap),
          ResponseAsyncValueMessagesCardAnimated(ui: ui),
        ],
      );
    }



    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Movement header
        movementAppBarTitle(
          movementAndLines: movementAndLines,
          onBack: () => popScopeAction(context, ref),
          showBackButton: false,
          subtitle: '${Messages.LINES} : (${movementAndLines.movementLines?.length ?? 0})',
        ),
        const SizedBox(height: 10),

        // Product title
        sectionCard(
          color: Colors.blue[50],
          child: Text(
            widget.storage.mProductID?.identifier ?? '--',
            style: TextStyle(
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: _cardGap),
        _copyLastLocatorToCard(ref),
        SizedBox(height: _cardGap),

        // Locator To card (success)
        resultCard,
        SizedBox(height: _cardGap),

        // Quantity selector (uses provider)
        quantityCard(ref),
        SizedBox(height: _cardGap),

        // Lines selector (uses provider)
        linesCard(ref),
        SizedBox(height: _cardGap),

        // Stock list
        unsortedStorageOnHandList(ref,storageList),
      ],
    );
  }

  @override
  Widget asyncValueSuccessPanel(WidgetRef ref, {required ResponseAsyncValue result}) {
    // English: At this point data is a valid locator.
    final locatorTo = result.data as IdempiereLocator;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Movement header
        movementAppBarTitle(
          movementAndLines: movementAndLines,
          onBack: () => popScopeAction(context, ref),
          showBackButton: false,
          subtitle: '${Messages.LINES} : (${movementAndLines.movementLines?.length ?? 0})',
        ),
        const SizedBox(height: 10),

        // Product title
        sectionCard(
          color: Colors.blue[50],
          child: Text(
            widget.storage.mProductID?.identifier ?? '--',
            style: TextStyle(
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(height: _cardGap),
        _copyLastLocatorToCard(ref),
        SizedBox(height: _cardGap),

        // Locator To card (success)
        sectionCard(
          color: Colors.green[50],
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${Messages.TO}: ${locatorTo.value ?? locatorTo.identifier ?? '--'}',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed:(){
                  showDialog(
                    context: context,
                    builder: (_) {
                      return SearchLocatorDialog(
                        readOnly: false,
                        forCreateLine: false,
                      );
                    },
                  );
                },
                icon: const Icon(Icons.search, color: Colors.purple),
              ),
            ],
          ),
        ),
        SizedBox(height: _cardGap),

        // Quantity selector (uses provider)
        quantityCard(ref),
        SizedBox(height: _cardGap),

        // Lines selector (uses provider)
        linesCard(ref),
        SizedBox(height: _cardGap),

        // Stock list
        unsortedStorageOnHandList(ref,storageList),
      ],
    );
  }

  @override
  void afterAsyncValueAction(WidgetRef ref, {required ResponseAsyncValue result}) {
    // English: Mark locator-to as the last selected locator.
    //ref.read(actionScanProvider.notifier).state = actionScanTypeInt ;
    ref.read(isDialogShowedProvider.notifier).state = false ;
  }

  // ---------- UI pieces ----------


  // ---------- Actions ----------
  Future<void> _createMovementLineOnly(WidgetRef ref) async {
    // English: Minimal guardrails; keep your original logic if you have it.
    if (!movementAndLines.hasMovement) {
      showErrorMessage(context,ref,Messages.NO_MOVEMENT_SELECTED,durationSeconds: 0);
      return;
    }

    final locatorTo = ref.read(selectedLocatorToProvider);
    if (locatorTo.id == null || (locatorTo.id ?? 0) <= 0) {
      showErrorMessage(context,ref,Messages.ERROR_LOCATOR_TO,durationSeconds: 3);
      return;
    }
    int locatorToId = locatorTo.id ?? -1;

    final lines = ref.read(movementLinesProvider(movementAndLines));

    final qty = ref.read(quantityToMoveProvider);
    if (qty <= 0) {
      showErrorMessage(context,ref,Messages.ERROR_QUANTITY,durationSeconds: 0);
      return;
    }

    int movementId =movementAndLines.id ?? -1;
    if(movementId<=0){
      showErrorMessage(context, ref, Messages.MOVEMENT_ID);
      return ;
    }

    int locatorFrom = widget.storage.mLocatorID?.id ?? -1;
    if(locatorFrom<=0){
      showErrorMessage(context,ref,Messages.ERROR_LOCATOR_FROM,durationSeconds: 3);
      return;
    }

    if(movementId>0 && locatorFrom>0 && locatorToId>0) {
      SqlDataMovementLine movementLine = SqlDataMovementLine();
      Memory.sqlUsersData.copyToSqlData(movementLine);
      movementLine.mMovementID = movementAndLines;
      if (movementLine.mMovementID == null ||
          movementLine.mMovementID!.id == null) {
        showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
        return;
      }
      movementLine.mLocatorID = widget.storage.mLocatorID;
      if (movementLine.mLocatorID == null ||
          movementLine.mLocatorID!.id == null) {
        showErrorMessage(context, ref, Messages.ERROR_LOCATOR_FROM);
        return;
      }
      movementLine.mProductID = widget.storage.mProductID;
      if (movementLine.mProductID == null ||
          movementLine.mProductID!.id == null) {
        showErrorMessage(context, ref, Messages.ERROR_PRODUCT);
        return;
      }
      movementLine.mLocatorToID = locatorTo;
      if (movementLine.mLocatorToID == null ||
          movementLine.mLocatorToID!.id == null) {
        showErrorMessage(context, ref, Messages.ERROR_LOCATOR_TO);
        return;
      }
      movementLine.movementQty = ref.read(quantityToMoveProvider);
      if (movementLine.movementQty == null && movementLine.movementQty! <= 0) {
        showErrorMessage(context, ref, Messages.ERROR_QUANTITY);
        return;
      }
      movementLine.mAttributeSetInstanceID =
          widget.storage.mAttributeSetInstanceID;
      MemoryProducts.newSqlDataMovementLineToCreate = movementLine;
      movementLine.line = lines;
      MemoryProducts.movementAndLines.movementLineToCreate = movementLine;


      MovementAndLines m = MovementAndLines();
      if (widget.argument.isNotEmpty) {
        m = MovementAndLines.fromJson(jsonDecode(widget.argument));
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
      context.go(AppRouter.PAGE_CREATE_MOVEMENT_LINE,
          extra: m);

    }
  }

  // ---------- Helpers ----------
  MovementAndLines _resolveMovement() {
    if (widget.argument.isNotEmpty && widget.argument != '-1') {
      try {
        return MovementAndLines.fromJson(jsonDecode(widget.argument));
      } catch (_) {
        return widget.movementAndLines;
      }
    }
    return widget.movementAndLines;
  }



  @override
  Future<void> handleInputString({required WidgetRef ref,
    required String inputData, required int actionScan}) async {

    widget.handleInputString(ref: ref, inputData: inputData, actionScan: actionScan);

  }
  Widget _copyLastLocatorToCard(WidgetRef ref) {
    final lastLocatorTo = widget.movementAndLines.lastLocatorTo;
    final copyLastLocatorTo = ref.watch(copyLastLocatorToProvider);

    // English: Resolve last locator label (safe)
    final lastLabel = lastLocatorTo == null
        ? ''
        : (lastLocatorTo.value ?? lastLocatorTo.identifier ?? '');

    return sectionCard(
      color: Colors.grey[50],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // English: Checkbox aligned like a "leading" area
          SizedBox(
            width: 24,
            child: Center(
              child: Checkbox(
                value: copyLastLocatorTo,
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(copyLastLocatorToProvider.notifier).state = value;
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          // English: Title + subtitle stacked
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Messages.COPY_LAST_DATA,
                  style: TextStyle(
                    fontSize: fontSizeSmall,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (lastLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    lastLabel,
                    style: TextStyle(
                      fontSize: fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // English: "Copy now" action button (download icon)
          IconButton(
            tooltip: Messages.COPY_LAST_DATA,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.download, color: Colors.purple),
            onPressed: lastLocatorTo == null
                ? null
                : () {
              // English: Force-apply last locator to selection
              ref.read(selectedLocatorToProvider.notifier).state = lastLocatorTo;

              // English: Rebuild current state if needed
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  // TODO: implement mainNotifier
  CodeAndFireActionNotifier get mainNotifier => ref.read(findLocatorToActionProvider);


/*Widget _copyLastLocatorToCard(WidgetRef ref) {
    final lastLocatorTo = widget.movementAndLines.lastLocatorTo;
    final copyLastLocatorTo = ref.watch(copyLastLocatorToProvider);
    double trailingWidth = 60;
    return ListTile(
      dense: true,
      leading: SizedBox(
        width: trailingWidth,
        child: Center(
          child: Checkbox(
            value: copyLastLocatorTo,
            onChanged: (value) {
              if (value == null) return;
              ref.read(copyLastLocatorToProvider.notifier).state = value;
            },
          ),
        ),

      ),
      title: Text(Messages.COPY_LAST_DATA,
        style: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      subtitle: Text( lastLocatorTo == null  ? '' :
        lastLocatorTo.value ?? lastLocatorTo.identifier ?? '',
        style: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
      trailing: IconButton(
        padding: EdgeInsets.zero, // Eliminar padding para alinear
        icon: const Icon(Icons.download, color: Colors.purple),
        onPressed: () {
          // acción opcional extra si quieres forzar copia manual
          if(lastLocatorTo == null) return ;

          ref.read(selectedLocatorToProvider.notifier).state =
              lastLocatorTo;
          setState(() {

          });
        },
      ),
    );

  }*/
}

/// English: Small wrapper so we keep BottomAppBar readable.
class _CreateLineSlider extends StatelessWidget {
  final VoidCallback onConfirm;

  const _CreateLineSlider({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return ConfirmationSlider(
      height: 45,
      backgroundColor: Colors.green[100]!,
      backgroundColorEnd: Colors.green[800]!,
      foregroundColor: Colors.green,
      text: Messages.SLIDE_TO_CREATE_LINE,
      textStyle: TextStyle(
        fontSize: themeFontSizeLarge,
        fontWeight: FontWeight.bold,
        color: Colors.purple,
      ),
      onConfirmation: onConfirm,
    );
  }
}

