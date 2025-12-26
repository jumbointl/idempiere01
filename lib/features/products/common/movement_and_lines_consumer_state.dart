import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';

import '../../../config/theme/app_theme.dart';
import '../../auth/domain/entities/warehouse.dart';
import '../../shared/data/memory.dart';
import '../../shared/data/messages.dart';
import '../domain/idempiere/idempiere_locator.dart';
import '../domain/idempiere/idempiere_movement.dart';
import '../domain/idempiere/idempiere_movement_confirm.dart';
import '../domain/idempiere/idempiere_movement_line.dart';
import '../domain/idempiere/movement_and_lines.dart';
import '../domain/idempiere/response_async_value.dart';
import '../presentation/providers/common_provider.dart';
import '../presentation/providers/persitent_provider.dart';
import '../presentation/providers/product_provider_common.dart';
import '../presentation/screens/movement/edit_new/new_movement_card_with_locator.dart';
import '../presentation/screens/movement/edit_new/new_movement_line_card.dart';
import '../presentation/screens/movement/movement_no_data_card.dart';
import '../presentation/screens/movement/provider/new_movement_provider.dart';
import '../presentation/screens/movement/provider/products_home_provider.dart';
import 'async_value_consumer_screen_state.dart';

abstract class MovementAndLinesConsumerState<T extends ConsumerStatefulWidget>
    extends AsyncValueConsumerState<T> {
  IdempiereMovement? movement ;
  IdempiereLocator? lastSavedLocatorFrom;
  Color colorBackgroundHasMovementId = Colors.cyan[200]!;
  Color colorBackgroundNoMovementId = Colors.white;
  int sameLocator = 0;
  final double singleProductDetailCardHeight = 160;
  Warehouse? userWarehouse;
  late var movementAndLines ;
  int movementId =-1;
  @override
  late var isDialogShowed;
  late String fromPage;


  Future<MovementAndLines> getSavedMovementAndLines () async {
    var movementAndLines = await GetStorage().read(Memory.KEY_MOVEMENT_AND_LINES);
    if(movementAndLines != null){
      if(movementAndLines is MovementAndLines) return movementAndLines;
      return MovementAndLines.fromJson(movementAndLines);
    } else {
      MovementAndLines data = MovementAndLines();
      data.setUser(Memory.sqlUsersData);
      return data ;
    }
  }
  Future<void> saveMovementAndLines(MovementAndLines? movementAndLines) async {
    if(movementAndLines==null){
      GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
      return;
    }
    await GetStorage().write(Memory.KEY_MOVEMENT_AND_LINES, movementAndLines.toJson());
  }
  void removeMovementAndLines(){
    GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
  }
  Color? getColorByMovementAndLines(MovementAndLines? data){
    if(data==null ||!data.hasMovement) return Colors.white;
    if(data.canComplete) return Colors.cyan[200];
    return Colors.green[200];
  }

  void findMovementAfterDate(DateTime date, {required String inOut}) {}
  //handlling Error, no data, no record fond, initialState
  @override
  Widget asyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {

    return   MovementNoDataCard(response: result,);

  }

  @override
  void afterAsyncValueAction(WidgetRef ref, {required ResponseAsyncValue result}) {
    if(!result.success || result.data == null){
      return;
    }
    final current = ref.read(movementAndLinesProvider);
    final incoming = movementAndLines;

    // Evita reasignar si ya es el mismo (opcional)
    if (current.id != incoming.id ||
        (current.movementLines?.length ?? -1) != (incoming.movementLines?.length ?? -1)) {
      ref.read(movementAndLinesProvider.notifier).state = incoming;
    }
    if (!movementAndLines.isOnInitialState) {
      changeMovementAndLineState(ref, movementAndLines);
      ref.read(showBottomBarProvider.notifier).state =
          movementAndLines.canCompleteMovement;

    }
  }
  @override
  Widget asyncValueSuccessPanel(WidgetRef ref, {required ResponseAsyncValue result}) {


    if(result.data == null  || result.data.hasMovement == false){
      return   asyncValueErrorHandle(ref, result: result,);
      //return   MovementNoDataCard(response: result,);
    }
    MovementAndLines movementAndLines = this.movementAndLines ;
    if(!movementAndLines.hasMovement) {
      movementAndLines = result.data!;
    } else {
    }

    setWidgetMovementId(movementAndLines.id?.toString() ?? '-1');
    movementId = movementAndLines.id!;
    String argument = jsonEncode(movementAndLines.toJson());
    List<IdempiereMovementLine>? lines = movementAndLines.movementLines;
    return  Column(
      spacing: 5,
      children: [
        movementAndLines.hasMovement ?
        //
        NewMovementCardWithLocator(
          argument: argument,
          bgColor: themeColorPrimary,
          width: double.infinity,
          movementAndLines: movementAndLines,
        )
            : MovementNoDataCard(response: result,),
        if(movementAndLines.hasMovementConfirms)
          getMovementConfirm(movementAndLines.movementConfirms!),

        lines == null || lines.isEmpty ? Center(child: Text(Messages.NO_DATA_FOUND),)
            : getMovementLines(lines, getWidth()),
      ],
    );

  }
  void setWidgetMovementId(String id);
  Widget getMovementConfirm(List<IdempiereMovementConfirm> list) {
    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final data = list[index];
          String documentStatus = data.docStatus?.id ?? '';

          return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black),
              ),

              child: ListTile(leading: Text('$documentStatus :${index+1}',style: textStyleLarge), title: Text(data.documentNo ??'',style: textStyleLarge)));
        },
        separatorBuilder: (BuildContext context, int index) =>
        const SizedBox(height: 5)
    );
  }
  Widget getMovementLines(List<IdempiereMovementLine> storages, double width) {

    return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: storages.length,
        itemBuilder: (context, index) {
          final product = storages[index];
          return NewMovementLineCard(index: index + 1, totalLength:storages.length,
            width: width - 10, movementLine: product,
            canEdit: movementAndLines.canCompleteMovement ,
            showLocators: true,
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
        const SizedBox(height: 5,)
    );

  }
  void changeMovementAndLineState(WidgetRef ref,MovementAndLines? movementAndLines) async {
    int len = movementAndLines?.movementLines?.length ?? 0;
    if(len>0) {
      final allow = len > qtyOfDataToAllowScroll;
      final notifier = ref.read(allowScrollFabProvider.notifier);
      if (notifier.state != allow) {
        notifier.state = allow;
      }

      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
    ref.read(isScanningProvider.notifier).update((state) => false);


    if(movementAndLines!=null && movementAndLines.hasMovement){
      //ref.read(movementAndLinesProvider.notifier).state = movementAndLines;
      setWidgetMovementId(movementAndLines.id?.toString() ?? '-1');
    }

  }
  @override
  void initialSetting(BuildContext context, WidgetRef ref) {
    fromPage = ref.read(pageFromProvider).toString();
    ref.invalidate(persistentLocatorToProvider);
    isScanning = ref.watch(isScanningProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);

    inputString = ref.watch(inputStringProvider);
    pageIndexProdiver = ref.watch(productsHomeCurrentIndexProvider);
    actionScan = ref.read(actionScanProvider);
    movementAndLines = ref.watch(movementAndLinesProvider);



  }


}
