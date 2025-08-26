import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/movement_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_records_card.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../../config/router/app_router.dart';
import '../../../domain/idempiere/idempiere_movement_line.dart';
import '../../providers/locator_provider.dart';
import '../../widget/movement_line_card.dart';
import '../movement/products_home_provider.dart';
import '../../../../auth/domain/entities/warehouse.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_scan_notifier.dart';
import '../../providers/store_on_hand_provider.dart';
import '../../widget/no_data_card.dart';
import '../../widget/scan_product_barcode_button.dart';
import '../store_on_hand/memory_products.dart';
import 'movement_card.dart';


class MovementsScreen extends ConsumerStatefulWidget {
  static const String WAIT_FOR_SCAN_MOVEMENT = '-1';


  int countScannedCamera =0;
  late ProductsScanNotifier productsNotifier ;
  int actionTypeInt = Memory.ACTION_FIND_MOVEMENT_BY_ID ;
  late var allowedLocatorId;
  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_SCREEN;
  late var usePhoneCamera;
  String movementId;
  MovementsScreen({super.key, required this.movementId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => MovementsScreenState();
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
    ref.read(isMovementCreateScreenShowedProvider.notifier).update((state) => true);
    Future.delayed(const Duration(milliseconds: 500), () {

    });
    GoRouterHelper(context).push(AppRouter.PAGE_MOVEMENTS_SEARCH, extra:productsNotifier);
  }

  @override
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
}

class MovementsScreenState extends ConsumerState<MovementsScreen> {
  late ScanProductBarcodeButton scanButton;
  late int movementId;

