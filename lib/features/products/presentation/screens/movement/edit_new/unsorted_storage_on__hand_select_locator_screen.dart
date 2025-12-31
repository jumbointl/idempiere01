
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/store_on_hand_navigation.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

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
import '../../../widget/response_async_value_messages_card.dart';
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
    debugPrint('UnsortedStorageOnHandSelectLocatorScreen.handleInputString');
    debugPrint('inputData: $inputData');
    debugPrint('actionScan: $actionScan');
    if(inputData.isEmpty) return ;
    final notifier = ref.read(scanHandleNotifierProvider.notifier);
    notifier.handleInputString(ref: ref, inputData: inputData, actionScan: actionScan);
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

    return ref.watch(findLocatorToProvider);
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
      separatorBuilder: (_, __) => SizedBox(height: cardGap),
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

        // English: Ask quantity using the shared numeric input bottom sheet.
        () async {
          final result = await openInputDialogWithResult(
            context,
            ref,
            false,
            value: qtyOnHand.toInt().toString(),
            title: Messages.QUANTITY_SHORT,
            numberOnly: true,
          );
          final aux = double.tryParse(result ?? '') ?? 0;
          if (aux > 0 && aux <= qtyOnHand) {
            ref.read(quantityToMoveProvider.notifier).state = aux;
          } else {
            if (context.mounted) _showErrorMessage(Messages.ERROR_QUANTITY);
          }
        }();
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
          ],
        ),
      );

    } else {
      final ui = mapResponseAsyncValueToUi(
        result: result,
        title: Messages.LOCATOR_TO,
        subtitle: result.message ?? Messages.ERROR_LOCATOR_TO,
      );
      resultCard = ResponseAsyncValueMessagesCardAnimated(ui: ui);
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
      _showErrorMessage(Messages.NO_MOVEMENT_SELECTED);
      return;
    }

    final locatorTo = ref.read(selectedLocatorToProvider);
    if (locatorTo.id == null || (locatorTo.id ?? 0) <= 0) {
      showAutoCloseErrorDialog(context,ref,Messages.ERROR_LOCATOR_TO,3);
      return;
    }
    int locatorToId = locatorTo.id ?? -1;

    final lines = ref.read(movementLinesProvider(movementAndLines));

    final qty = ref.read(quantityToMoveProvider);
    if (qty <= 0) {
      _showErrorMessage(Messages.ERROR_QUANTITY);
      return;
    }

    print('----------------------------ConfirmationSlide');
    int movementId =movementAndLines.id ?? -1;
    if(movementId<=0){
      showErrorMessage(context, ref, Messages.MOVEMENT_ID);
      return ;
    }

    int locatorFrom = widget.storage.mLocatorID?.id ?? -1;
    if(locatorFrom<=0){
      showAutoCloseErrorDialog(context,ref,Messages.ERROR_LOCATOR_FROM,3);
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
      String argument = jsonEncode(m.toJson());
      /*context.go('${AppRouter.PAGE_CREATE_MOVEMENT_LINE}/$argument',
          extra: m);*/
      await openMovementLinesCreateBottomSheet(
        context: context,
        ref: ref,
        movementAndLines: m,
        argument: argument,
      );
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

  void _showErrorMessage(String message) {
    if (!context.mounted) return;
    AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.error,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(message, style: const TextStyle(fontStyle: FontStyle.italic)),
        ),
      ),
      title: Messages.ERROR,
      desc: '',
      autoHide: const Duration(seconds: 3),
      btnOkOnPress: () {},
      btnOkColor: Colors.amber,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
    ).show();
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


