import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/features/products/common/async_value_consumer_simple_state.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:monalisa_app_001/features/products/common/input_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/create/movement_create_validation_result.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../providers/actions/find_locator_to_action_provider.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/store_on_hand/action_notifier.dart';
import '../../locator/search_locator_dialog.dart';
import '../provider/new_movement_provider.dart';
import 'movements_create_screen.dart';

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
    final notifier = ref.read(findLocatorToActionProvider);
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
    ref.read(isDialogShowedProvider.notifier).update((state) => false);
    ref.read(actionScanProvider.notifier).state = actionScanTypeInt;
    ref.invalidate(selectedLocatorToProvider);
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
    // English: Reset key providers before leaving
    unfocus();
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(quantityToMoveProvider.notifier).state = 0;
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

    // English: Defer navigation to avoid Navigator lock during gesture/build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final router = GoRouter.of(context);

      if (router.canPop()) {
        router.pop();
        return;
      }

      final productId = widget.storage.mProductID?.id ?? -1;
      context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productId');

    });
  }

  // ---------- Main UI ----------
  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    final canCreate = RolesApp.appMovementComplete || RolesApp.appMovementconfirmComplete;

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

            await openMovementCreateBottomSheet(
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

  Future<void> openMovementCreateBottomSheet({
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
          child: MovementsCreateScreen(
            putAwayMovement: putAwayMovement,
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
          maxValue: qtyOnHand,
          minValue: 1,
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
      data: (result) {
        ResponseAsyncValue response  = result ;
        if(!response.isInitiated){
          String title= Messages.WAIT_FOR_SEARCH ;
          return ListTile(
            leading: GestureDetector(
              onTap: () {
                // English: Open locator search dialog
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
              title,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            trailing: const Icon(Icons.error, color: Colors.red),
          );
        } else if(!response.success) {
          String title = result.message ?? Messages.NO_DATA_FOUND;

            return ListTile(
              leading: GestureDetector(
                onTap: () {
                  // English: Open locator search dialog
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
                title,
                style: TextStyle(
                  fontSize: fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              trailing: const Icon(Icons.error, color: Colors.red),
            );
        }  else if(response.data == null){
          String title = result.message ?? Messages.NO_DATA_FOUND;

          return ListTile(
            leading: GestureDetector(
              onTap: () {
                // English: Open locator search dialog

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
              title,
              style: TextStyle(
                fontSize: fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            trailing: const Icon(Icons.error, color: Colors.red),
          );

        }



        final IdempiereLocator locator = ref.read(selectedLocatorToProvider);
        // English: When locatorTo is valid, sync PutAway movement targets
        if (locator.id != null && locator.id! > 0) {
          putAwayMovement!.movementLineToCreate!.mLocatorToID = locator;
          putAwayMovement!.movementToCreate!.mWarehouseToID = locator.mWarehouseID;
        }

        return ListTile(
          leading: GestureDetector(
            onTap: () {
              // English: Open locator search dialog

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
            (locator.id != null) ? (locator.value ?? '') : (locator.identifier ?? ''),
            style: TextStyle(
              fontSize: fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          trailing: (locator.id != null && locator.id! > 0)
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
        separatorBuilder: (_, _) => const SizedBox(height: 5),
      ),
    );
  }

  @override
  Future<void> handleInputString({required WidgetRef ref,
    required String inputData, required int actionScan}) async {
    widget.handleInputString(ref: ref, inputData: inputData, actionScan: actionScan);

  }
}


