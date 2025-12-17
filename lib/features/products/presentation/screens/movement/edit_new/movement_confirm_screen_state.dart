import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/common_consumer_state.dart';
import '../../../../domain/idempiere/idempiere_locator.dart';
import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../providers/locator_provider.dart';
import '../../../providers/movement_confirm_state_notifier.dart';
import '../../../providers/movement_provider_for_line.dart';
import '../../../providers/movement_provider_old.dart';
import '../../../providers/product_provider_common.dart';
import '../../store_on_hand/memory_products.dart';
import '../provider/new_movement_provider.dart';
import '../provider/products_home_provider.dart';
import 'movement_confirm_screen.dart';

class MovementConfirmScreenState extends CommonConsumerState<MovementConfirmScreen> {
  late MovementConfirmStateNotifier stateNotifier ;
  AsyncValue get actionAsync => ref.watch(confirmMovementProvider);
  String DR = Memory.IDEMPIERE_DOC_TYPE_DRAFT;
  bool started = false;
  late IdempiereLocator lastSavedLocatorTo;
  late IdempiereWarehouse warehouse;
  late IdempiereWarehouse warehouseTo;
  bool success = false;
  bool canConfirm=false;
  MovementAndLines? movementAndLines;

  String get getTitleMessage => Messages.CONFIRM_MOVEMENT;

  bool get isActionSuccess {
    String doc = widget.movementAndLines.docStatus?.id ?? '';
    print('isActionSuccess $doc = ${Memory.IDEMPIERE_DOC_TYPE_COMPLETED}');
    return doc == Memory.IDEMPIERE_DOC_TYPE_COMPLETED;
  }

