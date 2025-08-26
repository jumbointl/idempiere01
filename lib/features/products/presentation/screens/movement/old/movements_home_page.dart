import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/product_store_on_hand_screen.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';
import 'package:monalisa_app_001/features/shared/data/messages.dart';
import 'package:monalisa_app_001/src/components/navigation_bar.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/products_home_provider.dart';
import 'package:monalisa_app_001/src/pages/common/scan_button.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../providers/product_provider_common.dart';
import 'movement_headers_view2.dart';
import 'multiple_page_scan_button.dart';


class MovementsHomePage extends ConsumerStatefulWidget{
  MovementsHomePage({this.actionScanner,super.key});
  int pageLength = 4; // Adjusted to be total pages - 1 for zero-based indexing
  int indexOfScanButton = 2;
  int? actionScanner = 0;
  final int totalPageOfScreen = 4;
  late var currentIndex;
  late var usePhoneCamera;
  late var isScanning;
  IconData iconCamera = Icons.photo_camera;
  IconData iconBarcodeReader = Icons.barcode_reader;
  final int pageIndex = Memory.PAGE_INDEX_MULTIPLE;
  late ProductsScanNotifier productsNotifier;
  late MultiplePageScanButton scanButton;

  late var actionTypeInt ;
  @override
  ConsumerState<MovementsHomePage> createState() => MovementsHomePageState();


  StateProvider<int> getIndexProvider() {
    return movementsHomeCurrentIndexProvider;
  }
  List<NavItemData> getNavItemData(context,ref){
    return [
      NavItemData(icon: TablerIcons.circle_plus, title:  Messages.ADD),
      NavItemData(icon: Icons.find_in_page, title: Messages.FIND),
      NavItemData(icon: iconCamera, title: ''),
      NavItemData(icon: TablerIcons.edit, title: Messages.UPDATE),
      NavItemData(icon: TablerIcons.barcode, title: Messages.UPC,
        //NavItemData(icon: TablerIcons.list, title: ''
      ),
    ];
  }

  List<Widget> getScreens() {
    return [
      //ProductSearchScreen(),
      //UpdateProductUpcScreen4(),
      ProductStoreOnHandScreen(),
      MovementHeadersView2(movementsHomePage: this,),
      //ProductStoreOnHandScreen(),
      Center(child: Text('${Messages.NOT_IMPLEMENTED}  3')),
      Center(child: Text('${Messages.NOT_IMPLEMENTED}  4')),
    ];
  }

  int getIndexOfScanButton() {
    return 2;
  }

  int getPageLength() {
    return 4;
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

          ref.read(scanStateNotifierProvider.notifier).addBarcodeByUPCOrSKUForStoreOnHande(result);
          //ref.read(scannedCodeProvider.notifier).state = result;
        }

      },
      child: Text(Messages.OPEN_CAMERA),
    );
  }

  AutoDisposeStateProvider<int> getIsLoadingProvider() {
    // TODO: implement getIsLoadingProvider
    throw UnimplementedError();
  }




  Color getIconColor(currentIndex, int i, WidgetRef ref) {
    if (currentIndex == i) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }

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

}

class MovementsHomePageState extends ConsumerState<MovementsHomePage> {

  @override
  void dispose() {
    // TODO: implement dispose
    /*ref.invalidate(selectedLocatorToProvider);
    ref.invalidate(selectedLocatorFromProvider);
    ref.invalidate(productsHomeCurrentIndexProvider);*/
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {

    widget.actionTypeInt = Memory.ACTION_NO_ACTION ;
    widget.productsNotifier = ref.watch(scanStateNotifierProvider.notifier);
    widget.isScanning = ref.watch(isScanningProvider.notifier);
    widget.usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    widget.currentIndex = ref.watch(widget.getIndexProvider());
    widget.actionScanner = ref.watch(productsHomeScannerActionProvider);
    widget.scanButton = MultiplePageScanButton(widget.productsNotifier,
        totalPageOnScreens: widget.totalPageOfScreen,
        actionTypeInt: widget.actionTypeInt,pageIndex: widget.pageIndex);
    final List<Widget> screens = widget.getScreens();
    return Scaffold(
      /*appBar: AppBar(
        automaticallyImplyLeading: true,
        leading:IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
            {
              ref.read(productsHomeCurrentIndexProvider.notifier).state = 0,
              context.go(AppRouter.PAGE_HOME)
            }
          //
        ),
        title: Text(Messages.PRODUCT),
         actions: [

          widget.usePhoneCamera.state ? IconButton(
            icon: Icon(widget.iconBarcodeReader),
            onPressed: () => {

              setState(() {
                widget.isScanning.state = false;
                widget.usePhoneCamera.state = false;
              }),

            },
          ) :  IconButton(
            icon: Icon(widget.iconCamera),
            onPressed: () => {
              setState(() {
              widget.isScanning.state = false;
              widget.usePhoneCamera.state = true;}),
             }
          ),
        ],

        bottom: getScanButton(context),
      ),*/
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: getPageIndex(context,ref), children: screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: widget.currentIndex,

        onTap: (index) {

          actionOnTap(context,ref,index);

          if (index == widget.indexOfScanButton) {
            // Handle QR Navigation Separately
           button3Pressed(context, ref);
          } else {
            // Update selected tab
            ref.read(widget.getIndexProvider().notifier).state = index > 2
                ? index - 1
                : index;
            actionOnTap(context,ref,index);
          }
        },
        navItems: widget.getNavItemData(context,ref),
      ) ,
    );
  }

  void actionOnTap(BuildContext context,WidgetRef ref, int index) async{
    FocusScope.of(context).unfocus();
    ref.read(productsHomeCurrentIndexProvider.notifier).state = index;
    switch(index){
      case 0:
        ref.read(productsHomeScannerActionProvider.notifier).state = ScanButton.SCAN_TO_HEARDER_VIEW;
        break;
      case 1:
        ref.read(productsHomeScannerActionProvider.notifier).state = ScanButton.SCAN_TO_STORE_ON_HAND;
        break;
      case 2:

        break;
      case 3:
        ref.read(productsHomeScannerActionProvider.notifier).state = ScanButton.SCAN_TO_SEARCH;

        break;
      case 4:
        break;
      default:
        break;
    }
  }

  int getPageIndex(context, WidgetRef ref) {
    if(widget.currentIndex>4){
      widget.currentIndex = 0;
    }
    if(widget.currentIndex<0){
      return 0;
    }
    return widget.currentIndex;
  }
  void button3Pressed(BuildContext context,WidgetRef ref) async{

    //widget.usePhoneCamera.state = true;
    print('---------------------button3Pressed ${widget.usePhoneCamera.state} ');
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

    print('--------------------result $result');
    if(result==null){
      print('--------------------result -1');
      ref.read(isScanningProvider.notifier).state = false;
    } else if(result !='-1'){
        widget.scanButton.handleResult(ref, result);
        //ref.read(scanStateNotifierProvider.notifier).addBarcodeByUPCOrSKUForStoreOnHande(result);
    } else {

      print('--------------------result -1');
        ref.read(isScanningProvider.notifier).state = false;
        setState(() {

        });
      }


    //widget.showErrorMessage(context, ref, Messages.NOT_IMPLEMENTED);
  }
  PreferredSize getScanButton(BuildContext context) {

    return PreferredSize(
          preferredSize: Size(double.infinity,30),
          child: SizedBox(width: MediaQuery.of(context).size.width, child:
          ref.watch(isScanningProvider.notifier).state?
          LinearProgressIndicator(minHeight: 30,) :
          widget.scanButton,
        ));

  }
}
