import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/movement_provider_old.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/movement_line_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';

import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/put_away_movement.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/products_scan_notifier.dart';
import '../../store_on_hand/memory_products.dart';
import '../movement_line_card_for_create.dart';


class MovementsCreateScreenOld extends ConsumerStatefulWidget {

  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_CREATE_SCREEN;
  final PutAwayMovement? putAwayMovement;

  MovementsCreateScreenOld({super.key,required this.putAwayMovement});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>MovementsCreateScreenOldState();

}

class MovementsCreateScreenOldState extends ConsumerState<MovementsCreateScreenOld> {
  late ProductsScanNotifier productsNotifier ;
  final double singleProductDetailCardHeight = 160;
  bool startCreate = false;
  late  double width ;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      if(mounted && widget.putAwayMovement!=null && !startCreate){
        if(widget.putAwayMovement!.canCreatePutAwayMovement()==PutAwayMovement.SUCCESS){
          startCreate = true;
          productsNotifier.createPutAwayMovement(ref,widget.putAwayMovement!);
        }
      }
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context){
    width = MediaQuery.of(context).size.width;
    productsNotifier = ref.read(scanHandleNotifierProvider.notifier);

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

    AsyncValue movementAsync = ref.watch(newPutAwayMovementProvider);
         return movementAsync.when(
           data: (data) {
             //bool b = startedCreatePutAwayMovement.state ?? false;
             if(data==null || data.isEmpty){
               if(startCreate){
                 return getNoDataCreated(context, ref);
               } else {
                 return getDataToCreatePutAwayMovement(context, ref);
               }

             }
             WidgetsBinding.instance.addPostFrameCallback((_) async {
               await Future.delayed(Duration(seconds: MemoryProducts.delayOnSwitchPageInSeconds));
               if(data!=null && data.length ==2){
                 if (context.mounted) {
                   int id = data[0].id ?? -1;
                   context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$id');

                 }
               }
             });
             IdempiereMovement movement = IdempiereMovement();
             IdempiereMovementLine movementLine = IdempiereMovementLine();
             if(data==null || data.isEmpty){
                return getNoDataCreated(context, ref);

             } else if(data.length==1){
               movement = data[0];
               int id = movement.id!;
               return  SingleChildScrollView(
                 child: Column(
                   spacing: 10,
                   children: [
                     Icon(Icons.error_rounded,size: 100,color: Colors.orange,),
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
                       child: TextButton(
                           style: TextButton.styleFrom(
                             backgroundColor: Colors.amber[800],
                             foregroundColor: Colors.white,
                           ),
                           onPressed: () async {
                             if(context.mounted){
                               context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$id');
                             }
                           },
                           child: Text(Messages.OK,style: TextStyle(fontSize: themeFontSizeLarge,
                               color: Colors.white,fontWeight: FontWeight.bold),)),
                     )
                   ],
                 ),
               );
             } else {
               movement = data[0];
               movementLine = data[1];
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
    return Center(child: Column(
      children: [
        Icon(Icons.error,size: 100,color: Colors.red,),
        Text(Messages.NO_DATA_CREATED, overflow: TextOverflow.ellipsis,),
        TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
            ),
            onPressed: (){
              if (context.mounted) {
                ref.invalidate(startedCreateNewPutAwayMovementProvider);
                if(context.mounted){
                  Navigator.pop(context);
                }
              }
            },
            child: Text(Messages.BACK,style: TextStyle(fontSize: themeFontSizeLarge,
                color: Colors.white,fontWeight: FontWeight.bold),))
      ],
    ),);
  }

  Widget getMovementLines(List<IdempiereMovementLine> storages, double width) {
    return MovementLineCardForCreate(width: width,
      movementLine: storages[0],);
  }

}