/*
class UnsortedStorageOnHandSelectLocatorScreen extends ConsumerStatefulWidget implements InputDataProcessor {

  final IdempiereStorageOnHande storage;
  final MovementAndLines movementAndLines;
  final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;
  final int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE;
  String? productUPC;

  String? argument;


  UnsortedStorageOnHandSelectLocatorScreen({
    required this.index,
    required this.storage,
    required this.width,
    this.productUPC,
    required this.movementAndLines,

    super.key, required String argument});


  @override
  ConsumerState<UnsortedStorageOnHandSelectLocatorScreen> createState() =>
      UnsortedStorageOnHandScreenSelectLocatorState();

  @override
  Future<void> handleInputString(
      {required WidgetRef ref, required String inputData, required int actionScan}) async {
    final scanHandleNotifier = ref.read(scanHandleNotifierProvider.notifier);
    scanHandleNotifier.handleInputString(
        ref: ref, inputData: inputData, actionScan: actionScan);
  }
}
class UnsortedStorageOnHandScreenSelectLocatorState extends ConsumerState<UnsortedStorageOnHandSelectLocatorScreen> {
  late List<IdempiereStorageOnHande> unsortedStorageList = [];
  late List<IdempiereStorageOnHande> storageList = [];
  late double widthLarge ;
  late double widthSmall ;

  late AsyncValue findLocatorTo ;
  late var isLocatorScreenShowed;
  late var usePhoneCamera ;
  late var quantityToMove;
  late double dialogHeight ;
  late double dialogWidth ;
  List<bool> isCardsSelected = [];
  double fontSizeSmall = 12;
  double fontSizeMedium = 16;
  double fontSizeLarge = 22;
  late var actionScan ;
  bool goToMovementsScreenWithMovementId = false;
  bool showErrorDialog = false;
  final ScrollController _scrollController = ScrollController();
  late var scrollToTop  ;
  late var locatorTo;
  late var locatorFrom ;
  late var isScanning ;
  late var isDialogShowed;
  bool searched = false ;
  double goToPosition =0.0;
  late MovementAndLines movementAndLines;
  late var lines ;
  bool showScanButton = false;
  String? productId ;
  late var copyLastLocatorTo ;
  late var documentColor;
  double trailingWidth = 60;
  late var movementColor ;

  @override
  void initState() {
    super.initState();
    movementAndLines = widget.movementAndLines;



    WidgetsBinding.instance.addPostFrameCallback((_) async {

      final from = widget.storage.mLocatorID;

      final int id = from?.id ?? -1;

      await Future.delayed(const Duration(milliseconds: 100),(){
        ref.read(actualLocatorFromProvider.notifier).state = id;
        //ref.read(actionScanProvider.notifier).state = 5;
        ref.read(isDialogShowedProvider.notifier).state = false;
        int warehouseToID = movementAndLines.mWarehouseToID?.id ?? 0;
        ref.read(allowedWarehouseToProvider.notifier).state = warehouseToID;
        if(copyLastLocatorTo){
          if(movementAndLines.hasLastLocatorTo){
            ref.read(selectedLocatorToProvider.notifier).state = movementAndLines.lastLocatorTo!;
          }
        } else {
          //ref.invalidate(scannedLocatorToProvider);
          //ref.invalidate(selectedLocatorToProvider);
        }


      });




    });
  }


  @override
  Widget build(BuildContext context) {
    actionScan = ref.watch(actionScanProvider);
    copyLastLocatorTo = ref.watch(copyLastLocatorToProvider);


    locatorFrom = widget.storage.mLocatorID ;

    productId = widget.movementAndLines.nextProductIdUPC ;

    lines = ref.watch(movementLinesProvider(widget.movementAndLines));

    findLocatorTo = ref.watch(findLocatorToProvider);
    locatorTo = ref.watch(selectedLocatorToProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);
    isScanning = ref.watch(isScanningProvider);

    widget.width = MediaQuery.of(context).size.width;
    quantityToMove = ref.watch(quantityToMoveProvider);
    usePhoneCamera = ref.watch(usePhoneCameraToScanForLineProvider);
    scrollToTop = ref.watch(scrollToUpProvider);

    widthLarge = widget.width/3*2;
    widthSmall = widget.width/3;
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);
    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionScanType));
    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;
    isDialogShowed = ref.watch(isDialogShowedProvider);
    storageList = unsortedStorageList
        .where((element) =>
    element.mLocatorID?.mWarehouseID?.id ==
        widget.storage.mLocatorID?.mWarehouseID?.id &&
        element.mProductID?.id == widget.storage.mProductID?.id &&
        element.mLocatorID?.id == widget.storage.mLocatorID?.id )
        .toList();


    if (isCardsSelected.isEmpty && storageList.isNotEmpty) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }

    final canShowBottomBar = ref.watch(canShowCreateLineBottomBarProvider);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
          {
            popScopeAction(context,ref),

          }
        ),
        actions: [
          if(showScan) ScanButtonByActionFixedShort(
            actionTypeInt: widget.actionScanType,
            onOk: widget.handleInputString,),
          if(showScan) IconButton(
            icon: const Icon(Icons.keyboard,color: Colors.purple),
            onPressed: () => {
              openInputDialogWithAction(ref: ref, history: false,
                  onOk: widget.handleInputString, actionScan:  widget.actionScanType)
            },
          ),
        ],
        title: movementAppBarTitle(movementAndLines: movementAndLines,
            onBack: ()=> popScopeAction,
            showBackButton: false,
            subtitle: '${Messages.LINES} : (${movementAndLines.movementLines?.length ?? 0})'
        ),


      ),
        bottomNavigationBar:  canShowBottomBar ?  bottomAppBar(context, ref) :null,
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {

              return;
            }
            popScopeAction(context,ref);

          },
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: getMovementCard(context, ref)),
                  SliverPadding(
                    padding: EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(widget.storage.mProductID?.identifier ?? '--',style: TextStyle(
                          fontSize: fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,),),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(
                            color: Colors.black, // Specify the border color
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            Expanded(
                              flex: 1, // Use widthSmall for this column's width
                              child: Column(
                                spacing: 5,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(Messages.QUANTITY_SHORT,style: TextStyle(
                                    fontSize: fontSizeMedium,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,),),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2, // Use widthLarge for this column's width
                              child: Column(
                                spacing: 5,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(Memory.numberFormatter0Digit.format(quantityToMove),
                                    style: TextStyle(
                                      fontSize: fontSizeMedium,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),),

                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(
                            color: Colors.black, // Specify the border color
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            Expanded(
                              flex: 1, // Use widthSmall for this column's width
                              child: Column(
                                spacing: 5,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(Messages.LINES,style: TextStyle(
                                    fontSize: fontSizeMedium,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,),),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2, // Use widthLarge for this column's width
                              child: Column(
                                spacing: 5,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                          side: BorderSide(color: Colors.black, width: 1), // Add border here
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5)),
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(50, 30),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          alignment: Alignment.centerLeft),
                                      onPressed: () async {

                                        String? result = await openInputDialogWithResult(
                                            context, ref, false,value: lines,
                                          title: Messages.LINES,numberOnly: true);
                                        double aux = double.tryParse(result ??'') ?? 0;
                                        if (aux > 0) {
                                          ref.read(movementLinesProvider(widget.movementAndLines).notifier)
                                              .state = aux;
                                        } else {
                                          if(context.mounted)showErrorMessage(context, ref, Messages.ERROR_LINES);
                                        }

                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(Memory.numberFormatter0Digit.format(lines),
                                          style: TextStyle(
                                            fontSize: fontSizeMedium,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),),
                                      ),
                                    ),
                                  ),

                                ],
                              ),
                            ),

                          ],
                        ),

                      ),
                    ),
                  ),
                  getStockList(context,ref),


              ]),
          )
        ),
        )
      );
  }

  Widget bottomAppBar(BuildContext context, WidgetRef ref) {

    return BottomAppBar(
      height: 70,
      color: themeColorPrimary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ConfirmationSlider(
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
          onConfirmation: () {
            if (!movementAndLines.hasMovement) {
              showErrorMessage(context, ref, Messages.NO_MOVEMENT_SELECTED);
              return;
            }
            createMovementLineOnly();
          },
        ),
      ),
    );
  }

  Widget storageOnHandCard(IdempiereStorageOnHande storage,int index) {
    final warehouse = ref.read(authProvider).selectedWarehouse;
    int warehouseID = warehouse?.id ?? 0;
    IdempiereLocator warehouseLocator = storage.mLocatorID!;
    IdempiereWarehouse? warehouseStorage = storage.mLocatorID?.mWarehouseID;
    Color background = warehouseStorage?.id == warehouseID ? widget.colorSameWarehouse : widget.colorDifferentWarehouse;
    String warehouseName = warehouseStorage?.identifier ?? '--';
    double qtyOnHand = storage.qtyOnHand ?? 0;
    String quantity = Memory.numberFormatter0Digit.format(qtyOnHand) ;
    return GestureDetector(
      onTap: () {
        if( qtyOnHand<=0){
          String message =  '${Messages.ERROR_QUANTITY} $quantity';
          showErrorMessage(context, ref, message);
          return;

        }
        // Handle tap event here
        setState(() { // Use setState to trigger a rebuild when isSelected changes
          isCardsSelected = List<bool>.filled(storageList.length, false);
           isCardsSelected[index] = !isCardsSelected[index]; // Update the corresponding index in isCardsSelected
        });
        FocusScope.of(context).unfocus();
        getDoubleDialog(ref:  ref,
            quantity: storage.qtyOnHand ?? 0,
            targetProvider: quantityToMoveProvider,
        );
      },
      child: Container(
        //margin: EdgeInsets.all(5),
        width: widget.width,
        decoration: BoxDecoration(
          color: isCardsSelected[index] ? background : Colors.grey[200], // Change background color based on isSelected
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1, // Use widthLarge for this column's width
                child: Column(
                  spacing: 5,
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
                flex: 2, // Use widthLarge for this column's width
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(warehouseName),
                    Text(widget.storage.mLocatorID?.value ?? '--', overflow: TextOverflow.ellipsis),
                    Text(
                      quantity,
                      style: TextStyle(
                        color: qtyOnHand < 0 ? Colors.redAccent : Colors.black,
                      ),
                    ),
                    Text(widget.storage.mAttributeSetInstanceID?.identifier ?? '--', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget getMovementCard(BuildContext context, WidgetRef ref) {

    IdempiereLocator? lastLocatorTo = movementAndLines.lastLocatorTo;
    if(lastLocatorTo != null){
      lastLocatorTo.value ??= lastLocatorTo.identifier;
    }
    Color color = ref.watch(colorLocatorProvider);

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black, // Specify the border color
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
            //spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              ListTile(
                dense: true,

                leading: SizedBox(
                  width: trailingWidth,
                  child: Text('${Messages.FROM} ${Messages.LOCATOR}',
                    style: TextStyle(
                      fontSize: fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,),textAlign: TextAlign.start,),
                ),
                title: Text(locatorFrom.value ??
                     Messages.LOCATOR_FROM,style: TextStyle(
                  fontSize: fontSizeSmall,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,),),
                trailing: SizedBox(
                  width: 48.0, // Ancho estándar de un IconButton
                  height: 48.0, // Alto estándar de un IconButton
                  child: Center(
                    child: Icon(Icons.check_circle, color: widget.storage.mLocatorID != null ? Colors.green : Colors.red),
                  ),
                ),
              ),

              if(lastLocatorTo != null)
                ListTile(
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
                  subtitle: Text(
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
                      ref.read(selectedLocatorToProvider.notifier).state =
                          lastLocatorTo;
                      setState(() {

                      });
                    },
                  ),
                ),
              getLocatorTo(context, ref),

            ],
          ),


    );
  }

  Widget getLocatorTo(BuildContext context, WidgetRef ref) {


    return findLocatorTo.when(
      data: (locatorFromFuture) {
        IdempiereLocator locator;
        if (locatorTo.id != Memory.INITIAL_STATE_ID) {
          print('Hay locator elegido manualmente');
          // Hay locator elegido manualmente (LocatorCard)
          locator = locatorTo;
        } else {
          print('No Hay locator elegido manualmente locatorFromFuture');
          // Usar el que viene del escaneo / FutureProvider
          locator = locatorFromFuture;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) async {

        });
        return ListTile(
          dense: true,
          leading: GestureDetector(
            onTap: (){
              bool forCreateLine = false ;
              ref.read(findingCreateLinLocatorToProvider.notifier).state = forCreateLine;
              Memory.pageFromIndex = ref.read(productsHomeCurrentIndexProvider.notifier).state;
              ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SearchLocatorDialog(
                    searchLocatorFrom :false,
                    forCreateLine: forCreateLine,
                  );
                },
              );

            },
            child: SizedBox(
              width: trailingWidth,
              child: Text('${Messages.TO} ${Messages.LOCATOR}',
                style: TextStyle(
                  fontSize: fontSizeSmall,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,),textAlign: TextAlign.start,),
            ),
          ),
          */
