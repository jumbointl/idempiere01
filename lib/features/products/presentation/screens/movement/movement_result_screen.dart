import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/movement_provider_old.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/movement_line_card_without_controller.dart';

import '../../../domain/idempiere/idempiere_movement.dart';
import '../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../store_on_hand/memory_products.dart';
import 'movement_line_card_for_create.dart';


class MovementResultScreen extends ConsumerStatefulWidget {

  final int pageIndex = Memory.PAGE_INDEX_MOVEMENTE_CREATE_SCREEN;
  final IdempiereMovement? movement;
  final double width;
  final IdempiereMovementLine? movementLine;
  MovementResultScreen({super.key,
    required this.movement,
    required this.movementLine,
    required this.width});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>MovementResultScreenState();

}

class MovementResultScreenState extends ConsumerState<MovementResultScreen> {
  final double singleProductDetailCardHeight = 160;
  bool startCreate = false;
  late  double width ;
  late String id;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      if(mounted){
        if(!startCreate){
          startCreate = true;

        }
      }
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context){
    width = MediaQuery.of(context).size.width;
    id ='';
    if(widget.movement!=null && widget.movement!.id!=null && widget.movement!.id!>0){
      id = widget.movement!.id!.toString();
    }
    String title ='${Messages.MOVEMENT} : $id';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.green[200],
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
              child: getResultCard(context, ref)
          ),
        ),
      ),
    );
  }
  Widget getResultCard(BuildContext context, WidgetRef ref){

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Icon(Icons.check_circle,size: 100,color: Colors.green,),
            Text('${Messages.ID} : $id', overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: themeFontSizeLarge,fontWeight: FontWeight.bold,
                  color: Colors.purple,)),

            MovementLineCardWithoutController(width: width,
              movementLine: widget.movementLine!,),
            TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (context.mounted) {
                    Future.delayed(Duration(seconds: 1), () {
                      if(context.mounted){
                        String url = '${AppRouter.PAGE_MOVEMENTS_SEARCH}/$id';
                        context.go(url);
                      }
                    });

                  }
                },
                child: Text(Messages.CONTINUE,style: TextStyle(fontSize: themeFontSizeLarge,
                    color: Colors.white,fontWeight: FontWeight.bold),)),
          ],
        )
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