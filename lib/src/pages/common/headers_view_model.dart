import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/products/presentation/providers/product_provider_common.dart';
import '../../../features/products/presentation/providers/products_scan_notifier.dart';
import '../../../features/products/presentation/screens/movement/products_home_provider.dart';
import '../../../features/shared/data/messages.dart';

abstract class HeadersViewModel extends ConsumerStatefulWidget {
  HeadersViewModel({super.key});
  late var isLoading ;
  double headerCardHeight = 160.0;
  double headerCardWidth = double.infinity;
  late ProductsScanNotifier productsNotifier ;
  late var usePhoneCamera;
  late AsyncValue asyncView;
  late AsyncValue asyncTable;
  @override
  ConsumerState<HeadersViewModel> createState() => HeadersViewModelState();

  Widget getHeaderCard(BuildContext context,WidgetRef ref);


  Widget getRecentTransaction(AsyncValue asyncTable, BuildContext context, WidgetRef ref, {required double width});
  void findButtonPressed(BuildContext context, WidgetRef ref, String result) ;
  void newButtonPressed(BuildContext context, WidgetRef ref, String result) ;
  void lastButtonPressed(BuildContext context, WidgetRef ref, String result) ;
  void confirmButtonPressed(BuildContext context, WidgetRef ref, String result) ;
  void usePhoneCameraToScan(BuildContext context, WidgetRef ref) ;
  Widget getButtonScanWithPhone(BuildContext context,WidgetRef ref);
  Widget getViewTitle(BuildContext context, WidgetRef ref) ;
  AsyncValue getAsyncCard(BuildContext context, WidgetRef ref);
  AsyncValue getAsyncTable(BuildContext context, WidgetRef ref);
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

class HeadersViewModelState extends ConsumerState<HeadersViewModel> {




  @override
  Widget build(BuildContext context) {
    widget.asyncView = widget.getAsyncCard(context, ref);
    widget.asyncTable = widget.getAsyncTable(context, ref);
    widget.productsNotifier = ref.watch(scanStateNotifierProvider.notifier);
    widget.headerCardWidth = MediaQuery.of(context).size.width-30 ;
    widget.isLoading = ref.watch(productsHomeIsLoadingProvider);
    widget.usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: widget.getViewTitle(context,ref),
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
        bottom: PreferredSize(preferredSize: Size.fromHeight(widget.headerCardHeight.h),
        child: Column(
          children: [
            widget.asyncView.when(data: (data) => widget.getHeaderCard(context, ref),
          error: (error, stackTrace) => Text(error.toString()),
          loading: () => LinearProgressIndicator(minHeight: widget.headerCardHeight,)),
            SizedBox(height: 10.h,),
          ],
        )),
    ),
     body:  widget.getRecentTransaction(widget.asyncTable, context, ref, width: widget.headerCardWidth),

      bottomNavigationBar: widget.getButtonScanWithPhone(context,ref),
    );

  }


}