/*title: Text(this.locatorTo.id != null ? this.locatorTo.value ??''
              : this.locatorTo.identifier ?? '',style:TextStyle(
            fontSize: fontSizeSmall,
            fontWeight: FontWeight.bold,
            color: Colors.purple,)),*//*

          title: Text(locator.id != null ?locator.value ??''
              : locator.identifier ?? '',style:TextStyle(
            fontSize: fontSizeSmall,
            fontWeight: FontWeight.bold,
            color: Colors.purple,)),
          trailing:locator.id != null
              && locator.id! > 0
              ? const SizedBox(width: 48.0, height: 48.0, child: Center(child: Icon(Icons.check_circle, color: Colors.green)))
              : const SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: Center(child: Icon(Icons.error, color: Colors.red)),
                ),

        );
      },
      error: (error, stackTrace) {
        return Text(Messages.ERROR,style:TextStyle(
        fontSize: fontSizeSmall,
        fontWeight: FontWeight.bold,
        color: Colors.red,));
      },
      loading: () => LinearProgressIndicator(minHeight: 16,),
    );


  }

  void createMovementLineOnly() {
    print('----------------------------ConfirmationSlide');
    int movementId =movementAndLines.id ?? -1;
    if(movementId<=0){
      showErrorMessage(context, ref, Messages.MOVEMENT_ID);
      return ;
    }

    int locatorFrom = widget.storage.mLocatorID?.id ?? -1;
    if(locatorFrom<=0){
      showAutoCloseErrorDialog(context,ref,Messages.ERROR_LOCATOR_FROM,3);
      return;
    }
    int locatorTo = this.locatorTo?.id ?? -1;
    if(locatorTo<=0){
      showAutoCloseErrorDialog(context,ref,Messages.ERROR_LOCATOR_TO,3);
      return;
    }
    if(movementId>0 && locatorFrom>0 && locatorTo>0){
      SqlDataMovementLine movementLine = SqlDataMovementLine();
      Memory.sqlUsersData.copyToSqlData(movementLine);
      movementLine.mMovementID = movementAndLines;
      if(movementLine.mMovementID==null || movementLine.mMovementID!.id==null){
        showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
        return;
      }
      movementLine.mLocatorID = widget.storage.mLocatorID ;
      if(movementLine.mLocatorID==null || movementLine.mLocatorID!.id==null){
        showErrorMessage(context, ref, Messages.ERROR_LOCATOR_FROM);
        return;
      }
      movementLine.mProductID = widget.storage.mProductID;
      if(movementLine.mProductID==null || movementLine.mProductID!.id==null){
        showErrorMessage(context, ref, Messages.ERROR_PRODUCT);
        return;
      }
      movementLine.mLocatorToID = this.locatorTo;
      if(movementLine.mLocatorToID==null || movementLine.mLocatorToID!.id==null){
        showErrorMessage(context, ref, Messages.ERROR_LOCATOR_TO);
        return;
      }
      movementLine.movementQty = ref.read(quantityToMoveProvider);
      if(movementLine.movementQty==null && movementLine.movementQty!<=0){
        showErrorMessage(context, ref, Messages.ERROR_QUANTITY);
        return;
      }
      movementLine.mAttributeSetInstanceID = widget.storage.mAttributeSetInstanceID;
      MemoryProducts.newSqlDataMovementLineToCreate = movementLine;
      movementLine.line = lines;
      MemoryProducts.movementAndLines.movementLineToCreate = movementLine;


      MovementAndLines m = MovementAndLines();
      if(widget.argument!= null && widget.argument!.isNotEmpty){
        m = MovementAndLines.fromJson(jsonDecode(widget.argument!));
        if(!m.hasMovement){
          showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
          return;
        }
      } else {
        m = movementAndLines;
        if(!m.hasMovement){
          showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
          return;
        }
      }
      m.movementLineToCreate = movementLine;
      MemoryProducts.movementAndLines = m;
      String argument = m.id.toString() ?? '-1';
      context.go('${AppRouter.PAGE_CREATE_MOVEMENT_LINE}/$argument',
          extra: m);

    }




  }
  Widget getStockList(BuildContext context, WidgetRef ref) {

    return SliverPadding(
      padding: EdgeInsets.only(top: 5),
      sliver: SliverList.separated(
        itemBuilder: (BuildContext context, int index) {
            return storageOnHandCard(storageList[index], index);
          },
        itemCount: storageList.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 5,),
      ),
    );
  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(quantityToMoveProvider.notifier).update((state) => 0);
    ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_STORE_ON_HAND);
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
    String productUPC = widget.storage.mProductID?.identifier ?? '-1';
    productUPC = productUPC.split('_').first;
    print('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/$productUPC');

    Navigator.pop(context);


  }

}

*/
