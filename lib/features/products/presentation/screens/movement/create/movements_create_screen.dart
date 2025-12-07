import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/create/movement_line_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';

import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/products_scan_notifier.dart';
import '../../store_on_hand/memory_products.dart';
import 'movement_line_card_for_create.dart';
import 'no_data_created_put_away_movement_card.dart';


class MovementsCreateScreen extends ConsumerStatefulWidget {

  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_CREATE_SCREEN;
  final PutAwayMovement? putAwayMovement;
  MovementsCreateScreen({super.key, this.putAwayMovement});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>MovementsCreateScreenState();

}

class MovementsCreateScreenState extends ConsumerState<MovementsCreateScreen> {
  late ProductsScanNotifier productsNotifier ;
  final double singleProductDetailCardHeight = 160;
  late double width ;
  PutAwayMovement? putAwayMovement;
  late AsyncValue movementAsync ;
  bool startCreate = false;
  @override
  void initState() {
    productsNotifier = ref.read(scanHandleNotifierProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      /*Future.delayed(const Duration(milliseconds: 1000), () {


      });*/
      if(widget.putAwayMovement!=null && mounted && !startCreate){
        startCreate = true;
        widget.putAwayMovement!.startCreate = true;
        productsNotifier.createPutAwayMovement(ref,widget.putAwayMovement!);
      }
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context){


    width = MediaQuery.of(context).size.width;

    movementAsync = ref.watch(newPutAwayMovementProvider);
    String title ='${Messages.MOVEMENT} : ${Messages.CREATE}';

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
          //child: buttonConfirm(context, ref)
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: getBodyForNewPutAwayMovement(context, ref)
            ),
          ),
        ),
    );
  }
 Widget getDataToCreatePutAwayMovement(BuildContext context, WidgetRef ref){

   return  Container(
     padding: const EdgeInsets.symmetric(horizontal: 10),
     child: getMovementLines([MemoryProducts.newSqlDataMovementLineToCreate],
         width),
   );
 }


  Widget getBodyForNewPutAwayMovement(BuildContext context, WidgetRef ref){


         return movementAsync.when(
           data: (result) {

             if(result==null || result.id ==null || result.id!<=0){
               if(startCreate==true){
                 return getNoDataCreated(context, ref);
               } else {
                 return getDataToCreatePutAwayMovement(context, ref);
               }

             }
             MovementAndLines data = result;
             WidgetsBinding.instance.addPostFrameCallback((_) async {
               ref.read(isDialogShowedProvider.notifier).update((state) =>false);
               ref.read(isScanningProvider.notifier).update((state) => false);
               await Future.delayed(Duration(seconds: MemoryProducts.delayOnSwitchPageInSeconds));
               if(data.allCreated){
                 ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);
                 ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
                 Memory.PAGE_INDEX_STORE_ON_HAND);
                 Future.delayed(Duration.zero);

                 if (context.mounted) {
                   context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/:-1',
                   extra: data,);

                 }
               }
             });
             IdempiereMovement movement = IdempiereMovement();
             IdempiereMovementLine movementLine = IdempiereMovementLine();
             if(data.nothingCreated){
                return getNoDataCreated(context, ref);
             } else if(data.onlyMovementCreated){
               movement = data;
               int id = movement.id!;
               return  SingleChildScrollView(
                 child: Column(
                   spacing: 10,
                   children: [
                     Icon(Icons.error_rounded,size: 50,color: Colors.orange,),
                     Text('${Messages.ID} : $id', overflow: TextOverflow.ellipsis,
                     style: TextStyle(fontSize: themeFontSizeTitle,fontWeight: FontWeight.bold,
                     color: Colors.purple,)),
                     MovementCardWithoutController(
                       bgColor: Colors.cyan[800]!,
                       height: singleProductDetailCardHeight,
                       width: double.infinity,
                       movement: movement ,
                     ),
                     Text(Messages.MOVEMENT_LINE_NOT_CREATED,style: TextStyle(
                       fontSize: themeFontSizeTitle,fontWeight: FontWeight.bold,
                        color: Colors.orange[800],)),
                     SizedBox(
                       width: MediaQuery.of(context).size.width/2,
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceAround,
                         children: [
                           Expanded(
                             child: TextButton(
                                 style: TextButton.styleFrom(
                                   backgroundColor: Colors.amber[800],
                                   foregroundColor: Colors.white,
                                 ),
                                 onPressed: () async {
                                   ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_FIND_MOVEMENT_BY_ID);
                                   ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
                                   Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);
                                   ref.read(isDialogShowedProvider.notifier).update((state) =>false);
                                   MemoryProducts.movementAndLines.clearData();
                                   if(context.mounted){
                                     context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$id');
                                   }
                                 },
                                 child: Text(Messages.MOVEMENT,style: TextStyle(fontSize: themeFontSizeLarge,
                                     color: Colors.white,fontWeight: FontWeight.bold),)),
                           ),
                           Expanded(
                             child: TextButton(
                                 style: TextButton.styleFrom(
                                   backgroundColor: themeColorPrimary,
                                   foregroundColor: Colors.white,
                                 ),
                                 onPressed: () async {
                                   ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);
                                   ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
                                   Memory.PAGE_INDEX_STORE_ON_HAND);

                                   ref.read(isDialogShowedProvider.notifier).update((state) =>false);
                                   if(context.mounted){

                                     context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/:-1',
                                       extra: data,);
                                   }
                                 },
                                 child: Text(Messages.ADD_NEW_LINE,style: TextStyle(fontSize: themeFontSizeLarge,
                                     color: Colors.white,fontWeight: FontWeight.bold),)),
                           ),
                         ],
                       ),
                     )
                   ],
                 ),
               );
             } else {
               movement = data;
               movementLine = data.movementLines![0];
               int id = movement.id!;
               return  SingleChildScrollView(
                 child: Column(
                   spacing: 10,
                   children: [
                     Icon(Icons.check_circle,size: 100,color: Colors.green,),
                     Text('${Messages.ID} : $id', overflow: TextOverflow.ellipsis,
                         style: TextStyle(fontSize: themeFontSizeTitle,fontWeight: FontWeight.bold,
                           color: Colors.purple,)),
                     MovementCardWithoutController(
                       bgColor: Colors.cyan[800]!,
                       height: singleProductDetailCardHeight,
                       width: double.infinity,
                       movement: movement ,
                     ),
                     MovementLineCardWithoutController(width: width,
                          movementLine: movementLine,),
                     SizedBox(
                       width: MediaQuery.of(context).size.width/2,
                       child: TextButton(
                           style: TextButton.styleFrom(
                             backgroundColor: Colors.green[800],
                             foregroundColor: Colors.white,
                           ),
                           onPressed: () async {
                             ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_FIND_MOVEMENT_BY_ID);
                             ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_FIND_MOVEMENT_BY_ID);
                             ref.read(isDialogShowedProvider.notifier).update((state) =>false);
                             MemoryProducts.movementAndLines.clearData();
                             if (context.mounted) {
                               context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$id');
                            }
                           },
                           child: Text(Messages.OK,style: TextStyle(fontSize: themeFontSizeLarge,
                               color: Colors.white,fontWeight: FontWeight.bold),)),
                     )
                   ],
                 ),
               );
             }

           },error: (error, stackTrace) => Text('Error: $error'),
           loading: () => LinearProgressIndicator(
             minHeight: 36,
           ),
         );
  }
  Widget getNoDataCreated(BuildContext context, WidgetRef ref){
       return NoDataPutAwayCreatedCard(width: width);
  }

  Widget getMovementLines(List<IdempiereMovementLine> storages, double width) {
    return MovementLineCardForCreate(width: width,
      movementLine: storages[0],);
  }

}