  String get getErrorMessagesTitle => Messages.MOVEMENT_NOT_COMPLETED;
  String get getSuccessMessagesTitle => Messages.MOVEMENT_COMPLETED;
  int count = 0 ;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      actionAfterShow(ref);

    });

  }
  @override
  Widget build(BuildContext context) {
    if(widget.argument.isNotEmpty){
      movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    }


    if(!widget.movementAndLines.hasMovementLines && movementAndLines!=null
        && movementAndLines!.hasMovementLines){
      widget.movementAndLines = movementAndLines!;

    }
    stateNotifier = ref.watch(movementConfirmStateNotifierProvider.notifier);
    warehouse = widget.movementAndLines.mWarehouseID ?? IdempiereWarehouse();
    warehouseTo = widget.movementAndLines.mWarehouseID ?? IdempiereWarehouse();
    if(widget.movementAndLines.hasLastLocatorTo){
      lastSavedLocatorTo = widget.movementAndLines.lastLocatorTo!;
    }
    canConfirm = movementAndLines?.canCompleteMovement ?? false;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: success ? Colors.green[200] : Colors.white,
          title: ListTile(title: Text(getTitleMessage,style: TextStyle(fontSize: themeFontSizeLarge),),
            subtitle: Text('MV : ${widget.movementAndLines.id ?? ''}',style: TextStyle(fontSize:
            themeFontSizeNormal),),
          ),
          leading:IconButton(
              icon: const Icon(Icons.arrow_back),
            onPressed: () => {
              popScopeAction(context,ref),

            },
          ),
        ),
        body: PopScope(
          canPop: false, // el back físico no hace pop automático
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) {
              // Si por alguna razón ya poppeó, no hagas nada.
              return;
            }
            popScopeAction(context, ref);

          },
          child: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                height: widget.height,
                width: widget.width,
                padding: EdgeInsets.all(10),
                child:  actionAsync.when(data: (data){
                  print('data ::${data?.toJson() ?? 'null'}');
                  print(count.toString());
                  count++;

                  if(data == null){
                    print('data :: null');
                    return Container(
                      decoration: BoxDecoration(
                        color: widget.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          getMovementCard(context, ref),
                        ],
                      ),
                    );
                  }
                  started = true ;
                  MovementAndLines m = data ;
                  print('data :: ${m.docStatus?.toJson() ?? 'null'}');
                  widget.movementAndLines.docStatus = data.docStatus;

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if(data!=null && data.id != null && data.id!>0){
                      if(widget.movementAndLines.docStatus!=null && widget.movementAndLines.docStatus!.id!=null){
                        success = isActionSuccess;
                        /*if(success){
                          String message = Messages.SUCCESS;
                          showSuccessMessage(context, ref, message);
                        } else {
                          String message = Messages.ERROR;
                          showErrorMessage(context, ref, message);
                        }

                        await Future.delayed(Duration(seconds: 5));
                        */

                        ref.read(movementIdForMovementLineSearchProvider.notifier).state = null;
                        ref.read(scannedMovementIdForSearchProvider.notifier).state = '';
                        ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
                        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);
                        ref.read(actionScanProvider.notifier).update((state) =>
                        Memory.ACTION_FIND_MOVEMENT_BY_ID);

                        int? id =  widget.movementAndLines.id ??-1 ;
                        print('${AppRouter.PAGE_MOVEMENTS_EDIT}/$id/-1');
                        await Future.delayed(Duration(seconds: MemoryProducts.delayOnSwitchPageInSeconds));
                        if(context.mounted){
                          context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$id/-1');
                        }
                      }
                    }


                  });
                  widget.movementAndLines.docStatus = data.docStatus;
                  return getResultCard(context, ref, data);

                },
                    error:(error, stackTrace) => Text('Error: $error'),
                    loading: ()=>LinearProgressIndicator(minHeight: 36,)),
              ),
            ),
          ),
        ));
  }
  Widget getMovementCard(BuildContext context,WidgetRef ref){
    String titleLeft='';
    String titleRight='';
    String subtitleLeft='';
    String subtitleRight='';

    String date='';
    String id='';
    IdempiereMovement movement = widget.movementAndLines ?? IdempiereMovement();
    id = movement.documentNo ?? 'XXX';

    if(movement.id != null && movement.id!>0){
      id = movement.documentNo ?? '';
      date = movement.movementDate?.toString() ?? '';
      titleLeft = '${Messages.FROM}:${movement.mWarehouseID?.identifier ?? ''}';
      titleRight = '${Messages.TO}:${movement.mWarehouseToID?.identifier ?? ''}';
      subtitleLeft = '${Messages.DOC_STATUS}: ${movement.docStatus?.identifier ?? ''}';
      String docStatus = '';
      Future.delayed(Duration(milliseconds: 100), () {
        docStatus = movement.docStatus?.id ?? '';
      });

      subtitleRight = docStatus ==DR ? Messages.CONFIRM : '';

    } else {
      id = movement.name ?? Messages.EMPTY;
      titleLeft =movement.identifier ?? Messages.EMPTY;
    }
    return Container(
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id,
                style: widget.movementStyle,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                date,
                style: widget.movementStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titleLeft,
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  titleRight,
                  style: widget.movementStyle,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ref.watch(selectedLocatorFromProvider).value ?? '',
                style: widget.movementStyle,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                ref.watch(selectedLocatorToProvider).value ?? '',
                style: widget.movementStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitleLeft,
                style: widget.movementStyle,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitleRight ,
                textAlign: TextAlign.end,
                style: widget.movementStyle,
                overflow: TextOverflow.ellipsis,
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget getConfirmBar(BuildContext context, WidgetRef ref) {

    return canConfirm ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 10,
        children: [
          Expanded(
            child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                onPressed: (){ popScopeAction(context, ref);},
                child: Text(
                  Messages.CANCEL,
                )
            ),
          ),
          Expanded(
            child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
                onPressed: (){
                  if(!canConfirm){
                    AwesomeDialog(
                      context: context,
                      animType: AnimType.scale,
                      dialogType: DialogType.error,
                      body: Center(child: Text(
                        Messages.MOVEMENT_ALREADY_COMPLETED,
                        //style: TextStyle(fontStyle: FontStyle.italic),
                      ),), // correct here
                      title: Messages.MOVEMENT_ALREADY_COMPLETED,
                      desc:   '',
                      autoHide: const Duration(seconds: 3),
                      btnOkOnPress: () {},
                      btnOkColor: themeColorSuccessful,
                      btnCancelColor: themeColorError,
                      btnCancelText: Messages.CANCEL,
                      btnOkText: Messages.OK,
                    ).show();
                    return;
                  }
                  stateNotifier.confirmMovement(widget.movementAndLines.id);
                  //Navigator.pop(context);
                },
                child: Text(Messages.CONFIRM)
            ),
          ),
        ]) :
    Container(
        decoration: BoxDecoration(
          color: Colors.green[800],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Icon(Icons.check_circle,color: Colors.white,size: 100,),
            Text(Messages.MOVEMENT_COMPLETED,style:
            TextStyle(fontSize: themeFontSizeLarge,color: Colors.white),)
          ],
        ));

  }
  void showAutoCloseErrorDialog(BuildContext context, WidgetRef ref, String message,int seconds) {
    while (!context.mounted) {
      Future.delayed(const Duration(milliseconds: 500));

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
      autoHide: Duration(seconds: seconds),
      btnOkOnPress: () {},
      btnOkColor: Colors.amber,
      btnCancelText: Messages.CANCEL,
      btnOkText: Messages.OK,
    ).show();
    return;
  }

  Widget getResultCard(BuildContext context, WidgetRef ref,MovementAndLines data) {
    String title = Messages.MOVEMENT_NOT_COMPLETED ;
    Color bgColor = Colors.yellow[200]!;
    String subtitle = 'MV: ${data.documentNo ?? ''}';
    if(isActionSuccess) {
      title = getSuccessMessagesTitle ;
      bgColor = Colors.green[200]!;

    } else {
      bgColor = Colors.yellow[200]!;
      title =getErrorMessagesTitle;
      subtitle = '$subtitle : ${data.name ?? ''}';
    }

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child:  SingleChildScrollView(
        child: Column(
          spacing: 10,
          children: [
            Text(title,style: TextStyle(fontSize: themeFontSizeLarge),),
            Text(subtitle,style: TextStyle(fontSize: themeFontSizeNormal),),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData, required int actionScan}) {
    // TODO: implement handleInputString
    throw UnimplementedError();
  }

  Future<void> actionAfterShow(WidgetRef ref) async{
    if (movementAndLines?.canCompleteMovement == false) {
      String message = Messages.ERROR_CANNOT_COMPLETE_MOVEMENT;
      showAutoCloseErrorDialog(context, ref,
          message,5);
      return ;
    }
    if(!started){
      started = true;
      stateNotifier.confirmMovement(widget.movementAndLines.id);
    }
  }
  void popScopeAction(BuildContext context, WidgetRef ref) {
    int movementId = widget.movementAndLines.id ?? -1;
    // Restaurar configuración de navegación del Home
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;

    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_MOVEMENT_BY_ID;

    // Redirigir
    context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
  }
}
