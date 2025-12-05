import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/common_screen_state.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_confirm.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/domain/entities/warehouse.dart';
import '../../../../../home/presentation/screens/home_screen.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/scan_button_by_action.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/persitent_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_provider.dart';
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

  static const String WAIT_FOR_SCAN_MOVEMENT='-1';


  NewMovementEditScreen({
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
  final ScrollController _scrollController = ScrollController();
  final double singleProductDetailCardHeight = 160;
  Warehouse? userWarehouse;
  late var movementAndLines ;
  int movementId =-1;
  @override
  late var isDialogShowed;

  @override
  late var usePhoneCamera;



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
          spacing: 10,
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
            if(movementAndLines.movementConfirms!=null &&
                movementAndLines.movementConfirms!.isNotEmpty)
              getMovementConfirm(movementAndLines.movementConfirms!),
            if(movementAndLines.canCompleteMovement || !movementAndLines.hasMovementLines)
              SizedBox(
                width: double.infinity,
                  child: getAddButton(context,ref)),
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
        const SizedBox(height: 10,)
    );

  }
  //@override
  //AsyncValue get mainDataListAsync => ref.watch(newFindMovementLinesByMovementIdProvider);


  @override
  void initialSetting(BuildContext context, WidgetRef ref) {

    ref.invalidate(persistentLocatorToProvider);
    isScanning = ref.watch(isScanningProvider);
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);
    scrollToTop = ref.watch(scrollToUpProvider);
    scrollController = ScrollController();

    inputString = ref.watch(inputStringProvider);
    pageIndexProdiver = ref.watch(productsHomeCurrentIndexProvider);
    actionScan = ref.read(actionScanProvider);
    movementAndLines = ref.watch(movementAndLinesProvider);



  }

  @override
  Future<void> handleInputString(BuildContext context, WidgetRef ref, String inputData) async {
    if(inputData.isEmpty){
      return;
    }
    final productsNotifier = ref.read(scanStateNotifierForLineProvider.notifier);
    productsNotifier.handleInputString(context,ref,inputData);

    //ref.read(inputStringProvider.notifier).update((state) => inputData);
  }

  void changeMovementAndLineState(WidgetRef ref,MovementAndLines? movementAndLines) async {
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
          backgroundColor: Colors.green[800],
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

            print('page index ${pageIndexProdiver}');
            print('action scan ${actionScan}');
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
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    MovementAndLines movementAndLines = MemoryProducts.movementAndLines;
    late TextStyle style = textStyleLarge;
    if(movementAndLines.documentNo!=null && movementAndLines.documentNo!.length>20){
      style = textStyleTitleMore20C;
    }
    if(widget.movementId!=null && widget.movementId!='-1' && movementAndLines.hasMovement){
      return ListTile(
        title: Text(movementAndLines.documentNo ??'',
          style: style,
          ),
        subtitle: Text('${movementAndLines.id ?? ''} ${movementAndLines.docStatus?.id ?? ''}'
          ,style: textStyleLarge,),
      );
    } else {
      return Text(Messages.MOVEMENT_SEARCH,style: textStyleTitle);
    }

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

  Widget getSearchMovement(BuildContext context, WidgetRef ref) {
    return SizedBox(
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.yellow[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          ref.read(isScanningProvider.notifier).state = false ;
          ref.read(isDialogShowedProvider.notifier).state = false;
          ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_MOVEMENT_BY_ID;
          pageIndexProdiver.update((state)=>Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);
          widget.movementId = '-1';
          ref.invalidate(newScannedMovementIdForSearchProvider);
          ref.invalidate(newFindMovementLinesByMovementIdProvider);
          MemoryProducts.movementAndLines.clearData();
          removeMovementAndLines();
        },
        child: Text(Messages.FIND_MOVEMENT,style: TextStyle(fontSize: themeFontSizeLarge,
            color: Colors.white),),
      ),
    );

  }

  @override
  BottomAppBar getBottomAppBar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color: getColorByActionScan() ,
        child: usePhoneCamera ? buttonScanWithPhone(context,ref,this)
            : getScanButton(context,ref)
    );


  }
  @override
  Widget getScanButton(BuildContext context, WidgetRef ref) {
    return ScanButtonByAction(
        color: getColorByActionScan(),
        actionTypeInt: widget.actionTypeInt,
        processor: this);
  }
  @override
  String get hinText {
    if(actionScan == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      return Messages.FIND_MOVEMENT;
    } else if(actionScan == Memory.ACTION_GET_LOCATOR_TO_VALUE) {
      return Messages.FIND_LOCATOR;
    }  else  if(actionScan == Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND) {
      return Messages.SKU_UPC;
    }  else {
      return Messages.INPUT_DATA;
    }

  }

  Widget getMovementConfirm(List<IdempiereMovementConfirm> list) {
    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final data = list[index];
          return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black),
              ),

              child: ListTile(leading: Text('CO :${index+1}',style: textStyleLarge), title: Text(data.documentNo ??'',style: textStyleLarge)));
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
    context.go('${AppRouter.PAGE_MOVEMENTS_LIST}/-1');
  }

  @override
  void changeUsePhoneCameraToScanState(BuildContext context, WidgetRef ref) {
    // 🧠 Riverpod se encarga del rebuild, sin setState
    print('usePhoneCamera: $usePhoneCamera');
    ref.read(usePhoneCameraToScanProvider.notifier).state = !usePhoneCamera;
    ref.read(isDialogShowedProvider.notifier).state = false;
  }
}



