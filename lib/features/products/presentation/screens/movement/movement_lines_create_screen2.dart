import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/movement_line_card_without_controller.dart';

import '../../../domain/idempiere/idempiere_movement.dart';
import '../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/movement_provider_for_line.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_scan_notifier.dart';
import '../store_on_hand/memory_products.dart';
import 'movement_line_card_for_create.dart';


class MovementLinesCreateScreen2 extends ConsumerStatefulWidget {
  late ProductsScanNotifier productsNotifier ;
  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_CREATE_SCREEN;
  final IdempiereMovement? movement;
  SqlDataMovementLine movementLine;
  final double width;
  List<IdempiereMovementLine>? movementLines;
  MovementLinesCreateScreen2({super.key,
    required this.movement,
    required this.movementLine,
    required this.movementLines,
    required this.width});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>MovementLinesCreateScreenState2();

}

class MovementLinesCreateScreenState2 extends ConsumerState<MovementLinesCreateScreen2> {

  final double singleProductDetailCardHeight = 160;
  bool canCreateMovementLine = false ;
  bool startCreate = false;
  late int movementId;


  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      Future.delayed(const Duration(milliseconds: 1000), () {
        if(mounted){
          if(canCreateMovementLine){
            if(!startCreate){
              startCreate = true;
              widget.productsNotifier.createMovementLine(widget.movementLine);
            }
          }
        }
      });

    });
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    if(widget.movement!.id!=null && widget.movement!.id!>0
              && widget.movementLine.id!=null && widget.movementLine.id!>0){
      canCreateMovementLine = false;
      movementId = widget.movement?.id ?? -1;
    } else {
      canCreateMovementLine = true;

    }
    widget.productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);


    IdempiereMovement? movement = widget.movement;
    String title ='MV LINE: ';
    if(movement!=null && movement.id!=null && movement.id!>0){
      title = 'MV: ${movement.id}';
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading:IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
          {
            context.pop(),
          }
            //
        ),
        title: Text(title, overflow: TextOverflow.ellipsis,),

      ),

      bottomNavigationBar: BottomAppBar(
          height: Memory.BOTTOM_BAR_HEIGHT,
          color: themeColorPrimary,
          child: Center(
            child: Text(Messages.PLEASE_WAIT,style: TextStyle(fontSize: themeFontSizeLarge,
            color: Colors.white),overflow: TextOverflow.ellipsis,),
          )
      ),
      body: SafeArea(
          child: PopScope(
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) {
                return;
              }
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child:  SingleChildScrollView(
                child: Column(
                  spacing: 10,
                  children: [
                    getBodyForNewMovementLine2(context, ref),
                    //getConfirmBar(context, ref),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
 Widget getDataToCreateMovementLine(BuildContext context, WidgetRef ref){

   return  getMovementLines([MemoryProducts.newSqlDataMovementLineToCreate],
       widget.width);
 }
  /*Widget getBodyForNewMovementLine(BuildContext context, WidgetRef ref){
    return getDataToCreateMovementLine(context, ref);
  }*/

  Widget getBodyForNewMovementLine2(BuildContext context, WidgetRef ref){

    AsyncValue movementLineAsync = ref.watch(createNewMovementLineProvider);
         return movementLineAsync.when(
           data: (data) {

             if(data==null && !startCreate){
               return getDataToCreateMovementLine(context, ref);
             }
             WidgetsBinding.instance.addPostFrameCallback((_) async {
               if(data!=null && data.id!=null && data.id!>0){

                   if(movementId>0){
                     Future.delayed(Duration(seconds: MemoryProducts.delayOnSwitchPageInSeconds),(){

                     });
                     if(ref.context.mounted){
                       print('----------------------${AppRouter.PAGE_MOVEMENTS_SEARCH}/$movementId');
                       ref.context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$movementId');
                     }
                   }

               }
             });

             if(data==null || data.id ==null || data.id!<=0){
                return getNoDataCreated(context, ref);

             }


             return  MovementLineCardWithoutController(width: widget.width,
               movementLine: data ,);

           },error: (error, stackTrace) => Text('Error: $error'),
           loading: () => LinearProgressIndicator(
             minHeight: 36,
           ),
         );
  }

  Widget getNoDataCreated(BuildContext context, WidgetRef ref){
    return Center(child: Column(
      children: [
        Icon(Icons.error,size: 100,color: Colors.red,),
        Text(Messages.NO_DATA_CREATED, overflow: TextOverflow.ellipsis,),
      ],
    ),);
  }


  Widget buttonRedirect(BuildContext context,WidgetRef ref) {
    String idString = widget.movement!.id.toString();
     return Center(
       child: TextButton(onPressed: (){
         context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$idString');
       }, child: Text(Messages.OK,style: TextStyle(fontSize: themeFontSizeLarge,
           fontWeight: FontWeight.bold,
           color: Colors.white),overflow: TextOverflow.ellipsis,),)
     );
  }

  Widget getMovementLines(List<IdempiereMovementLine> storages, double width) {
    return MovementLineCardForCreate(width: width ,
      movementLine: storages[0],);



  }
  Widget getConfirmBar(BuildContext context, WidgetRef ref) {
    if(startCreate){
      return buttonRedirect(context, ref);
    }
    return  Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 10,
        children: [
          Expanded(
            child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                onPressed: (){ Navigator.pop(context);},
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
                    AwesomeDialog(
                      context: context,
                      animType: AnimType.scale,
                      dialogType: DialogType.info,
                      body: Center(child: Text(
                        Messages.READY_TO_CREATE_MOVEMENT_LINE,
                        //style: TextStyle(fontStyle: FontStyle.italic),
                      ),), // correct here
                      title:  Messages.READY_TO_CREATE_MOVEMENT_LINE,
                      desc:   '',
                      //autoHide: const Duration(seconds: 3),
                      btnOkOnPress: () {
                        /*ref.read(isCreatingMovementLineProvider.notifier).state = true;
                        ref.read(newSqlDataMovementLineProvider.notifier).update((state)
                        => widget.movementLine);*/

                        widget.productsNotifier.createMovementLine(widget.movementLine);
                      },
                      btnOkColor: themeColorSuccessful,
                      btnCancelColor: themeColorError,
                      btnCancelText: Messages.CANCEL,
                      btnOkText: Messages.OK,
                    ).show();
                    return;

                },
                child: Text(Messages.CONFIRM)
            ),
          ),
        ]) ;

  }

}