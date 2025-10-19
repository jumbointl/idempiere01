// Clase de estado abstracta para lógica común
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/scan_button_by_action.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/products_home_provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../config/router/app_router.dart';
import '../../../config/theme/app_theme.dart';
import '../../shared/data/memory.dart';
import '../../shared/data/messages.dart';
import '../domain/idempiere/movement_and_lines.dart';
import '../presentation/providers/product_provider_common.dart';
import '../presentation/providers/store_on_hand_provider.dart';
import 'input_data_processor.dart';
import 'input_dialog.dart';

abstract class CommonConsumerState<T extends ConsumerStatefulWidget> extends ConsumerState<T> implements InputDataProcessor {


  /*late var isScanning = ref.watch(isScanningProvider.notifier);
  late var usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
  late AsyncValue mainDataAsync  = getMainDataAsync;
  late AsyncValue mainDataListAsync = getMainDataListAsync;
  late var isDialogShowed = ref.watch(isDialogShowedProvider.notifier);
  late var scrollToTop = ref.watch(scrollToUpProvider.notifier);
  late ScrollController scrollController = ScrollController();*/

  late var isScanning ;
  late var usePhoneCamera ;
  AsyncValue get mainDataAsync ;
  //AsyncValue get mainDataListAsync;
  late var isDialogShowed;
  late var scrollToTop ;
  late var inputString;
  late var pageIndexProdiver;
  late var actionScan;
  late ScrollController scrollController;
  double goToPosition =0.0;
  double? get fontSizeTitle =>themeFontSizeTitle;
  double? get fontSizeLarge =>themeFontSizeLarge;
  double? get fontSizeMedium=>themeFontSizeNormal;
  double? get fontSizeSmall=>themeFontSizeSmall;
  Color? get fontBackgroundColor=>Colors.white;
  Color? get fontForegroundColor=>Colors.black;
  Color? get backgroundColor=>Colors.white;
  Color? get foregroundColor=>Colors.black;
  Color? get hintTextColor=>Colors.purple;
  Color? get resultColor=>Colors.purple;
  Color? get borderColor=>Colors.black;
  late TextStyle textStyleTitle = TextStyle(fontSize: fontSizeTitle,
      color: fontForegroundColor);
  late TextStyle textStyleLarge = TextStyle(fontSize: fontSizeLarge,
      color: fontForegroundColor);
  late TextStyle textStyleLargeBold = TextStyle(fontSize: fontSizeLarge,
      color: fontForegroundColor, fontWeight: FontWeight.bold);
  late TextStyle textStyleMedium = TextStyle(fontSize: fontSizeMedium,
      color: fontForegroundColor);
  late TextStyle textStyleMediumBold = TextStyle(fontSize: fontSizeMedium,
      color: fontForegroundColor, fontWeight: FontWeight.bold);
  late TextStyle textStyleSmall = TextStyle(fontSize: fontSizeSmall,
      color: fontForegroundColor);
  late TextStyle textStyleSmallBold = TextStyle(fontSize: fontSizeSmall,
      color: fontForegroundColor, fontWeight: FontWeight.bold);
  late TextStyle textStyleBold = TextStyle(
      color: fontForegroundColor, fontWeight: FontWeight.bold);
  String get hinText;
  double getWidth();
  Color? getAppBarBackgroundColor(BuildContext context,WidgetRef ref);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      executeAfterShown();
    });
  }
  @override
  Widget build(BuildContext context){
    initialSetting(context,ref);

    return Scaffold(

      appBar: getAppBar(context,ref),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          double positionAdd= scrollController.position.maxScrollExtent;
          if(scrollToTop.state){
            goToPosition -= positionAdd;
            if(goToPosition <= 0){
              goToPosition = 0;
              ref.read(scrollToUpProvider.notifier).update((state) => !state);
            }
          } else {
            goToPosition+= positionAdd;
            if(goToPosition >= scrollController.position.maxScrollExtent){
              goToPosition = scrollController.position.maxScrollExtent;
              ref.read(scrollToUpProvider.notifier).update((state) => !state);
            }
          }

          setState(() {});
          scrollController.animateTo(
            goToPosition,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: Icon(scrollToTop.state ? Icons.arrow_upward :Icons.arrow_downward),
      ),
      bottomNavigationBar: isDialogShowed.state ? Container(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color: themeColorPrimary,
        child: Center(
          child: Text(Messages.DIALOG_SHOWED,
            style: TextStyle(color: Colors.white,fontSize: themeFontSizeLarge
                ,fontWeight: FontWeight.bold),),
        ),
      ) : getBottomAppBar(context,ref),

      body: SafeArea(
        child: PopScope(
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              return;
            }
            popScopeAction(context,ref);


          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  getSearchBar(context,ref,hinText,this),
                  getMainDataCard(context, ref),
                  //getMainDataList(context, ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  void executeAfterShown();

  Widget getMainDataCard(BuildContext context,WidgetRef ref);
  //Widget getMainDataList(BuildContext context,WidgetRef ref);





  void iconBackPressed(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
  }

  void popScopeAction(BuildContext context, WidgetRef ref) {
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(actionScanProvider.notifier).update((state)
    => Memory.ACTION_FIND_MOVEMENT_BY_ID);
    ref.read(productsHomeCurrentIndexProvider.notifier).update((state)
    => Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);

    context.go(AppRouter.PAGE_HOME);
  }

  BottomAppBar getBottomAppBar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
        height: Memory.BOTTOM_BAR_HEIGHT,
        color: getColorByActionScan() ,
        child: usePhoneCamera.state ? buttonScanWithPhone(context,ref,this)
            : getScanButton(context,ref)
    );


  }
  void initialSetting(BuildContext context, WidgetRef ref);




  Widget getScanButton(BuildContext context, WidgetRef ref) {
    //return EnterSubmitScreen(processor: this,);
    print('actionScan.state ${actionScan.state}');
    return ScanButtonByAction(
        color: getColorByActionScan(),
        actionTypeInt: actionScan.state,
        processor: this);



  }


  AppBar? getAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: getAppBarBackgroundColor(context,ref),
      automaticallyImplyLeading: true,
      leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async =>
          {
            context.go(AppRouter.PAGE_HOME),
            //iconBackPressed(context,ref),
          }
        //
      ),

      title: getAppBarTitle(context,ref),
      actions: [
        usePhoneCamera.state ? IconButton(
          icon: const Icon(Icons.barcode_reader),
          onPressed: () => {
            usePhoneCamera.state = false,
            isDialogShowed.state = false,
            setState(() {}),
          },

        ) :  IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => {
            usePhoneCamera.state = true,
            isDialogShowed.state = false,
            setState(() {}),
          },

        ),

      ],

    );
  }

  Widget? getAppBarTitle(BuildContext context, WidgetRef ref);

  Future<MovementAndLines> getSavedMovementAndLines () async {
    var movementAndLines = await GetStorage().read(Memory.KEY_MOVEMENT_AND_LINES);
    if(movementAndLines != null){
      if(movementAndLines is MovementAndLines) return movementAndLines;
      return MovementAndLines.fromJson(movementAndLines);
    } else {
      MovementAndLines data = MovementAndLines();
      data.setUser(Memory.sqlUsersData);
      return data ;
    }
  }
  Future<void> saveMovementAndLines(MovementAndLines? movementAndLines) async {
    if(movementAndLines==null){
      GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
      return;
    }
      await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, movementAndLines.toJson());
  }
  void removeMovementAndLines(){
    GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
  }
  Color? getColorByMovementAndLines(MovementAndLines? data){
     if(data==null ||!data.hasMovement) return Colors.white;
     if(data.canComplete) return Colors.cyan[200];
     return Colors.green[200];
  }

  Color? getColorByActionScan() {
    int action = actionScan.state;
    if(action == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      return Colors.cyan[800];
    }else if(action == Memory.ACTION_GET_LOCATOR_TO_VALUE){
      return Colors.yellow[800];

    }
    return themeColorPrimary;

  }

}