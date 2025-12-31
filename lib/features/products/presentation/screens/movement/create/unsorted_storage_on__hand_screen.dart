import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/features/products/common/async_value_consumer_simple_state.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/common/input_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/create/putAway_validation_result.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../locator/search_locator_dialog.dart';
import '../provider/new_movement_provider.dart';
import '../provider/products_home_provider.dart';
import 'models/put_away_create_flow_fiew.dart';

class UnsortedStorageOnHandScreen extends ConsumerStatefulWidget
    implements InputDataProcessor {
  final IdempiereStorageOnHande storage;
  final int index;

  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;

  double width;
  final int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE;

  String? productUPC;

  UnsortedStorageOnHandScreen({
    required this.index,
    required this.storage,
    required this.width,
    this.productUPC,
    super.key,
  });

  @override
  ConsumerState<UnsortedStorageOnHandScreen> createState() =>
      UnsortedStorageOnHandScreenState();

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    // English: Delegate scanning input handling to the shared notifier
    final notifier = ref.read(scanHandleNotifierProvider.notifier);
    notifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }
}

class UnsortedStorageOnHandScreenState
    extends AsyncValueConsumerSimpleState<UnsortedStorageOnHandScreen> {
  // ---------- Local screen state ----------
  List<IdempiereStorageOnHande> unsortedStorageList = [];
  List<IdempiereStorageOnHande> storageList = [];

  List<bool> isCardsSelected = [];

  @override
  double fontSizeMedium = 16;
  @override
  double fontSizeLarge = 22;

  double widthLarge = 0;
  double widthSmall = 0;

  double dialogHeight = 0;
  double dialogWidth = 0;

  PutAwayMovement? putAwayMovement;

  IdempiereLocator? locatorFrom;

  // English: We keep the AsyncValue coming from provider (locatorTo lookup)
  late AsyncValue findLocatorTo;

  // English: Cached provider values used in widgets
  late double quantityToMove;

  // ---------- Overrides from base ----------
  @override
  bool get showLeading => true;

  @override
  bool get scrollMainDataCard =>
      false; // English: Main card is already scrollable (CustomScrollView)

  @override
  int get actionScanTypeInt => widget.actionScanType;

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync =>
      const AsyncLoading(); // English: Not used in this screen (base doesn't depend on it)

  @override
  double getWidth() => MediaQuery.of(context).size.width;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.white;
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    final title = ref.read(movementCreateScreenTitleProvider);
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  @override
  Future<void> setDefaultValuesOnInitState(
      BuildContext context,
      WidgetRef ref,
      ) async {
    // English: Initialize PutAway movement structure
    putAwayMovement = PutAwayMovement();
    putAwayMovement!.setUser(Memory.sqlUsersData);

    // English: Ensure org link is consistent (some models need org propagation)
    final org = widget.storage.mLocatorID!.aDOrgID!;
    widget.storage.mLocatorID!.mWarehouseID!.aDOrgID = org;

    locatorFrom = widget.storage.mLocatorID;

    putAwayMovement!.movementLineToCreate!.mProductID = widget.storage.mProductID;
    putAwayMovement!.movementLineToCreate!.mLocatorID = locatorFrom;

    putAwayMovement!.movementToCreate!.locatorFromId = locatorFrom!.id;
    putAwayMovement!.movementToCreate!.mWarehouseID = locatorFrom!.mWarehouseID;
  }

  @override
  void executeAfterShown() {
    // English: After first frame, store "from locator" in provider
    final id = locatorFrom?.id ?? -1;
    ref.read(actualLocatorFromProvider.notifier).state = id;
  }

  @override
  void initialSettingOnBuild(BuildContext context, WidgetRef ref) {
    widget.width = MediaQuery.of(context).size.width;

    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;

    widthLarge = widget.width / 3 * 2;
    widthSmall = widget.width / 3;

    quantityToMove = ref.watch(quantityToMoveProvider);

    // English: Input data (list) comes from provider
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);

    // English: Filter stock list for same warehouse + same product + same locator
    storageList = unsortedStorageList
        .where((e) =>
    e.mLocatorID?.mWarehouseID?.id ==
        widget.storage.mLocatorID?.mWarehouseID?.id &&
        e.mProductID?.id == widget.storage.mProductID?.id &&
        e.mLocatorID?.id == widget.storage.mLocatorID?.id)
        .toList();

    if (isCardsSelected.isEmpty && storageList.isNotEmpty) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }

    // English: Keep locatorFrom synced
    locatorFrom = widget.storage.mLocatorID;

    // English: LocatorTo lookup async value
    findLocatorTo = ref.watch(findLocatorToProvider);
  }

  @override
  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    final canShowBottomBar = ref.watch(canShowCreateLineBottomBarProvider);
    if (!canShowBottomBar) return null;
    return bottomAppBar(context, ref);
  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) {
    // English: Reset key providers before leaving
    unfocus();
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(quantityToMoveProvider.notifier).state = 0;
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_STORE_ON_HAND;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

    // English: Return to previous screen
    Navigator.pop(context);
  }

  // ---------- Main UI ----------
  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    final canCreate = RolesApp.canCreateMovementInSameOrganization ||
        RolesApp.canCreateDeliveryNote;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          if (canCreate) SliverToBoxAdapter(child: getMovementCard(context, ref)),
          if (canCreate)
            SliverPadding(
              padding: const EdgeInsets.only(top: 5),
              sliver: SliverToBoxAdapter(
                child: _productHeaderCard(),
              ),
            ),
          if (canCreate)
            SliverPadding(
              padding: const EdgeInsets.only(top: 5),
              sliver: SliverToBoxAdapter(
                child: _quantityCard(),
              ),
            ),
          getStockList(context, ref),
        ],
      ),
    );
  }

  Widget _productHeaderCard() {
    return Container(
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
    );
  }

  Widget _quantityCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Memory.numberFormatter0Digit.format(quantityToMove),
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

  // ---------- Bottom bar ----------
  BottomAppBar bottomAppBar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
      height: 70,
      color: themeColorPrimary,
      child: ConfirmationSlider(
        height: 45,
        backgroundColor: Colors.green[100]!,
        backgroundColorEnd: Colors.green[800]!,
        foregroundColor: Colors.green,
        text: Messages.SLIDE_TO_CREATE,
        textStyle: TextStyle(
          fontSize: themeFontSizeLarge,
          color: Colors.purple,
          fontWeight: FontWeight.bold,
        ),
        onConfirmation: () async {
          // English: Validate doc type before creating movement
            if (putAwayMovement != null &&
              putAwayMovement!.movementLineToCreate != null) {
            putAwayMovement!.movementLineToCreate!.movementQty =
                ref.read(quantityToMoveProvider);

            final check = putAwayMovement!.canCreatePutAwayMovement();
            final ui = mapPutAwayCheckToUi(check);

            if (!ui.ok) {
              showErrorMessage(context, ref, ui.message);
              return;
            }

            await showPutAwayCreateBottomSheet(
            context: ref.context,
            putAwayMovement: putAwayMovement!,
            );

            return;


          }

          showErrorMessage(context, ref, Messages.MOVEMENT_ALREADY_CREATED);
        },
      ),
    );
  }
  Future<void> showPutAwayCreateBottomSheet({
    required BuildContext context,
    required PutAwayMovement putAwayMovement,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: PutAwayCreateFlowView(
            putAwayMovement: putAwayMovement,
            closeMode: PutAwayCloseMode.closeOnly,
          ),
        );
      },
    );
  }


  // ---------- Cards ----------
  Widget storageOnHandCard(IdempiereStorageOnHande storage, int index) {
    final warehouse = ref.read(authProvider).selectedWarehouse;
    final warehouseID = warehouse?.id ?? 0;

    final warehouseStorage = storage.mLocatorID?.mWarehouseID;
    final background = (warehouseStorage?.id == warehouseID)
        ? widget.colorSameWarehouse
        : widget.colorDifferentWarehouse;

    final warehouseName = warehouseStorage?.identifier ?? '--';
    final qtyOnHand = storage.qtyOnHand ?? 0;
    final quantity = Memory.numberFormatter0Digit.format(qtyOnHand);

    return GestureDetector(
      onTap: () {
        if (qtyOnHand <= 0) {
          final message = '${Messages.ERROR_QUANTITY} $quantity';
          showErrorMessage(context, ref, message);
          return;
        }

        // English: Toggle selection and open quantity dialog
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(warehouseName),
                    Text(
                      storage.mLocatorID?.value ?? '--',
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      quantity,
                      style: TextStyle(
                        color: qtyOnHand < 0 ? Colors.redAccent : Colors.black,
                      ),
                    ),
                    Text(
                      storage.mAttributeSetInstanceID?.identifier ?? '--',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showErrorMessage(BuildContext context, WidgetRef ref, String message) {
    // English: Avoid showing dialogs if widget is disposed
    if (!context.mounted) return;

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

  // ---------- Movement card ----------
  Widget getMovementCard(BuildContext context, WidgetRef ref) {
    // English: Color depends on fixed locatorFrom
    final color = ref.watch(movementColorProvider(locatorFrom));

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: SizedBox(
              width: 60,
              child: Text(
                '${Messages.FROM} ${Messages.LOCATOR}',
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            title: Text(
              locatorFrom?.value ?? Messages.LOCATOR_FROM,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            trailing: Icon(
              Icons.check_circle,
              color: widget.storage.mLocatorID != null ? Colors.green : Colors.red,
            ),
          ),
          getLocatorTo(context, ref),
        ],
      ),
    );
  }

  Widget getLocatorTo(BuildContext context, WidgetRef ref) {
    return findLocatorTo.when(
      data: (locator) {
        // English: When locatorTo is valid, sync PutAway movement targets
        if (locator != null && locator.id != null && locator.id! > 0) {
          putAwayMovement!.movementLineToCreate!.mLocatorToID = locator;
          putAwayMovement!.movementToCreate!.mWarehouseToID = locator.mWarehouseID;
        }

        return ListTile(
          leading: GestureDetector(
            onTap: () {
              // English: Open locator search dialog
              Memory.pageFromIndex =
                  ref.read(productsHomeCurrentIndexProvider.notifier).state;
              ref
                  .read(productsHomeCurrentIndexProvider.notifier)
                  .state = Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN;

              showDialog(
                context: context,
                builder: (_) {
                  return SearchLocatorDialog(
                    searchLocatorFrom: false,
                    forCreateLine: false,
                  );
                },
              );
            },
            child: SizedBox(
              width: 60,
              child: Text(
                '${Messages.TO} ${Messages.LOCATOR}',
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ),
          title: Text(
            (locator?.id != null) ? (locator?.value ?? '') : (locator?.identifier ?? ''),
            style: TextStyle(
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          trailing: (locator?.id != null && locator!.id! > 0)
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.error, color: Colors.red),
        );
      },
      error: (error, stackTrace) {
        return Text(
          Messages.ERROR,
          style: TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 16),
    );
  }

  // ---------- Stock list ----------
  Widget getStockList(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 5),
      sliver: SliverList.separated(
        itemBuilder: (context, index) {
          return storageOnHandCard(storageList[index], index);
        },
        itemCount: storageList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 5),
      ),
    );
  }

  @override
  Future<void> handleInputString({required WidgetRef ref,
    required String inputData, required int actionScan}) async {
    final notifier = ref.read(scanHandleNotifierProvider.notifier);
    notifier.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }
}




/*

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/common/input_dialog.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action_fixed_short.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_organization.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../../domain/idempiere/put_away_movement.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../locator/search_locator_dialog.dart';
import '../provider/products_home_provider.dart';
import '../provider/new_movement_provider.dart';
class UnsortedStorageOnHandScreen extends ConsumerStatefulWidget implements InputDataProcessor{

  final IdempiereStorageOnHande storage;
  final int index;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  double width;
  final int pageIndex = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
  final int actionScanType = Memory.ACTION_GET_LOCATOR_TO_VALUE;
  String? productUPC ;
  late var notifier;



  UnsortedStorageOnHandScreen({
    required this.index,
    required this.storage,
    required this.width,
    this.productUPC,
    super.key});


  @override
  ConsumerState<UnsortedStorageOnHandScreen> createState() =>UnsortedStorageOnHandScreenState();

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData,
    required int actionScan}) async {
    notifier.handleInputString(ref:ref, inputData:inputData,actionScan:actionScan);

  }

}

class UnsortedStorageOnHandScreenState extends ConsumerState<UnsortedStorageOnHandScreen> {
  late List<IdempiereStorageOnHande> unsortedStorageList = [];
  late List<IdempiereStorageOnHande> storageList = [];
  late double widthLarge ;
  late double widthSmall ;

  late AsyncValue findLocatorTo ;

  late var usePhoneCamera ;
  late var quantityToMove;
  late double dialogHeight ;
  late double dialogWidth ;
  List<bool> isCardsSelected = [];
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
  PutAwayMovement? putAwayMovement;


  @override
  void initState() {


    WidgetsBinding.instance.addPostFrameCallback((_){
      final id = locatorFrom?.id ?? -1;
      ref.read(actualLocatorFromProvider.notifier).state = id;
      //ref.read(allowedWarehouseToProvider.notifier).state = 0;
    });
    super.initState();
    putAwayMovement = PutAwayMovement();
    putAwayMovement!.setUser(Memory.sqlUsersData);
    putAwayMovement!.movementLineToCreate!.mProductID = widget.storage.mProductID;
    IdempiereOrganization org = widget.storage.mLocatorID!.aDOrgID!;
    widget.storage.mLocatorID!.mWarehouseID!.aDOrgID = org;
    putAwayMovement!.movementLineToCreate!.mLocatorID = widget.storage.mLocatorID;

    locatorFrom = widget.storage.mLocatorID;

    putAwayMovement!.movementToCreate!.locatorFromId = locatorFrom.id;
    putAwayMovement!.movementToCreate!.mWarehouseID = locatorFrom.mWarehouseID;




  }

  @override
  Widget build(BuildContext context) {

    final allowedMovementDocumentType = ref.read(allowedMovementDocumentTypeProvider);

    print('allowedMovementDocumentType $allowedMovementDocumentType');
    widget.notifier = ref.read(scanHandleNotifierProvider.notifier);
    locatorFrom = widget.storage.mLocatorID;
    locatorTo = ref.watch(selectedLocatorToProvider.notifier);
    findLocatorTo = ref.watch(findLocatorToProvider);
    actionScan = ref.watch(actionScanProvider.notifier);
    isScanning = ref.watch(isScanningLocatorToProvider.notifier);
    isDialogShowed = ref.watch(isDialogShowedProvider.notifier);
    widget.width = MediaQuery.of(context).size.width;
    quantityToMove = ref.watch(quantityToMoveProvider);
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    scrollToTop = ref.watch(scrollToUpProvider.notifier);


    widthLarge = widget.width/3*2;
    widthSmall = widget.width/3;
    unsortedStorageList = ref.read(unsortedStoreOnHandListProvider);
    dialogHeight = MediaQuery.of(context).size.height;
    dialogWidth = MediaQuery.of(context).size.width;

    storageList = unsortedStorageList
        .where((element) =>
    element.mLocatorID?.mWarehouseID?.id ==
        widget.storage.mLocatorID?.mWarehouseID?.id &&
        element.mProductID?.id == widget.storage.mProductID?.id &&
        element.mLocatorID?.id == widget.storage.mLocatorID?.id )
        .toList();
    final String title = ref.read(movementCreateScreenTitleProvider);

    if (isCardsSelected.isEmpty && storageList.isNotEmpty) {
      isCardsSelected = List<bool>.filled(storageList.length, false);
    }
    final canCreate = RolesApp.canCreateMovementInSameOrganization || RolesApp.canCreateDeliveryNote;
    final canShowBottomBar = ref.watch(canShowCreateLineBottomBarProvider);
    final showScan = ref.watch(showScanFixedButtonProvider(widget.actionScanType));
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
            if(showScan && canCreate) ScanButtonByActionFixedShort(actionTypeInt: widget.actionScanType,
              onOk: widget.handleInputString,),
            if(showScan && canCreate) IconButton(
              icon: const Icon(Icons.keyboard,color: Colors.purple),
              onPressed: () => {
                openInputDialogWithAction(ref: ref, history: false, actionScan: widget.actionScanType,
                    onOk: widget.handleInputString)
              },
            ),

          ],
          title: Text(title,style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,),),


        ),
        bottomNavigationBar: canShowBottomBar ? bottomAppBar(context, ref): null,

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
                      if(canCreate)SliverToBoxAdapter(child: getMovementCard(context, ref)),
                      if(canCreate)SliverPadding(
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

                      if(canCreate)SliverPadding(
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
      child: ConfirmationSlider(
          height: 45,
          backgroundColor: Colors.green[100]!,
          backgroundColorEnd: Colors.green[800]!,
          foregroundColor: Colors.green,
          text: Messages.SLIDE_TO_CREATE,
          textStyle: TextStyle(fontSize: themeFontSizeLarge, color: Colors.purple,fontWeight: FontWeight.bold),
          onConfirmation: () {
            print('----------------------------ConfirmationSlide');
            final allowedDocumentType = ref.read(allowedMovementDocumentTypeProvider);
            if(allowedDocumentType!=Memory.MM_ELECTRONIC_DELIVERY_NOTE_ID &&
                allowedDocumentType!=Memory.NO_MM_ELECTRONIC_DELIVERY_NOTE_ID){
              showErrorMessage(context, ref, '${Messages.ERROR_DOCUMENT_TYPE} : $allowedDocumentType');
              return;

            }
            print('allowedDocumentType--to create----------$allowedDocumentType');

            if (putAwayMovement!=null && putAwayMovement!.movementLineToCreate!=null) {
              putAwayMovement!.movementLineToCreate!.movementQty = ref.read(quantityToMoveProvider);
              int check = putAwayMovement!.canCreatePutAwayMovement();
              switch (check) {
                case PutAwayMovement.ERROR_START_CREATE:
                  showErrorMessage(ref.context, ref, Messages.ERROR_START_CREATE);
                  return;
                case PutAwayMovement.ERROR_LOCATOR_TO:
                  showErrorMessage(ref.context, ref, Messages.ERROR_LOCATOR_TO);
                  return;
                case PutAwayMovement.ERROR_LOCATOR_FROM:
                  showErrorMessage(ref.context, ref, Messages.ERROR_LOCATOR_FROM);
                  return;
                case PutAwayMovement.ERROR_SAME_LOCATOR:
                  showErrorMessage(ref.context, ref, Messages.ERROR_SAME_LOCATOR);
                  return;
                case PutAwayMovement.ERROR_QUANTITY:
                  showErrorMessage(ref.context, ref, Messages.ERROR_QUANTITY);
                  return;
                case PutAwayMovement.ERROR_WAREHOUSE_FROM:
                  showErrorMessage(ref.context, ref, Messages.ERROR_WAREHOUSE_FROM);
                  return;
                case PutAwayMovement.ERROR_WAREHOUSE_TO:
                  showErrorMessage(ref.context, ref, Messages.ERROR_WAREHOUSE_TO);
                  return;
                case PutAwayMovement.ERROR_ORG_WAREHOUSE_FROM:
                  showErrorMessage(ref.context, ref, Messages.ERROR_ORG_WAREHOUSE_FROM);
                  return;
                case PutAwayMovement.ERROR_ORG_WAREHOUSE_TO:
                  showErrorMessage(ref.context, ref, Messages.ERROR_ORG_WAREHOUSE_TO);
                  return;
                case PutAwayMovement.ERROR_DOCUMENT_TYPE:
                  showErrorMessage(ref.context, ref, Messages.ERROR_DOCUMENT_TYPE);
                  return;
                case PutAwayMovement.ERROR_PRODUCT:
                  showErrorMessage(ref.context, ref, Messages.ERROR_PRODUCT);
                  return;
                case PutAwayMovement.ERROR_MOVEMENT:
                  showErrorMessage(ref.context, ref, Messages.ERROR_MOVEMENT);
                  return;
                case PutAwayMovement.ERROR_MOVEMENT_LINE:
                  showErrorMessage(ref.context, ref, Messages.ERROR_MOVEMENT_LINE);
                  return;
                case PutAwayMovement.SUCCESS:
                  GoRouter.of(ref.context).go(AppRouter.PAGE_CREATE_PUT_AWAY_MOVEMENT,
                      extra: putAwayMovement);
                  break;
                case PutAwayMovement.ERROR_MOVEMENT_NULL:
                  showErrorMessage(ref.context, ref, Messages.ERROR_MOVEMENT_NULL);
                  return;
                default:
                  showErrorMessage(ref.context, ref, '${Messages.ERROR} : $check');
                  return;

              }

            } else {
              showErrorMessage(context, ref, Messages.MOVEMENT_ALREADY_CREATED);

            }
          }

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
        getDoubleDialog(ref:  ref, quantity:  qtyOnHand ?? 0,
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


  void showErrorMessage(BuildContext context, WidgetRef ref, String message) {
    if (!context.mounted) {
      Future.delayed(const Duration(seconds: 1));
      if(!context.mounted) return;
    }
    AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.error,
      body: Center(child: Column(
        children: [
          Text(message,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),),
      title:  message,
      desc:   '',
      autoHide: const Duration(seconds: 3),
      btnOkOnPress: () {},
      btnOkColor: Colors.amber,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
    ).show();
    return;
  }


  Widget getMovementCard(BuildContext context, WidgetRef ref) {

    // 👇 Provider recebe o locatorFrom fixo
    final color       = ref.watch(movementColorProvider(locatorFrom));


    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: Colors.black, // Specify the border color
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
              leading: SizedBox(
                width: 60,
                child: Text('${Messages.FROM} ${Messages.LOCATOR}',
                  style: TextStyle(
                    fontSize: fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,),textAlign: TextAlign.start,),
              ),
              title: Text(locatorFrom.value ??
                  Messages.LOCATOR_FROM,style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,),),
              trailing: Icon(Icons.check_circle,color:
              widget.storage.mLocatorID != null ?
              Colors.green : Colors.red,)
          ),
          getLocatorTo(context, ref),

        ],
      ),


    );
  }

  Widget getLocatorTo(BuildContext context, WidgetRef ref) {

    return findLocatorTo.when(
      data: (locator) {

        if(locator!=null && locator.id!=null && locator.id!>0){

          putAwayMovement!.movementLineToCreate!.mLocatorToID = locator;
          putAwayMovement!.movementToCreate!.mWarehouseToID = locator?.mWarehouseID ;
        }


        WidgetsBinding.instance.addPostFrameCallback((_) async {
        });
        return ListTile(
          leading: GestureDetector(
            onTap: (){

              Memory.pageFromIndex = ref.read(productsHomeCurrentIndexProvider.notifier).state;
              ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_NO_REQUERED_SCAN_SCREEN);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SearchLocatorDialog(
                    searchLocatorFrom :false,
                    forCreateLine: false,
                  );
                },
              );

            },
            child: SizedBox(
              width: 60,
              child: Text('${Messages.TO} ${Messages.LOCATOR}',
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,),textAlign: TextAlign.start,),
            ),
          ),
          title: Text(locator.id != null ?locator.value ??''
              : locator.identifier ?? '',style:TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: Colors.purple,)),
          trailing:locator.id != null
              && locator.id! > 0 ?
          Icon(Icons.check_circle,color: Colors.green,) :
          Icon(Icons.error,color: Colors.red,),

        );
      },
      error: (error, stackTrace) {
        return Text(Messages.ERROR,style:TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.bold,
          color: Colors.red,));
      },
      loading: () => LinearProgressIndicator(minHeight: 16,),
    );


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
    print('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productUPC');
    //context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productUPC');
    Navigator.pop(context);



  }

}


// Clasecita interna solo para organizar datos de los botones
*/


