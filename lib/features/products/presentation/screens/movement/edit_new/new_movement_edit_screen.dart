import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/common_screen_state.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_confirm.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/domain/entities/warehouse.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/persitent_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../widget/movement_no_data_card.dart';
import 'new_movement_card_with_locator.dart';
import 'new_movement_line_card.dart';


class NewMovementEditScreen extends ConsumerStatefulWidget {

  int countScannedCamera =0;
  final int actionTypeInt = Memory.ACTION_FIND_MOVEMENT_BY_ID;
  late var allowedLocatorId;
  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;
  String? movementId;
  bool isMovementSearchedShowed = false;
  final String fromPage;


  static const String WAIT_FOR_SCAN_MOVEMENT='-1';

  static const String FROM_PAGE_HOME ='-1';
  static const String FROM_PAGE_MOVEMENT_LIST ='1';


  NewMovementEditScreen({
    required this.fromPage,
    this.movementId,super.key});


  @override
  ConsumerState<ConsumerStatefulWidget> createState() => NewMovementEditScreenState();

  void confirmMovementButtonPressed(BuildContext context, WidgetRef ref, String string) {

  }

  void lastMovementButtonPressed(BuildContext context, WidgetRef ref, String lastSearch) {}

  void findMovementButtonPressed(BuildContext context, WidgetRef ref, String s) {}

  void newMovementButtonPressed(BuildContext context, WidgetRef ref, String s) {}


}

class NewMovementEditScreenState extends CommonConsumerState<NewMovementEditScreen> {
  IdempiereMovement? movement ;
  IdempiereLocator? lastSavedLocatorFrom;
  Color colorBackgroundHasMovementId = Colors.cyan[200]!;
  Color colorBackgroundNoMovementId = Colors.white;
  int sameLocator = 0;
  final double singleProductDetailCardHeight = 160;
  Warehouse? userWarehouse;
  late var movementAndLines ;
  int movementId =-1;
  @override
  late var isDialogShowed;
  late String fromPage;




  @override
  Future<void> executeAfterShown() async {


    await setDefaultValues(context, ref);

    if( widget.movementId != null &&  widget.movementId!.isNotEmpty && widget.movementId != '-1'){
      while(!context.mounted){
        Future.delayed(Duration(milliseconds: 100), () {});
      }
      print('search ${widget.movementId}');
      final productsNotifier = ref.read(scanStateNotifierForLineProvider.notifier);
      productsNotifier.addBarcodeToSearchMovementNew(widget.movementId!);
    }



  }

