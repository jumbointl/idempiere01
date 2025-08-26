import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement_line.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/locator_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/movement_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/movement_create_screen2.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../providers/product_provider_common.dart';
import '../../../providers/products_scan_notifier.dart';
import '../../store_on_hand/memory_products.dart';
import '../../store_on_hand/scan_barcode_multipurpose_button.dart';
import '../../../widget/movement_line_card.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../widget/movement_card2.dart';
import 'movements_home_page.dart';

class MovementHeadersView extends ConsumerStatefulWidget {
  MovementHeadersView({required this.movementsHomePage, super.key});
  final MovementsHomePage movementsHomePage ;
  double headerCardHeight = 180.0;
  double headerCardWidth = double.infinity;
  late ProductsScanNotifier productsNotifier ;
  late var usePhoneCamera;
  late AsyncValue asyncSelectView;
  late AsyncValue asyncCreateView;
  late AsyncValue asyncTable;
  late var sqlQueryType;
  final int pageIndex = Memory.PAGE_INDEX_HEARDER_VIEW;
  late var actionScan ;
  final int actionTypeInt = Memory.ACTION_FIND_MOVEMENT_BY_ID;
  @override
  ConsumerState<MovementHeadersView> createState() => HeadersViewModelState();

  void lastButtonPressed(BuildContext context, WidgetRef ref, String result) {
    openSearchDialog(context, ref, true);
  }

