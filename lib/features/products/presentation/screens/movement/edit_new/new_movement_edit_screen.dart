
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/movement_and_lines_consumer_state.dart';
import '../../../../domain/idempiere/response_async_value.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';


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


}

class NewMovementEditScreenState extends MovementAndLinesConsumerState<NewMovementEditScreen> {





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
  AsyncValue<ResponseAsyncValue> get mainDataAsync => ref.watch(newFindMovementByIdOrDocumentNOProvider);

  @override
  int get qtyOfDataToAllowScroll => 2;

  @override
  int get actionScanTypeInt => widget.actionTypeInt;



  @override
  Future<void> handleInputString({required WidgetRef ref,required  String inputData,required int actionScan}) async {
    asyncResultHandled = false;

    if(inputData.isEmpty){
      return;
    }
    final productsNotifier = ref.read(scanStateNotifierForLineProvider.notifier);
    productsNotifier.handleInputString(ref: ref, inputData: inputData,
        actionScan: widget.actionTypeInt);

    //ref.read(inputStringProvider.notifier).update((state) => inputData);
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
  BottomAppBar? getBottomAppBar(BuildContext context, WidgetRef ref) {
    final showBottomBar = ref.watch(showBottomBarProvider);
    return showBottomBar ?BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color:themeColorPrimary ,
        child: getAddButton(context, ref),
    ) : null;


  }




  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {

    ref.read(isScanningProvider.notifier).update((state) => false);

  }

  @override
  void popScopeAction(BuildContext context, WidgetRef ref) async {
    ref.invalidate(newScannedMovementIdForSearchProvider);
    int pageFrom = ref.read(pageFromProvider);
    print('page from $pageFrom');
    if(pageFrom <=0){
      context.go(AppRouter.PAGE_HOME);
    } else {
      context.go('${AppRouter.PAGE_MOVEMENTS_LIST}/-1');
    }



  }

  @override
  void setWidgetMovementId(String id) {
    widget.movementId = id;
  }






}



