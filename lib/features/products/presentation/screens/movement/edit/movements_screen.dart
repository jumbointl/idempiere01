import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/movement_provider_old.dart'
    hide scannedMovementIdForSearchProvider;
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit/movement_line_card_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/products_home_provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../providers/movement_provider_for_line.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_provider.dart';
import '../../../widget/no_data_card.dart';
import '../provider/new_movement_provider.dart';
import 'movement_card_with_locator_for_line.dart';
import 'scan_product_barcode_button_for_line.dart';
import '../../store_on_hand/memory_products.dart';


class MovementsScreen extends ConsumerStatefulWidget {
  static const String WAIT_FOR_SCAN_MOVEMENT = '-1';

  int countScannedCamera =0;
  int actionTypeInt = Memory.ACTION_FIND_MOVEMENT_BY_ID ;
  late var allowedLocatorId;
  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_SCREEN;
  late var usePhoneCamera;
  String movementId;
  bool? forceToSearch;
  String title=Messages.MOVEMENT;

  late ProductsScanNotifierForLine productsNotifier;

  MovementsScreen({super.key, required this.movementId, required bool forceToSearch});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => MovementsScreenState();


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

}

class MovementsScreenState extends ConsumerState<MovementsScreen> {
  //late ScanProductBarcodeButtonForLine scanButton;
  Color foreGroundProgressBar = Colors.purple;
  final double singleProductDetailCardHeight = 160;
  late AsyncValue movementAsync;
  //late AsyncValue movementLineAsync;
  late double width;
  final ScrollController _scrollController = ScrollController();
  late var scrollToTop  ;
  double goToPosition =0.0;
  int count =0;
  late var confirmAsync;
  late var movementId;
  late var isDialogShowed;
  IdempiereMovement? movement ;
  int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;
  late String subtitle='';
@override
  void initState() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    ref.read(isScanningForLineProvider.notifier).update((state) => false);
    ref.read(isDialogShowedProvider.notifier).update((state) => false);
    ref.read(productsHomeCurrentIndexProvider.notifier).update((state) => widget.pageIndex);
    ref.read(actionScanProvider.notifier).update((state) => widget.actionTypeInt);
    int aux = int.tryParse(widget.movementId) ?? -1;
    if(aux>0){
      widget.productsNotifier.addBarcodeToSearchMovement(widget.movementId);
    }

  });
    super.initState();
  }
  @override
  Widget build(BuildContext context){
    
    widget.productsNotifier = ref.watch(scanStateNotifierForLineProvider.notifier);
    movementAsync = ref.watch(newFindMovementByIdOrDocumentNOProvider);
    movementId = ref.watch(movementIdForMovementLineSearchProvider.notifier);
    //movementLineAsync = ref.watch(findMovementLinesByMovementIdProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider.notifier);
    width = MediaQuery.of(context).size.width - 30;
    scrollToTop = ref.watch(scrollToUpProvider.notifier);
    widget.usePhoneCamera = ref.watch(usePhoneCameraToScanForLineProvider.notifier);

    bool canEdit = false;


    widget.title ='MV: ${widget.movementId}';
    if(widget.movementId == MovementsScreen.WAIT_FOR_SCAN_MOVEMENT){
      widget.title = Messages.FIND_MOVEMENT;
      subtitle ='';
    }

    if(movementId.state!=null && movementId.state>0){
      movement = MemoryProducts.movementAndLines;
      if(movement != null && movement!.id!=null && movement!.id!>0){
        subtitle = movement!.docStatus?.id ?? '';
        canEdit = Memory.canConformMovement(movement!);

        if(canEdit){
          widget.title =  movement!.documentNo ?? '';
        } else {
          if(movement!.id!=null && movement!.id!>0){
            widget.title =  movement!.documentNo ?? '';
            widget.title ='${widget.title} $subtitle';
          } else {
            widget.title =  widget.title =Messages.NOT_FOUND;
            subtitle ='';
          }

        }

      }


    } else {
      widget.title = Messages.FIND_MOVEMENT;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: movementId.state!=null && movementId.state>0 ?
        canEdit ? Colors.cyan[200]: Colors.amber[200] : Colors.white,
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async =>
          {
            if(context.mounted){
              context.go(AppRouter.PAGE_HOME),
            }
          }
            //
        ),
        title: Text(widget.title,style: TextStyle(fontSize: themeFontSizeLarge,
         )),
        /*ListTile(subtitle: Text(subtitle),
             title: Text(widget.title)),*/
          actions: [

            widget.usePhoneCamera.state ? IconButton(
              icon: const Icon(Icons.barcode_reader),
              onPressed: () => {
                isDialogShowed.state = false,
                widget.usePhoneCamera.state = false,
                setState(() {}),
              },
            ) :  IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => {
            isDialogShowed.state = false,
              widget.usePhoneCamera.state = true,
              setState(() {}),
            },

          ),

        ],

      ),
      floatingActionButton: (movementId.state!=null && movementId.state>0) ? FloatingActionButton(
        onPressed: () {
          double positionAdd=125;
          if(MediaQuery.of(context).orientation == Orientation.portrait){
            positionAdd=250;
          }
          if(scrollToTop.state){
            goToPosition -= positionAdd;
            if(goToPosition <= 0){
              goToPosition = 0;
              ref.read(scrollToUpProvider.notifier).update((state) => !state);
            }
          } else {
            goToPosition+= positionAdd;
            if(goToPosition >= _scrollController.position.maxScrollExtent){
              goToPosition = _scrollController.position.maxScrollExtent;
              ref.read(scrollToUpProvider.notifier).update((state) => !state);
            }
          }
          setState(() {});
          _scrollController.animateTo(
            goToPosition,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: Icon(scrollToTop.state ? Icons.arrow_upward :Icons.arrow_downward),
      ) :null,
      bottomNavigationBar: BottomAppBar(

          height: Memory.BOTTOM_BAR_HEIGHT,
          color: themeColorPrimary,
          child: isDialogShowed.state ? Container(
              height: Memory.BOTTOM_BAR_HEIGHT,
              color: themeColorPrimary,
              child: Center(
                child: Text(Messages.DIALOG_SHOWED,
                  style: TextStyle(color: Colors.white,fontSize: themeFontSizeLarge
                      ,fontWeight: FontWeight.bold),),
              ),) :getScanButton(context)),
      body: SafeArea(
          child: PopScope(
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) {
                return;
              }
              if(context.mounted){
                context.go(AppRouter.PAGE_HOME);
              }
            },

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [

                  SliverToBoxAdapter(child: getSearchBar(context)),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    sliver: SliverToBoxAdapter(
                      child: movementAsync.when(

                        data: (movement) {

                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            if(movement != null && movement.id!=null && movement.id!>0){
                              changeMovementIdState(ref, movement.id);
                            }


                          });
                          MemoryProducts.movementAndLines = movement;
                          bool canEdit = Memory.canConformMovement(movement);
                          return  Column(
                            spacing: 10,
                            children: [
                              movement.id!= null && movement.id! >0 ?
                                  //
                              MovementCardWithLocatorForLine(
                                bgColor: themeColorPrimary,
                                height: singleProductDetailCardHeight,
                                width: double.infinity,
                                movementAndLines: movement,

                              ) : NoDataCard(),
                              if(movement.id!= null && movement.id! >0 && canEdit) getAddButton(context,ref),
                            ],
                          );

                        },error: (error, stackTrace) => Text('Error: $error'),
                        loading: () => LinearProgressIndicator(
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ),


/*                  movementLineAsync.when(
                      data: (storages) {

                      print('----------------mv lines ------result ');
                      if(storages != null) {
                        print(storages.length);
                      }
                      print('----------------mv lines ------result ');


                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          ref.watch(isScanningForLineProvider.notifier).update((state) => false);

                          if(storages!=null && storages.isNotEmpty){
                            if(storages.isNotEmpty){
                              if(ref.read(selectedLocatorToForLineProvider.notifier).state.id == null
                                  || ref.read(selectedLocatorToForLineProvider.notifier).state.id!<=0){
                                showErrorMessage(context, ref, Messages.ERROR_LOCATOR);
                              }

                            }
                          } else {
                            ref.read(selectedLocatorToForLineProvider.notifier).state = IdempiereLocator(id: Memory.INITIAL_STATE_ID,value: Messages.FIND);
                            ref.read(persistentLocatorToProvider.notifier).state = IdempiereLocator(id: Memory.INITIAL_STATE_ID,value: Messages.FIND);
                          }


                        });

                        return storages == null || storages.isEmpty ?
                        SliverToBoxAdapter(
                             child: Center(child: Text(Messages.NO_DATA_FOUND),))
                            : getMovementLines(storages, width);
                      },
                      error: (error, stackTrace) => SliverToBoxAdapter(
                          child: Text('Error: $error')),
                      loading: () => SliverToBoxAdapter(
                        child: LinearProgressIndicator(
                        backgroundColor: Colors.cyan,
                        color: foreGroundProgressBar,
                        minHeight: 36,
                        ),
                      )
                  ),*/

                ],
              ),
            ),
          ),
        ),

    );
  }

  Widget buttonScanWithPhone(BuildContext context,WidgetRef ref) {

    bool isScanning = ref.watch(isScanningForLineProvider);

    return TextButton(

      style: TextButton.styleFrom(
        backgroundColor: isScanning ? Colors.grey : themeColorPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),

      ),
      onPressed: isScanning ? null :  () async {
          print('-----------------------------scan');
          ref.read(isScanningForLineProvider.notifier).state = true;

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


            widget.movementId = result;
            if(ref.context.mounted){
              print('-----------------------------scan ${widget.movementId}');
              ref.read(scannedMovementIdForSearchProvider.notifier).update((state) => widget.movementId);
            }

          } else {
            Future.delayed(Duration(milliseconds: 1000), () {
              ref.watch(isScanningForLineProvider.notifier).state = false;
            });

            if(ref.context.mounted) {
              showErrorMessage(
                  context, ref, Messages.ERROR_SCANNING_DATA_EMPTY);
              }
          }

        },
      child: Text(Messages.OPEN_CAMERA,style: TextStyle(fontSize: themeFontSizeLarge,
          color: Colors.white),),

    );

  }

  Widget getMovementLines(List<IdempiereMovementLine> storages, double width) {

    return SliverList.separated(
        itemCount: storages.length,
        itemBuilder: (context, index) {
          final product = storages[index];
          return MovementLineCardForLine(index: index + 1, totalLength:storages.length,
            width: width - 10, movementLine: product
            , productsNotifier: widget.productsNotifier,);
        },
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10,)
        );

  }
  /*void clearData() async{
    await MemoryProducts.resetProviderStateForNewMovement(ref);
    widget.movementId = MovementsScreen.WAIT_FOR_SCAN_MOVEMENT;
    movementId.state = -1;
    widget.actionTypeInt == Memory.ACTION_FIND_MOVEMENT_BY_ID ;
  }*/
  Widget getSearchBar(BuildContext context){
    widget.title = Messages.FIND_MOVEMENT;
    var isScanning = ref.watch(isScanningForLineProvider);
    var usePhoneCamera = ref.watch(usePhoneCameraToScanForLineProvider.notifier);
    String title = Messages.MOVEMENT ;

    if(movementId.state!=null && movementId.state>0){
      title = Messages.MOVEMENT;
      widget.title = 'MV : ${widget.movementId}';
    } else {
      widget.title = Messages.FIND_MOVEMENT;
      title = Messages.MOVEMENT;
    }
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
              setState(() {});
            }, icon: Icon(usePhoneCamera.state?
            Icons.qr_code_scanner : Icons.barcode_reader, color:
            ref.watch(isDialogShowedProvider.notifier).state? Colors.red : Colors.purple,)),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: themeFontSizeNormal,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ) ,
            IconButton(onPressed:() async {
              isDialogShowed.state = true;
              setState(() {});
              await Future.delayed(Duration(milliseconds: 200), () {

              });
              getBarCode(context,false);
              },
              icon: Icon( Icons.search, color:isScanning?Colors.grey: Colors.purple,)),
            IconButton(onPressed:() async {
              isDialogShowed.state = true;
              setState(() {});
              await Future.delayed(Duration(milliseconds: 200), () {

              });
              getBarCode(context,true);},
                icon: Icon( Icons.history, color:isScanning?Colors.grey: Colors.purple,)),
            IconButton(onPressed:() async {
               widget.movementId = MovementsScreen.WAIT_FOR_SCAN_MOVEMENT;
               widget.actionTypeInt == Memory.ACTION_FIND_MOVEMENT_BY_ID ;
              },
                icon: Icon( Icons.cleaning_services, color:isScanning?Colors.grey: Colors.purple,)),

          ],
        ),
      );

  }
  Future<void> getBarCode(BuildContext context, bool history) async{

    TextEditingController controller = TextEditingController();
    if(history){
      String lastSearch = MemoryProducts.lastSearchMovementText;
      if(lastSearch.isEmpty){
        controller.text = Messages.NO_RECORDS_FOUND;
      } else {
        controller.text = lastSearch;
      }

    }
    bool stateActual = ref.watch(usePhoneCameraToScanForLineProvider.notifier).state;
    //ref.watch(usePhoneCameraToScanForLineProvider.notifier).state = true;
    //isDialogShowed.state = true;
    //FocusManager.instance.primaryFocus?.unfocus(); // Close keyboard if open
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
                autofocus: true,
                controller: controller,
                style: const TextStyle(fontSize: themeFontSizeLarge,
                color: Colors.purple,fontWeight: FontWeight.bold),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
      ),
      title: Messages.FIND_MOVEMENT_BY_ID,
      desc:  Messages.FIND_MOVEMENT_BY_ID,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
      btnOkOnPress: () async {
        isDialogShowed.state = false;
        setState(() {});
        await Future.delayed(Duration(milliseconds: 200), () {

        });

        final result = controller.text;
        bool b = result.isNotEmpty;


        if(!b){
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

        MemoryProducts.lastSearchMovementText = result;
        widget.productsNotifier.addBarcodeToSearchMovement(result);

      },
      btnCancelOnPress: () async {
        isDialogShowed.state  = false;
        setState(() {});
        await Future.delayed(Duration(milliseconds: 200), () {

        });
        return ;
      }
    ).show();

  }

  Widget getScanButton(BuildContext context) {

    final scanButton = ScanProductBarcodeButtonForLine(widget.productsNotifier,
        actionTypeInt: widget.actionTypeInt,
        pageIndex: widget.pageIndex);
      return widget.usePhoneCamera.state ?buttonScanWithPhone(context, ref):
      scanButton;


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
  bool isMovementCanEdit(BuildContext context, WidgetRef ref){

    var docStatus = ref.watch(movementDocumentStatusProvider.notifier);
    return docStatus.state == Memory.IDEMPIERE_DOC_TYPE_DRAFT;
  }

  void changeMovementIdState(WidgetRef ref,int id) async {
    ref.read(movementIdForConfirmProvider.notifier).state = id;
  }

  Widget getAddButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.green[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        onPressed: () async {
          if(MemoryProducts.movementAndLines.id != null && MemoryProducts.movementAndLines.id!>0){
            ref.read(isScanningForLineProvider.notifier).state = false;
            context.push('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/-1',
                extra: MemoryProducts.movementAndLines);
          }



        },
        child: Text(Messages.ADD_MOVEMENT_LINE,style: TextStyle(fontSize: themeFontSizeLarge,
            color: Colors.white),),
      ),
    );

  }
}