  @override
  Widget build(BuildContext context){

    final movementAsync = ref.watch(findMovementByIdProvider);
    final movementLineAsync = ref.watch(findMovementLinesByMovementIdProvider);
    widget.productsNotifier = ref.watch(scanStateNotifierProvider.notifier);
    final double width = MediaQuery.of(context).size.width - 30;
    final double bodyHeight = MediaQuery.of(context).size.height - 200;

    final resultOfSameWarehouse = ref.watch(resultOfSameWarehouseProvider.notifier);
    Warehouse? userWarehouse = ref.read(authProvider).selectedWarehouse;
    int userWarehouseId = userWarehouse?.id ?? 0;
    String userWarehouseName = userWarehouse?.name ?? '';
    final isScanning = ref.watch(isScanningProvider);
    widget.usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    final double singleProductDetailCardHeight = 145;
    Color foreGroundProgressBar = Colors.purple;

    scanButton = ScanProductBarcodeButton(widget.productsNotifier,
        actionTypeInt: widget.actionTypeInt,
        pageIndex: widget.pageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      int aux = int.parse(MovementsScreen.WAIT_FOR_SCAN_MOVEMENT);
      movementId = int.tryParse(widget.movementId) ?? aux;
      if(movementId != aux && movementId >0){
        ref.watch(scannedMovementIdForSearchProvider.notifier).update((state) => widget.movementId!);
      } else {
        ref.read(isScanningProvider.notifier).update((state) => false);
      }


    });
    String title ='${Messages.MOVEMENT} ${widget.movementId}';
    if(widget.movementId==MovementsScreen.WAIT_FOR_SCAN_MOVEMENT){
      title = Messages.FIND_MOVEMENT;
    }
    //print('Bearer ${Environment.token}');
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
          {
            ref.read(productsHomeCurrentIndexProvider.notifier).state = 0,
            ref.invalidate(selectedLocatorToProvider),
            ref.invalidate(selectedLocatorFromProvider),
            context.go(AppRouter.PAGE_HOME),
          }
            //
        ),
        title: Text(title),
          actions: [

            widget.usePhoneCamera.state ? IconButton(
              icon: const Icon(Icons.barcode_reader),
              onPressed: () => {
              ref.watch(isDialogShowedProvider.notifier).state = false,
                widget.usePhoneCamera.state = false},
            ) :  IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => {
            ref.watch(isDialogShowedProvider.notifier).state = false,
              widget.usePhoneCamera.state = true},

          ),

        ],

      ),

      body: SafeArea(
        child: PopScope(
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              return;
            }
            ref.invalidate(selectedLocatorToProvider);
            ref.invalidate(selectedLocatorFromProvider);
            ref.read(productsHomeCurrentIndexProvider.notifier).state = 0;
            context.go(AppRouter.PAGE_HOME);
          },
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 5,
              children: [
                  isScanning
                  ? LinearProgressIndicator(
                backgroundColor: Colors.cyan,
                color: foreGroundProgressBar,
                minHeight: 36,
              )
                  : getSearchBar(context),
        
              SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width - 30,
                  height: singleProductDetailCardHeight,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: movementAsync.when(
                    data: (product) {
                       return  product.id!= null && product.id! >0 ? MovementCard(
                         bgColor: Colors.white,
                         height: singleProductDetailCardHeight,
                         width: double.infinity,
                         movementScreen: widget,

                           ) : NoDataCard();

                    },error: (error, stackTrace) => Text('Error: $error'),
                    loading: () => Container(),
                  ),
                ),
              ),
                Expanded(
                    child: movementLineAsync.when(
                      data: (storages) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          // deley 1 secund
        

                        });
                        return storages == null ? Container() : getMovement(storages, width);
                      },
                      error: (error, stackTrace) => Text('Error: $error'),
                      loading: () => const LinearProgressIndicator(),
                    )),
                getScanButton(context),
        
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buttonScanWithPhone(BuildContext context,WidgetRef ref) {
    bool isScanning = ref.watch(isScanningProvider);
    return TextButton(

      style: TextButton.styleFrom(
        backgroundColor: isScanning ? Colors.grey : Colors.cyan[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),

      ),
      onPressed: isScanning ? null :  () async {
        ref.watch(isScanningProvider.notifier).state = true;

        String? result= await SimpleBarcodeScanner.scanBarcode(
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
        if(result!=null){

          ref.read(scanStateNotifierProvider.notifier).addBarcodeToSearchMovement(result);
          //ref.read(scannedCodeProvider.notifier).state = result;
        }

      },
      child: Text(Messages.OPEN_CAMERA),
    );
  }

  Widget getMovement(List<IdempiereMovementLine> storages, double width) {
    bool isScanning = ref.watch(isScanningProvider);
    bool showResultCard = ref.watch(showResultCardProvider);
    if(!showResultCard){
      return Container();
    }

    if(storages.isEmpty){
      return isScanning ?Container(): Container(
          width: MediaQuery.of(context).size.width - 30,
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          //child: ProductResumeCard(storages,width-10)
          child: NoRecordsCard(width:width-10)

      );
    }

    return isScanning? Container() :
         ListView.builder(
                   itemCount: storages.length,
                   padding: const EdgeInsets.all(10),
                   itemBuilder: (context, index) {
         final product = storages[index];
         return MovementLineCard(productsNotifier: widget.productsNotifier, index: index + 1, totalLength:storages.length, width: width - 10, movementLine: product,);
                   },
                 ) ;


  }
  Widget getSearchBar(BuildContext context){
    var isScanning = ref.watch(isScanningProvider);
    var usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    return
      SizedBox(
        //width: double.infinity,
        width: MediaQuery.of(context).size.width - 30,
        height: 36,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 5,
          children: [
            IconButton(onPressed: (){
              ref.watch(isDialogShowedProvider.notifier).state = false;
            }, icon: Icon(usePhoneCamera.state?
            Icons.qr_code_scanner : Icons.barcode_reader, color:
            ref.watch(isDialogShowedProvider.notifier).state? Colors.red : Colors.purple,)),
            Expanded(
              child: Text(
                Messages.FIND_MOVEMENT_BY_ID,
                textAlign: TextAlign.center,
              ),
            ) ,
            IconButton(onPressed:() async {getBarCode(context,false);},
              icon: Icon( Icons.search, color:isScanning?Colors.grey: Colors.purple,)),
            IconButton(onPressed:() async {getBarCode(context,true);},
                icon: Icon( Icons.history, color:isScanning?Colors.grey: Colors.purple,)),

          ],
        ),
      );

  }
  Future<void> getBarCode(BuildContext context, bool history) async{
    TextEditingController controller = TextEditingController();
    if(history){
      String lastSearch = Memory.lastSearch;
      if(lastSearch.isEmpty){
        controller.text = Messages.NO_RECORDS_FOUND;
      } else {
        controller.text = lastSearch;
      }

    }
    bool stateActual = ref.watch(usePhoneCameraToScanProvider.notifier).state;
    ref.watch(usePhoneCameraToScanProvider.notifier).state = true;
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
              Text(Messages.FIND_MOVEMENT_BY_ID),
              TextField(
                controller: controller,
                //style: const TextStyle(fontStyle: FontStyle.italic),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
      ),
      title: Messages.FIND_MOVEMENT_BY_ID,
      desc: Messages.FIND_MOVEMENT_BY_ID,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
      btnOkOnPress: () {
        ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
        final result = controller.text;
        int aux = int.tryParse(result) ?? -1;
        print('-------------------------result $result');
        if(result=='' || aux<1){
          AwesomeDialog(
            context: context,
            animType: AnimType.scale,
            dialogType: DialogType.error,
            body: Center(child: Text(
              Messages.ERROR_ID,
              style: TextStyle(fontStyle: FontStyle.italic),
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
        widget.productsNotifier.addBarcodeToSearchMovement(result);
      },
      btnCancelOnPress: (){
        ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
        return ;
      }
    ).show();

  }

  Widget getScanButton(BuildContext context) {
    if(ref.read(productsHomeCurrentIndexProvider.notifier).state==widget.pageIndex){
      return PreferredSize(
          preferredSize: Size(double.infinity,30),
          child: SizedBox(width: MediaQuery.of(context).size.width, child:

          ref.watch(usePhoneCameraToScanProvider) ?buttonScanWithPhone(context, ref):
          //ScanBarcodeMultipurposeButton(widget.productsNotifier)));
          scanButton));
    } else {
      return Container();
    }


  }




}