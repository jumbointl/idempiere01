
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_type.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../../config/constants/roles_app.dart';
import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/common_consumer_state.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/scan_button_by_action_fixed_short.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/sql/sql_data_movement_line.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/products_scan_notifier.dart';
import '../provider/new_movement_provider.dart';
import '../../store_on_hand/memory_products.dart';




class UnsortedStorageOnHandScreenForLine extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final IdempiereStorageOnHande storage;
  final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;
  int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE;
  MovementAndLines movementAndLines;
  String argument;

  UnsortedStorageOnHandScreenForLine({
    required this.index,
    required this.movementAndLines,
    required this.storage,
    required this.width,
    super.key,
    required this.argument,
  });

  @override
  ConsumerState<UnsortedStorageOnHandScreenForLine> createState() =>
      UnsortedStorageOnHandScreenForLineState();

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    late ProductsScanNotifier scanHandleNotifier =
    ref.read(scanHandleProvider.notifier);
    scanHandleNotifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }
}

class UnsortedStorageOnHandScreenForLineState
    extends CommonConsumerState<UnsortedStorageOnHandScreenForLine> {
  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) {
    // English: Delegate to the widget implementation to keep scan behavior in one place
    return widget.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }

  late List<IdempiereStorageOnHande> unsortedStorageList = [];
  late List<IdempiereStorageOnHande> storageList = [];
  late double widthLarge;
  late double widthSmall;

  late var quantityToMove;
  late double dialogHeight;
  late double dialogWidth;
  List<bool> isCardsSelected = [];
  @override
  double fontSizeMedium = 16;
  @override
  double fontSizeLarge = 22;
  late var actionScan;
  late var isLocatorScreenShowed;
  late IdempiereLocator? locatorTo;
  late var isScanning;
  late var isDialogShowed;
  late var scrollToTop;
  late var movementLinesToCreate;
  late ScrollController _scrollController;

  MovementAndLines get movementAndLines {
    if (widget.argument.isNotEmpty && widget.argument != '-1') {
      return MovementAndLines.fromJson(jsonDecode(widget.argument));
    } else {
      return widget.movementAndLines;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(actionScanProvider.notifier).update((state) =>
      Memory.ACTION_NO_SCAN_ACTION);
      await setDefaultValues(context, ref);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {
    // English: Ensure scan state is clean when opening this screen
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(quantityToMoveProvider.notifier).update((state) => 0);
    if(movementAndLines.hasMovement && movementAndLines.lastLocatorTo!=null){
      locatorTo = movementAndLines.lastLocatorTo;
      ref.read(selectedLocatorToProvider.notifier).state = movementAndLines.lastLocatorTo!;
    }
  }

  @override
  Widget build(BuildContext context) {

    actionScan = ref.watch(actionScanProvider.notifier);
    isScanning = ref.watch(isScanningLocatorToProvider.notifier);
    isDialogShowed = ref.watch(isDialogShowedProvider.notifier);
    widget.width = MediaQuery.of(context).size.width;
    quantityToMove = ref.watch(quantityToMoveProvider);
    scrollToTop = ref.watch(scrollToUpProvider.notifier);

    widthLarge = widget.width / 3 * 2;
    widthSmall = widget.width / 3;
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);
    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;

    storageList = unsortedStorageList
        .where((element) =>
    element.mLocatorID?.mWarehouseID?.id ==
        widget.storage.mLocatorID?.mWarehouseID?.id &&
        element.mProductID?.id == widget.storage.mProductID?.id &&
        element.mLocatorID?.id == widget.storage.mLocatorID?.id)
        .toList();
    int documentId = movementAndLines.cDocTypeID?.id ?? -1;
    IdempiereDocumentType? docType =  Memory.getDocumentTypeById(documentId);
    String title = Messages.UNEXPECTED_ERROR;
    if(docType!=null){
      title = docType.identifier ?? Messages.UNEXPECTED_ERROR;
    }

    if (isCardsSelected.isEmpty && storageList.isNotEmpty) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }

    final canCreate = RolesApp.canCreateMovementInSameOrganization ||
        RolesApp.canCreateDeliveryNote;
    final canShowBottomBar = ref.watch(canShowCreateLineBottomBarProvider);
    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionScanType));

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => {popScopeAction(context, ref)},
        ),
        actions: [
          if (showScan && canCreate)
            ScanButtonByActionFixedShort(
              actionTypeInt: widget.actionScanType,
              onOk: widget.handleInputString,
            ),
          if (showScan && canCreate)
            IconButton(
              icon: const Icon(Icons.keyboard, color: Colors.purple),
              onPressed: () => {
                openInputDialogWithAction(
                  ref: ref,
                  history: false,
                  actionScan: widget.actionScanType,
                  onOk: widget.handleInputString,
                )
              },
            ),
        ],
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      bottomNavigationBar: canShowBottomBar ? bottomAppBar(context, ref) : null,
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;
            popScopeAction(context, ref);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [

                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5,bottom: 5),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.storage.mProductID?.identifier ?? '--',
                          style: TextStyle(
                            fontSize: fontSizeMedium,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (canCreate) SliverToBoxAdapter(child: locatorFromCard(ref)),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: locatorToCard(ref),
                    ),
                  ),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: linesCard(ref),
                    ),
                  ),
                if (canCreate)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 5),
                    sliver: SliverToBoxAdapter(
                      child: quantityCard(ref),
                    ),
                  ),
                getStockList(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }


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
  Widget locatorFromCard(WidgetRef ref) {
    final locatorFrom = widget.storage.mLocatorID ?? IdempiereLocator();
    return sectionCard(
      color: locatorFrom.id == null || locatorFrom.id!<0 ? Colors.amber[50] : Colors.green[50],
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${Messages.FROM}: ${locatorFrom.value ?? locatorFrom.identifier ?? '--'}',
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
  }
  Widget locatorToCard(WidgetRef ref) {
    final locatorTo = ref.read(selectedLocatorToProvider);
    return sectionCard(
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
 Widget getStockList(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 5),
      sliver: SliverList.separated(
        itemBuilder: (BuildContext context, int index) {
          return storageOnHandCard(ref,storageList[index], index);
        },
        itemCount: storageList.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 5),
      ),
    );
  }
 /*
  Widget storageOnHandCard(IdempiereStorageOnHande storage, int index) {
    // English: Placeholder - keep your original card UI here
    return ListTile(
      title: Text(storage.mLocatorID?.value ?? ''),
      subtitle: Text(storage.mAttributeSetInstanceID?.identifier ?? ''),
      trailing: Text(Memory.numberFormatter0Digit.format(storage.qtyOnHand ?? 0)),
    );
  }
*/
  void popScopeAction(BuildContext context, WidgetRef ref) {
    FocusScope.of(context).unfocus();
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(quantityToMoveProvider.notifier).update((state) => 0);
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

    // English: Return to previous page (same behavior you had)
    Navigator.pop(context);
  }

  void showErrorMessage(BuildContext context, WidgetRef ref, String message) {
    if (!context.mounted) {
      Future.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
    }
    AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.error,
      body: Center(
        child: Column(
          children: [
            Text(
              message,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      title: message,
      desc: '',
      autoHide: const Duration(seconds: 3),
      btnOkOnPress: () {},
      btnOkColor: Colors.amber,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
    ).show();
  }
  Future<void> createMovementLineOnly() async {
    int movementId =movementAndLines.id ?? -1;
    if(movementId<=0){
      showErrorMessage(context, ref, Messages.MOVEMENT_ID);
      return ;
    }
    final lines = ref.watch(movementLinesProvider(widget.movementAndLines));
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
      movementLine.mMovementID = IdempiereMovement(id: movementId);
      if(movementLine.mMovementID==null || movementLine.mMovementID!.id==null){
        showErrorMessage(context, ref, Messages.ERROR_MOVEMENT);
        return;
      }
      movementLine.mLocatorID = widget.storage.mLocatorID;
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
      if(widget.argument.isNotEmpty){
        m = MovementAndLines.fromJson(jsonDecode(widget.argument));
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
      context.go(AppRouter.PAGE_CREATE_MOVEMENT_LINE,
          extra: m);
      /*await openMovementLinesCreateBottomSheet(
      context: context,
      ref: ref,
      movementAndLines: m,
      argument: argument,
      );*/
    }




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
}
