import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement_line.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/movement_provider_old.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/movement_line_card_without_controller.dart';

import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/movement_provider_for_line.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/products_scan_notifier.dart';
import '../../store_on_hand/memory_products.dart';
import '../movement_line_card_for_create.dart';
import '../products_home_provider.dart';


class MovementLinesCreateScreen extends ConsumerStatefulWidget {

  late ProductsScanNotifier productsNotifier ;
  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_CREATE_SCREEN;
  final MovementAndLines movementAndLines;
  final double width;
  String argument;
  MovementLinesCreateScreen({super.key,
    required this.movementAndLines,
    required this.width, required this.argument});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>MovementLinesCreateScreenState();

}

class MovementLinesCreateScreenState extends ConsumerState<MovementLinesCreateScreen> {
  late ProductsScanNotifier productsNotifier ;
  final double singleProductDetailCardHeight = 160;
  bool startCreate = false;
  late  double width ;
  late MovementAndLines movementAndLines ;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(const Duration(microseconds: 100),(){

      });
      SqlDataMovementLine movementLine = movementAndLines.movementLineToCreate ??
          SqlDataMovementLine();
      if(mounted && movementAndLines.canCreateMovementLine()){
        if(!startCreate){
          startCreate = true;
          productsNotifier.createMovementLine(movementLine);
        }
      }
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context){
    movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));
    width = MediaQuery.of(context).size.width;
    productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);

    String title ='${Messages.MOVEMENT_LINE} : ${Messages.CREATE}';

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
          child: SingleChildScrollView(
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: getBody(context, ref)
            ),
          ),
        ),
      ),
    );
  }
  Widget getDataToCreate(BuildContext context, WidgetRef ref){

    return  Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: getMovementLines([MemoryProducts.newSqlDataMovementLineToCreate],
          width),
    );
  }


  Widget getBody(BuildContext context, WidgetRef ref){

    AsyncValue movementAsync = ref.watch(createNewMovementLineProvider);
    return movementAsync.when(
      data: (data) {
        if(data==null){
          if(startCreate){
            return getNoDataCreated(context, ref);
          } else {
            return getDataToCreate(context, ref);
          }

        }
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if(data!=null && data.id!=null && data.id! > 0){
            if (ref.context.mounted) {
              await Future.delayed(Duration(
                  seconds: MemoryProducts.delayOnSwitchPageInSeconds), () {

              });

              ref.read(actionScanProvider.notifier).update((state) =>
              Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);
              ref.read(productsHomeCurrentIndexProvider.notifier).update((
                  state) =>
              Memory.PAGE_INDEX_STORE_ON_HAND);
              Future.delayed(Duration.zero);
              movementAndLines.movementLines ??= [];
              movementAndLines.movementLines!.add(data);
              if (context.mounted) {
                context.go(
                  '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/-1',
                  extra: movementAndLines,);
              }

            }
          }
        });
        IdempiereMovement movement = IdempiereMovement();
        IdempiereMovementLine movementLine = IdempiereMovementLine();
        if(data==null || data.id==null || data.id!<=0){
          return getNoDataCreated(context, ref);

        } else  {
          movement = movementAndLines;
          movementLine = data;
          int id = movement.id!;
          return  Column(
            spacing: 10,
            children: [
              Icon(Icons.check_circle,size: 50,color: Colors.green,),
              Text('${Messages.ID} : $id', overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: themeFontSizeLarge,fontWeight: FontWeight.bold,
                    color: Colors.purple,)),
              MovementCardWithoutController(
                bgColor: Colors.cyan[800]!,
                height: singleProductDetailCardHeight,
                width: double.infinity,
                movement: movement ,
              ),
              MovementLineCardWithoutController(width: width,
                movementLine: movementLine,),
              TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.yellow[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (context.mounted) {
                      if(context.mounted){
                        context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$id');
                      }
                    }
                  },
                  child: Text(Messages.MOVEMENT,style: TextStyle(fontSize: themeFontSizeLarge,
                      color: Colors.white,fontWeight: FontWeight.bold),))
            ],
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