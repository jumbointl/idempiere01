
/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/data_create_screen.dart';
import '../../../providers/product_provider_common.dart';
import '../../store_on_hand/memory_products.dart';
import '../widget/movement_line_create_result_screen.dart';
import 'no_data_created_put_away_movement_card.dart';

class MovementCreateScreen extends DataCreateScreen {
  final PutAwayMovement putAwayMovement;

  const MovementCreateScreen({
    super.key,
    required this.putAwayMovement,
    super.closeMode,
  });

  @override
  ConsumerState<MovementCreateScreen> createState() =>
      _MovementCreateScreenState();
}

class _MovementCreateScreenState
    extends DataCreateScreenState<MovementCreateScreen> {
  late final ProductsScanNotifier productsNotifier;

  bool startCreateLocal = false;
  String? productUPC;

  @override
  void initState() {
    super.initState();

    productsNotifier = ref.read(scanHandleNotifierProvider.notifier);
    productUPC = widget.putAwayMovement.movementLineToCreate?.uPC ?? '-1';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // English: Start creation only once
      if (!mounted) return;
      if (startCreateLocal) return;

      startCreateLocal = true;
      widget.putAwayMovement.startCreate = true;

      productsNotifier.createPutAwayMovement(ref, widget.putAwayMovement);
    });
  }

  @override
  String get title => '${Messages.MOVEMENT} : ${Messages.CREATE}';

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newPutAwayMovementProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: async.when(
        loading: () => const LinearProgressIndicator(minHeight: 36),
        error: (e, _) => Text('Error: $e'),
        data: (result) {
          // English: No movement created yet
          if (result == null || result.id == null || result.id! <= 0) {
            if (widget.putAwayMovement.startCreate == true) {
              return NoDataPutAwayCreatedCard(
                width: MediaQuery.of(context).size.width,
              );
            }
            // English: Display data that is going to be created
            return _dataToCreateCard(context);
          }

          final MovementAndLines data = result;

          // English: Small post-processing once data is ready
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            ref.read(isDialogShowedProvider.notifier).state = false;
            ref.read(isScanningProvider.notifier).state = false;

            // Optional delay behavior kept from your original flow
            await Future.delayed(
              Duration(seconds: MemoryProducts.delayOnSwitchPageInSeconds),
            );

            if (!mounted) return;

            if (data.allCreated) {

              ref.read(actionScanProvider.notifier).state =
                  Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;

              if(context.mounted) {
                context.go(
                '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/-1',
                extra: data,
              );
              }
            } else if(data.onlyMovementCreated){
              ref.read(actionScanProvider.notifier).state =
                  Memory.ACTION_FIND_MOVEMENT_BY_ID;
              if(context.mounted) {
                context.go(
                  '${AppRouter.PAGE_MOVEMENTS_EDIT}/${data.id ?? -1}'

                );
              }
            }

          });

          // English: Render the result using the dedicated screen widget
          return MovementLineCreateResultScreen(
            movementAndLines: data,
            closeMode: widget.closeMode,
            // English: this one can decide close behavior too
          );
        },
      ),
    );
  }

  Widget _dataToCreateCard(BuildContext context) {
    final qty = widget.putAwayMovement.movementLineToCreate?.movementQty ?? 0;
    final from = widget.putAwayMovement.movementLineToCreate?.mLocatorID?.value ??
        widget.putAwayMovement.movementLineToCreate?.mLocatorID?.identifier ??
        '--';
    final to =
        widget.putAwayMovement.movementLineToCreate?.mLocatorToID?.value ??
            widget.putAwayMovement.movementLineToCreate?.mLocatorToID?.identifier ??
            '--';
    final product =
        widget.putAwayMovement.movementLineToCreate?.mProductID?.identifier ??
            '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Messages.PLEASE_WAIT,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${Messages.PRODUCT}: $product'),
            Text('${Messages.LOCATOR_FROM}: $from'),
            Text('${Messages.LOCATOR_TO}: $to'),
            Text('${Messages.QUANTITY}: ${Memory.numberFormatter0Digit.format(qty)}'),
          ],
        ),
      ),
    );
  }

  @override
  void onClose(BuildContext context, WidgetRef ref) {
    // English: Reset common flags
    ref.read(isScanningProvider.notifier).state = false;
    ref.read(isDialogShowedProvider.notifier).state = false;

    if (widget.closeMode == DataCreateCloseMode.closeOnly) {
      Navigator.pop(context);
      return;
    }

    // English: Custom close behavior (page navigation)
    context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productUPC');
  }
}
*/




import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/input_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/common_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/common/store_on_hand_navigation.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/create/movement_line_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';

import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/actions/create_movement_and_lines_action.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/products_scan_notifier.dart';
import '../../../providers/store_on_hand/action_notifier.dart';
import '../../../providers/store_on_hand_for_put_away_movement.dart';
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

  String? productUPC;
  @override
  void initState() {
    productsNotifier = ref.read(scanHandleProvider.notifier);
    productUPC = widget.putAwayMovement?.movementLineToCreate?.uPC ?? '-1' ;
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      if(widget.putAwayMovement!=null && mounted && !startCreate){
        startCreate = true;
        widget.putAwayMovement!.startCreate = true;
        final act =ref.read(createMovementAndLinesActionProvider);
        await act.setAndFire(widget.putAwayMovement!);
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
            popScopeAction(context,ref),

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
              popScopeAction(context,ref);
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
                 if (context.mounted) {
                   ref.invalidate(pageFromProvider);
                   ref.invalidate(productStoreOnHandCacheProvider);
                   context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/-1',
                   extra: data,);

                 }
               } else if(data.onlyMovementCreated){
                 bool? retry = await openBottomSheetConfirmationDialog(
                     ref: ref,
                     title: Messages.MOVEMENT_LINE_NOT_CREATED,
                     message: '${Messages.RETRY}?');
                 if(retry==true) {
                   MovementAndLines m = data;
                   m.movementLineToCreate = data.movementLineToCreate;
                   String argument = jsonEncode(m.toJson());
                   if (context.mounted) {
                     await openMovementLinesCreateBottomSheet(
                         context: context, ref: ref,
                         movementAndLines: m,
                         argument: argument
                     );
                   }
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
                                   ref.read(isDialogShowedProvider.notifier).update((state) =>false);
                                   MemoryProducts.movementAndLines.clearData();
                                   if(context.mounted){
                                     context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$id/-1');
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
                               context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$id/-1');
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

  void popScopeAction(BuildContext context, WidgetRef ref) {
    ref.read(isScanningProvider.notifier).update((state) => false);
    ref.read(quantityToMoveProvider.notifier).update((state) => 0);
    ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND;
    context.go('${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/$productUPC');
  }

}