  @override
  double getWidth(){ return MediaQuery.of(context).size.width - 30;}




  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return getColorByMovementAndLines(movementAndLines);
  }

  @override
  AsyncValue get mainDataAsync => ref.watch(newFindMovementByIdOrDocumentNOProvider);

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {

     return mainDataAsync.when(
      data: (movement) {

        this.movement = movement;
        MovementAndLines? movementAndLines = movement;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if(movement==null) return;
          if(movementAndLines!=null && !movementAndLines.isOnInitialState){
            changeMovementAndLineState(ref, movementAndLines);
            if(movementAndLines.canCompleteMovement || !movementAndLines.hasMovementLines) {
              ref.read(showBottomBarProvider.notifier).state = true;
            } else {
              ref.read(showBottomBarProvider.notifier).state = false;
            }

          }



        });
        if(movementAndLines==null || movementAndLines.isOnInitialState){
          return   MovementNoDataCard();
        }
        widget.movementId = movementAndLines.id.toString();
        movementId = movementAndLines.id!;
        String argument = jsonEncode(movementAndLines.toJson());
        List<IdempiereMovementLine>? lines = movementAndLines.movementLines;
        return  Column(
          spacing: 5,
          children: [
            movement!=null && movementAndLines.hasMovement ?
            //
            NewMovementCardWithLocator(
              argument: argument,
              bgColor: themeColorPrimary,
              height: singleProductDetailCardHeight,
              width: double.infinity,
              movementAndLines: MemoryProducts.movementAndLines,
            )
            : MovementNoDataCard(),
            if(movementAndLines.hasMovementConfirms)
              getMovementConfirm(movementAndLines.movementConfirms!),

            lines == null || lines.isEmpty ? Center(child: Text(Messages.NO_DATA_FOUND),)
                : getMovementLines(lines, getWidth()),
          ],
        );

      },error: (error, stackTrace) => Text('Error: $error'),
       loading: () => LinearProgressIndicator(
         minHeight: 36,
       ),
    );
  }


  Widget getMovementLines(List<IdempiereMovementLine> storages, double width) {

    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: storages.length,
        itemBuilder: (context, index) {
          final product = storages[index];
          return NewMovementLineCard(index: index + 1, totalLength:storages.length,
            width: width - 10, movementLine: product,
            canEdit: movementAndLines.canCompleteMovement ,
            showLocators: true,
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
        const SizedBox(height: 5,)
    );

  }
  @override
  int get qtyOfDataToAllowScroll => 2;

  @override
  int get actionScanTypeInt => widget.actionTypeInt;

  @override
  void initialSetting(BuildContext context, WidgetRef ref) {
    fromPage = widget.fromPage;
    ref.invalidate(persistentLocatorToProvider);
    isScanning = ref.watch(isScanningProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);

    inputString = ref.watch(inputStringProvider);
    pageIndexProdiver = ref.watch(productsHomeCurrentIndexProvider);
    actionScan = ref.read(actionScanProvider);
    movementAndLines = ref.watch(movementAndLinesProvider);



  }

  @override
  Future<void> handleInputString({required WidgetRef ref,required  String inputData,required int actionScan}) async {
    if(inputData.isEmpty){
      return;
    }
    final productsNotifier = ref.read(scanStateNotifierForLineProvider.notifier);
    productsNotifier.handleInputString(ref: ref, inputData: inputData,
        actionScan: widget.actionTypeInt);

    //ref.read(inputStringProvider.notifier).update((state) => inputData);
  }

  void changeMovementAndLineState(WidgetRef ref,MovementAndLines? movementAndLines) async {
    int len = movementAndLines?.movementLines?.length ?? 0;
    if(len>0) {
      final allow = len > qtyOfDataToAllowScroll;
      final notifier = ref.read(allowScrollFabProvider.notifier);
      if (notifier.state != allow) {
        notifier.state = allow;
      }

      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
    ref.read(isScanningProvider.notifier).update((state) => false);


    if(movementAndLines!=null && movementAndLines.hasMovement){
      ref.read(movementAndLinesProvider.notifier).state = movementAndLines;
      widget.movementId = movementAndLines.id.toString();
    }

  }
  Widget getAddButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: themeColorPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          ref.read(isScanningProvider.notifier).update((state) => false);

          if(MemoryProducts.movementAndLines.hasMovement){
            MemoryProducts.movementAndLines.nextProductIdUPC ='-1';
            MovementAndLines movementAndLines = MovementAndLines();
            movementAndLines.cloneMovementAndLines(MemoryProducts.movementAndLines);
            ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_STORE_ON_HAND;
            ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_STORE_ON_HAND;
            ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

            await saveMovementAndLines(movementAndLines);

            print('page index $pageIndexProdiver');
            print('action scan $actionScan');
            String route = '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/-1';

            if(context.mounted) {
              context.push(route,
              extra: movementAndLines);
            }
          }



        },
        icon: Icon(Icons.add_circle, color: Colors.white),
        label: Text(Messages.ADD_MOVEMENT_LINE,style: TextStyle(fontSize: themeFontSizeLarge,
            color: Colors.white),),

      ),
    );

  }
  @override
  AppBar? getAppBar(BuildContext context, WidgetRef ref) {

    return AppBar(
      backgroundColor: getAppBarBackgroundColor(context,ref),
      automaticallyImplyLeading: showLeading,
      leading: leadingIcon ,
      title: getAppBarTitle(context,ref),
      actions: getActionButtons(context,ref),

    );
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    MovementAndLines m = MemoryProducts.movementAndLines;

    if (widget.movementId != null &&
        widget.movementId != '-1' &&
        m.hasMovement) {

      final styleMain = m.documentNo != null && m.documentNo!.length > 20
          ? textStyleTitleMore20C
          : textStyleLarge;

      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            onPressed: () => popScopeAction(context, ref),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.documentNo ?? '',
                  style: styleMain,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${m.id ?? ''}   ${m.docStatus?.id ?? ''}',
                  style: textStyleSmallBold,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          onPressed: () => popScopeAction(context, ref),
        ),
        Text(Messages.MOVEMENT_SEARCH, style: textStyleLarge),
      ],
    );
  }


  @override
  void addQuantityText(BuildContext context, WidgetRef ref,
      TextEditingController quantityController,int quantity) {
    if(quantity==-1){
      quantityController.text = '';
      return;
    }
    String s =  quantityController.text;
    String s1 = s;
    String s2 ='';
    if(s.contains('.')) {
      s1 = s.split('.').first;
      s2 = s.split('.').last;
    }

    String r ='';
    if(s.contains('.')){
      r='$s1$quantity.$s2';
    } else {
      r='$s1$quantity';
    }

    int? aux = int.tryParse(r);
    if(aux==null || aux<=0){
      String message =  '${Messages.ERROR_QUANTITY} $quantity';
      showErrorMessage(context, ref, message);
      return;
    }
    quantityController.text = aux.toString();

  }



  @override
  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    final showBottomBar = ref.watch(showBottomBarProvider);
    return showBottomBar ?BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color:themeColorPrimary ,
        child: getAddButton(context, ref),
    ) : null;


  }


  Widget getMovementConfirm(List<IdempiereMovementConfirm> list) {
    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final data = list[index];
          String documentStatus = data.docStatus?.id ?? '';

          return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black),
              ),

              child: ListTile(leading: Text('$documentStatus :${index+1}',style: textStyleLarge), title: Text(data.documentNo ??'',style: textStyleLarge)));
        },
        separatorBuilder: (BuildContext context, int index) =>
        const SizedBox(height: 5)
    );
  }

  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {

    ref.read(isScanningProvider.notifier).update((state) => false);

  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    ref.invalidate(newScannedMovementIdForSearchProvider);
    if(fromPage==NewMovementEditScreen.FROM_PAGE_HOME){
      context.go(AppRouter.PAGE_HOME);
    } else {
      context.go('${AppRouter.PAGE_MOVEMENTS_LIST}/-1');
    }



  }


}



