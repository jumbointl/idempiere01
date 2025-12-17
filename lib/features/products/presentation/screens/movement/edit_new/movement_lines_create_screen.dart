import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement_line.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/movement_provider_old.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_card_without_controller.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/create/movement_line_card_without_controller.dart';

import '../../../../domain/idempiere/idempiere_movement.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/movement_provider_for_line.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/products_scan_notifier.dart';
import '../../store_on_hand/memory_products.dart';
import '../create/movement_line_card_for_create.dart';
import '../provider/products_home_provider.dart';


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
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SqlDataMovementLine movementLine = movementAndLines.movementLineToCreate ??
          SqlDataMovementLine();
      if(mounted && movementAndLines.canCreateMovementLine()){
        if(!startCreate){
          startCreate = true;
          int aux = movementLine.mMovementID?.id ?? -1;
          print('print Movement Line Create createMovementLine $aux');
          productsNotifier.createMovementLine(movementLine);
        }
      }
    });

  }
  @override
  Widget build(BuildContext context){

    movementAndLines = MovementAndLines.fromJson(jsonDecode(widget.argument));

    print('print Movement Line Create build 1 ${movementAndLines.movementLineToCreate?.id}');
    width = MediaQuery.of(context).size.width;
    productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);

    String title ='${Messages.MOVEMENT_LINE} : ${Messages.CREATE}';
    print('print Movement Line Create build 2');
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading:IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
            {
              popScopeAction(context, ref),
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
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {

            if (didPop) {
              return;
            }
            popScopeAction(context, ref);
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
    print('print Movement Line Create getDataToCreate');
    return  Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: getMovementLines([MemoryProducts.newSqlDataMovementLineToCreate],
          width),
    );
  }


  Widget getBody(BuildContext context, WidgetRef ref){
    print('print Movement Line getBody 1');
    AsyncValue movementAsync = ref.watch(createNewMovementLineProvider);
    print('print Movement Line getBody 11');
    return movementAsync.when(
      data: (data) {
        print('print Movement Line getBody 0');
        if(data==null){
          print('print Movement Line getBody 3');
          if(startCreate){
            print('print Movement Line getBody 4');
            return getNoDataCreated(context, ref);

          } else {
            print('print Movement Line getBody 5');
            return getDataToCreate(context, ref);
          }

        }
        print('print Movement Line getBody 6');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if(data!=null && data.id!=null && data.id! > 0){
            if (ref.context.mounted) {
              await Future.delayed(Duration(
                  seconds: MemoryProducts.delayOnSwitchPageInSeconds), () {

              });


              movementAndLines.movementLines ??= [];
              movementAndLines.movementLines!.add(data);
              if (context.mounted) {
                ref.invalidate(pageFromProvider);
                context.go(
                  '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/-1',
                  extra: movementAndLines,);
              }

            }
          }
        });
        print('print Movement Line getBody 8');
        IdempiereMovement movement = IdempiereMovement();
        IdempiereMovementLine movementLine = IdempiereMovementLine();
        if(data==null || data.id==null || data.id!<=0){
          return getNoDataCreated(context, ref);

        } else  {
          movement = movementAndLines;

          movementLine = data;
          int id = movement.id ?? -1;
          if(data.id==null || data.id!<=0){
            showErrorMessage(context, ref, '${Messages.NO_DATA_CREATED} ID: $id');
            return getNoDataCreated(context, ref);
          }
          print('print Movement Line getBody 9');
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
                        context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$id/-1');
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
  void popScopeAction(BuildContext context, WidgetRef ref) {

    // Restaurar configuración de navegación del Home
    ref.read(productsHomeCurrentIndexProvider.notifier).state =
        Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN;

    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_MOVEMENT_BY_ID;
    int movementId = movementAndLines.id ?? -1;
    // Redirigir
    context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
  }
}