  void findButtonPressed(BuildContext context, WidgetRef ref, String result) {
    openSearchDialog(context, ref, false);
  }
  void newButtonPressed(BuildContext context, WidgetRef ref, String result) {
    ref.read(movementSqlQueryTypeProvider.notifier).state = ProductsScanNotifier.SQL_QUERY_CREATE;
    MemoryProducts.width = MediaQuery.of(context).size.width;
    MemoryProducts.createNewMovement = true;
    MemoryProducts.actionScan = Memory.ACTION_GET_LOCATOR_FROM_VALUE;

    ref.read(actionScanProvider.notifier).state = Memory.ACTION_GET_LOCATOR_FROM_VALUE;
    ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_MOVEMENTE_CREATE_SCREEN);
    ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => Memory.PAGE_INDEX_MOVEMENTE_CREATE_SCREEN);
    ref.read(isMovementCreateScreenShowedProvider.notifier).update((state) => true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the bottom sheet to take full screen height
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height, 
          child: MovementCreateScreen2(notifier: productsNotifier,
            width: MediaQuery.of(context).size.width,),
        );
      },
    );

  }

  void confirmButtonPressed(BuildContext context, WidgetRef ref, String result) {
    // TODO: implement confirmButtonPressed
  }


  Future<void> openSearchDialog(BuildContext context, WidgetRef ref,bool history) async{
    TextEditingController controller = TextEditingController();
    if(history){
      if(Memory.lastSearch==''){
        controller.text = Messages.NO_RECORDS_FOUND;
      } else {
        controller.text = Memory.lastSearch;
      }

    }
    bool stateActual = usePhoneCamera.state;
    usePhoneCamera.state = true;
    ref.read(isDialogShowedProvider.notifier).state = true;

    AwesomeDialog(
        context: context,
        headerAnimationLoop: false,
        dialogType: DialogType.noHeader,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Center(
            child: Column(
              spacing: 10,
              children: [
                Text(Messages.FIND),
                TextField(
                  controller: controller,
                  //style: const TextStyle(fontStyle: FontStyle.italic),
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
        ),
        title: Messages.FIND_BY_ID,
        desc: Messages.FIND_BY_ID,
        btnCancelText: Messages.CANCEL,
        btnOkText: Messages.OK,
        btnOkOnPress: () {
          usePhoneCamera.state = stateActual;
          final result = controller.text;
          Memory.lastSearch = result;
          if(result==''){
            AwesomeDialog(
              context: context,
              animType: AnimType.scale,
              dialogType: DialogType.error,
              body: Center(child: Text(
                Messages.ERROR_ID,
                //style: TextStyle(fontStyle: FontStyle.italic),
              ),), // correct here
              title: Messages.ERROR_ID,
              desc:   '',
              autoHide: const Duration(seconds: 3),
              btnOkOnPress: () {},
              btnOkColor: Colors.amber,
              btnCancelText: Messages.CANCEL,
              btnOkText: Messages.OK,
            ).show();
            return;
          }
          ref.read(movementSqlQueryTypeProvider.notifier).state = ProductsScanNotifier.SQL_QUERY_SELECT;
          ref.read(isDialogShowedProvider.notifier).state = false;
          productsNotifier.searchMovementById(result);
        },
        btnCancelOnPress: (){
          usePhoneCamera.state = stateActual;
          return ;
        }
    ).show();

  }

  void clearButtonPressed(BuildContext context, WidgetRef ref, String s) {
    ref.invalidate(resultOfSqlQueryMovementProvider);
    ref.invalidate(selectedLocatorFromProvider);
    ref.invalidate(selectedLocatorToProvider);
    ref.invalidate(scannedLocatorFromProvider);
    ref.invalidate(scannedLocatorToProvider);
    ref.invalidate(movementIdForMovementLineSearchProvider);
    ref.invalidate(resultOfSqlQueryMovementLineProvider);
    ref.invalidate(findMovementLinesByMovementIdProvider);


  }


}

class HeadersViewModelState extends ConsumerState<MovementHeadersView> {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // React to changes in dependencies
    ref.invalidate(selectedLocatorToProvider);
    ref.invalidate(selectedLocatorFromProvider);
    ref.invalidate(scannedMovementIdForSearchProvider);
    print('Dependencies changed');
  }

  final ScrollController _scrollController = ScrollController();




  @override
  Widget build(BuildContext context) {
    widget.actionScan = ref.watch(actionScanProvider.notifier);
    widget.asyncSelectView = ref.watch(findMovementByIdProvider);
    widget.asyncTable = ref.watch(findMovementLinesByMovementIdProvider);
    widget.asyncCreateView = ref.watch(createNewMovementProvider);
    widget.productsNotifier = ref.watch(scanStateNotifierProvider.notifier);
    widget.headerCardWidth = MediaQuery.of(context).size.width-30 ;
    final isScanning = ref.watch(isScanningProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(isScanningProvider.notifier).update((state) => false);
      ref.read(actionScanProvider.notifier).update((state) => widget.actionTypeInt);
      print('-----------------------------${widget.actionScan.state}');
    });

    widget.usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    widget.sqlQueryType = ref.watch(movementSqlQueryTypeProvider.notifier);
    if(widget.usePhoneCamera.state){
      usePhoneCameraToScan(context, ref);
    }
    return Scaffold(
      /*appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text(Messages.MOVEMENT),
        actions: [
          IconButton(onPressed: (){
            if(widget.usePhoneCamera.state){
              widget.usePhoneCamera.state = false;
              setState(() {});
            } else {
              widget.usePhoneCamera.state = true;
              setState(() {});
            }
          }, icon: Icon(widget.usePhoneCamera.state?
          Icons.barcode_reader : Icons.qr_code_scanner , color: Colors.purple,)),
        ],
        bottom: PreferredSize(preferredSize: Size.fromHeight(widget.headerCardHeight+80), child: Column(
          children: [
            getButtonScanWithPhone(context, ref),
            getHeaderCardBar(context, ref),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple, // font color
                    side: BorderSide(color: Colors.purple, width: 1), // border color and width
                  ),
                  onPressed: (){

                    FocusScope.of(context).unfocus();
                    ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_STORE_ON_HAND;
                    //ref.read(isScanningProvider.notifier).state = false;
                    //ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_STORE_ON_HAND_2;
                    //GoRouterHelper(context).push(AppRouter.PAGE_PRODUCT_STORE_ON_HAND_2);
                  },
                  child: Text(Messages.ADD_MOVEMENT_LINE),
                ),
              ),
            ),
            SizedBox(height: 10,),
            ],),
          ),
        ),*/

     body: PopScope(
       onPopInvokedWithResult: (bool didPop, Object? result) async {
         if (didPop) {

           return;
         }
         actionPop(context, ref);
       },
       child: Container(
         child: Column(
           children: [
             getHeaderCardBar(context, ref),

             Container(
               margin: EdgeInsets.symmetric(horizontal: 15),
               child: SizedBox(
                 width: double.infinity,
                 child: TextButton(
                   style: TextButton.styleFrom(
                     foregroundColor: Colors.purple, // font color
                     side: BorderSide(color: Colors.purple, width: 1), // border color and width
                   ),
                   onPressed: (){

                     FocusScope.of(context).unfocus();
                     //ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_STORE_ON_HAND;
                     //ref.read(isScanningProvider.notifier).state = false;
                     //ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_STORE_ON_HAND_2;
                     //GoRouterHelper(context).push(AppRouter.PAGE_PRODUCT_STORE_ON_HAND_2);
                   },
                   child: Text(Messages.ADD_MOVEMENT_LINE),
                 ),
               ),
             ),
             widget.asyncTable.when(
                 data: (data) {
                   if(data==null || data.isEmpty){
                     return Container();
                   }
                   int? locatorFrom = data[0].mLocatorID?.id;
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                     // Check if the widget is still mounted and the controller has clients
                     ref.read(allowedLocatorFromIdProvider.notifier).state = locatorFrom ?? 0 ;
                     ref.read(isScanningProvider.notifier).state = false;
                     bool scrollToDown = ref.read(movementLineScrollAtEndProvider);

                     if (mounted && scrollToDown && _scrollController.hasClients) {
                       // Check if the list is not empty before trying to scroll
                       if (data.isNotEmpty) {
                         _scrollController.animateTo(
                           _scrollController.position.maxScrollExtent,
                           duration: const Duration(milliseconds: 300),
                           curve: Curves.easeOut,
                         );
                       }
                     }
                   });

                   List<IdempiereMovementLine> list = data;
                 return Expanded(
                   child: SingleChildScrollView(
                     child: Padding(
                       padding: const EdgeInsets.all(15.0),
                       child: ListView.separated(shrinkWrap: true,
                         physics: NeverScrollableScrollPhysics(),
                         controller: _scrollController,
                         itemCount: list.length,
                         itemBuilder: (context, index) {
                         final item = list[index];
                         return MovementLineCard(movementLine: item,
                             width: MediaQuery.of(context).size.width-30 ,
                             productsNotifier: widget.productsNotifier,
                             index: index,
                             totalLength: list.length,
                         ); },
                         separatorBuilder: (context, index) { return SizedBox(height: 6,); }, ),
                     ),
                   ),
                 );},
                 error: (error, stackTrace) => Center(child: Text(error.toString())),
                 loading: () => LinearProgressIndicator(minHeight: widget.headerCardHeight,),
             ),

           ],
         ),
       ),
     ),

    );

  }
  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }



  Future<void> openSearchDialog(BuildContext context, WidgetRef ref,bool history) async{
    TextEditingController controller = TextEditingController();
    if(history){
      String lastSearch = Memory.lastSearch;
      if(lastSearch.isEmpty){
        controller.text = Messages.NO_RECORDS_FOUND;
      } else {
        controller.text = lastSearch;
      }

    }
    bool stateActual = widget.usePhoneCamera.state;
    widget.usePhoneCamera.state = true;
    //ref.read(isDialogShowedProvider.notifier).state = true;


    AwesomeDialog(
        context: context,
        headerAnimationLoop: false,
        dialogType: DialogType.noHeader,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Center(
            child: Column(
              spacing: 10,
              children: [
                Text(Messages.FIND),
                TextField(
                  controller: controller,
                  //style: const TextStyle(fontStyle: FontStyle.italic),
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
        ),
        title: Messages.FIND_BY_ID,
        desc: Messages.FIND_BY_ID,
        btnCancelText: Messages.CANCEL,
        btnOkText: Messages.OK,
        btnOkOnPress: () {
          widget.usePhoneCamera.state = stateActual;
          final result = controller.text;
          Memory.lastSearch = result;
          if(result==''){
            AwesomeDialog(
              context: context,
              animType: AnimType.scale,
              dialogType: DialogType.error,
              body: Center(child: Text(
                Messages.ERROR_ID,
                //style: TextStyle(fontStyle: FontStyle.italic),
              ),), // correct here
              title: Messages.ERROR_ID,
              desc:   '',
              autoHide: const Duration(seconds: 3),
              btnOkOnPress: () {},
              btnOkColor: Colors.amber,
              btnCancelText: Messages.CANCEL,
              btnOkText: Messages.OK,
            ).show();
            return;
          }

          widget.productsNotifier.searchMovementById(result);
        },
        btnCancelOnPress: (){
          widget.usePhoneCamera.state = stateActual;
          return ;
        }
    ).show();

  }
  Widget getButtonScanWithPhone(BuildContext context,WidgetRef ref) {
    bool show = ref.read(productsHomeCurrentIndexProvider.notifier).state == widget.pageIndex;
    return (show) ? PreferredSize(
        preferredSize: Size(double.infinity,30),
        child: SizedBox(width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                ref.watch(usePhoneCameraToScanProvider) ?_buttonScanWithPhone(context, ref):
                        ref.watch(isDialogShowedProvider)? Container() :
                        ScanBarcodeMultipurposeButton(widget.productsNotifier),
                SizedBox(height: 10,),

              ],
            ))) : Container();

  }
  Widget _buttonScanWithPhone(BuildContext context,WidgetRef ref) {
    bool isScanning = ref.watch(isScanningProvider);
    return TextButton(

      style: TextButton.styleFrom(
        backgroundColor: isScanning ? Colors.grey : Colors.cyan[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),

      ),
      onPressed: isScanning ? null :  () async {
        usePhoneCameraToScan(context, ref);
      },
      child: Text(Messages.OPEN_CAMERA),
    );
  }
  void usePhoneCameraToScan(BuildContext context, WidgetRef ref) {
    bool isScanning = ref.watch(isScanningProvider);
    isScanning ? null :  () async {
      ref.watch(isScanningProvider.notifier).state = true;

      String? result = await SimpleBarcodeScanner.scanBarcode(
        context,
        barcodeAppBar: BarcodeAppBar(
          appBarTitle: Messages.SCANNING,
          centerTitle: false,
          enableBackButton: true,
          backButtonIcon: Icon(Icons.arrow_back_ios),
        ),
        isShowFlashIcon: true,
        delayMillis: 300,
        cameraFace: CameraFace.back,
      );
      if (result != null) {
        widget.productsNotifier.searchMovementById(result);
      }
    };

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

  Widget getHeaderCardBar(BuildContext context, WidgetRef ref) {
    if(ref.watch(resultOfSqlQueryMovementProvider.notifier).state.id !=null
       && ref.watch(resultOfSqlQueryMovementProvider.notifier).state.id! >=0){
      return MovementCard2(height: widget.headerCardHeight, width: widget.headerCardWidth,
        movement: ref.watch(resultOfSqlQueryMovementProvider.notifier).state,
        productsNotifier: widget.productsNotifier,);
    }
    return widget.asyncSelectView.when(data: (data) {
      return MovementCard2(height: widget.headerCardHeight, width: widget.headerCardWidth, movement: data,
        productsNotifier: widget.productsNotifier,);
    },
        error: (error, stackTrace) => Text(error.toString()),
        loading: () => LinearProgressIndicator(minHeight: widget.headerCardHeight,));

    /*switch(widget.sqlQueryType){
      case ProductsScanNotifier.SQL_QUERY_CREATE:
        return widget.asyncCreateView.when(data: (data) {
          return MovementHeaderCard(height: widget.headerCardHeight, width: widget.headerCardWidth, movement: data, bgColor: themeColorPrimary,headersView: widget,);
        },
            error: (error, stackTrace) => Text(error.toString()),
            loading: () => LinearProgressIndicator(minHeight: widget.headerCardHeight,));
      case ProductsScanNotifier.SQL_QUERY_UPDATE:
        return widget.asyncSelectView.when(data: (data) {
          return MovementHeaderCard(height: widget.headerCardHeight, width: widget.headerCardWidth, movement: data, bgColor: themeColorPrimary,headersView: widget,);
        },
          error: (error, stackTrace) => Text(error.toString()),
          loading: () => LinearProgressIndicator(minHeight: widget.headerCardHeight,));

      case ProductsScanNotifier.SQL_QUERY_DELETE:
        return Container();
      case ProductsScanNotifier.SQL_QUERY_SELECT:
      return widget.asyncSelectView.when(data: (data) {
        return MovementHeaderCard(height: widget.headerCardHeight, width: widget.headerCardWidth, movement: data, bgColor: themeColorPrimary,headersView: widget,);
      },
          error: (error, stackTrace) => Text(error.toString()),
          loading: () => LinearProgressIndicator(minHeight: widget.headerCardHeight,));
      default:
        widget.sqlQueryType = ProductsScanNotifier.SQL_QUERY_SELECT;
        return widget.asyncSelectView.when(data: (data) {
          return MovementHeaderCard(height: widget.headerCardHeight, width: widget.headerCardWidth, movement: data, bgColor: themeColorPrimary,headersView: widget,);
        },
            error: (error, stackTrace) => Text(error.toString()),
            loading: () => LinearProgressIndicator(minHeight: widget.headerCardHeight,));
    }*/




  }

  void setAllowedLocatorId(WidgetRef ref) {


  }
  void actionPop(BuildContext context, WidgetRef ref){
    /*ref.invalidate(resultOfSqlQueryMovementProvider);
    ref.invalidate(resultOfSqlQueryMovementLineProvider);
    ref.invalidate(resultOfCreateMovementLinesProvider);
    ref.invalidate(selectedLocatorToProvider);
    ref.invalidate(selectedLocatorFromProvider);*/
    context.go(AppRouter.PAGE_HOME);
  }


}

