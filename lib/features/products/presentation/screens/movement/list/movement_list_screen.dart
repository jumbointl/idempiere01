
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/common/common_screen_state.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../auth/domain/entities/warehouse.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/persitent_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/store_on_hand_provider.dart';
import '../../../widget/movement_no_data_card.dart';


class MovementListScreen extends ConsumerStatefulWidget {

  int countScannedCamera =0;
  late var allowedLocatorId;
  bool isMovementSearchedShowed = false;


  MovementListScreen({super.key});


  @override
  ConsumerState<ConsumerStatefulWidget> createState() => MovementListScreenState();

  void confirmMovementButtonPressed(BuildContext context, WidgetRef ref, String string) {

  }

  void lastMovementButtonPressed(BuildContext context, WidgetRef ref, String lastSearch) {}

  void findMovementButtonPressed(BuildContext context, WidgetRef ref, String s) {}

  void newMovementButtonPressed(BuildContext context, WidgetRef ref, String s) {}


}

class MovementListScreenState extends CommonConsumerState<MovementListScreen> {
  IdempiereLocator? lastSavedLocatorFrom;
  Color colorBackgroundHasMovementId = Colors.cyan[200]!;
  Color colorBackgroundNoMovementId = Colors.white;
  int sameLocator = 0;
  final ScrollController _scrollController = ScrollController();
  final double singleProductDetailCardHeight = 160;
  Warehouse? userWarehouse;
  @override
  late var isDialogShowed;

  @override
  late var usePhoneCamera;



  @override
  void executeAfterShown() {
    ref.read(isScanningProvider.notifier).update((state) => false);
  }

  @override
  double getWidth(){ return MediaQuery.of(context).size.width - 30;}




  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.cyan[200];
  }

  @override
  AsyncValue get mainDataAsync => ref.watch(findMovementNotCompletedByDateProvider);

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {

     return mainDataAsync.when(
      data: (movements) {
        if(movements==null) return   MovementNoDataCard();
        WidgetsBinding.instance.addPostFrameCallback((_) async {


        });
        List<IdempiereMovement> list = movements;
        return getMovements(list);

      },error: (error, stackTrace) => Text('Error'),
       loading: () => LinearProgressIndicator(
         minHeight: 36,
       ),
    );
  }

  Widget getMovements(List<IdempiereMovement> movements) {
    // Lee el valor actual de IN/OUT desde Riverpod
    final isIn = ref.watch(inOutProvider); // true = IN, false = OUT


    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movements.length,
      itemBuilder: (context, index) {
        final movement = movements[index];
        final movementId = movement.id ?? 0;

        var iconData = isIn == null ? Icons.swap_vert : isIn ? Icons.arrow_downward : Icons.arrow_upward;
        var iconColor = Colors.purple;
        var textColor = isIn == null ? Colors.black : isIn ? Colors.green : Colors.red;

        int userWarehouseId = Memory.sqlUsersData.mWarehouseID?.id ?? -1;
        int warehouseFromId = movement.mWarehouseID?.id ?? -2;
        int warehouseToId = movement.mWarehouseToID?.id ?? -3;
        if(userWarehouseId>0 && warehouseFromId>0 && warehouseToId>0){
          if(warehouseFromId==warehouseToId){
            iconData = Icons.swap_vert;
            textColor = Colors.black;
          } else if(warehouseToId==userWarehouseId){
            iconData = Icons.arrow_downward ;
            textColor = Colors.green;
          } else if(warehouseFromId==userWarehouseId){
            iconData = Icons.arrow_upward;
            textColor = Colors.red;
          } else {
            iconData = Icons.error;
            textColor = Colors.blueAccent;
          }
        } else {
          iconData = Icons.error;
        }

        return ListTile(
          trailing: movementId > 0
              ? IconButton(
            icon: Icon(iconData,color: iconColor,),
            onPressed: () {
              context.push('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$movementId');
            },
          )  : null,
          title: Text(movement.documentNo ?? '$movementId',style: TextStyle(color: textColor)),
          subtitle: Text(
            '${Messages.DATE}: ${movement.movementDate ?? ''}',
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
      const SizedBox(height: 10),
    );
  }





  @override
  void initialSetting(BuildContext context, WidgetRef ref) {

    ref.invalidate(persistentLocatorToProvider);
    isScanning = ref.watch(isScanningProvider.notifier);
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
    isDialogShowed = ref.watch(isDialogShowedProvider.notifier);
    scrollToTop = ref.watch(scrollToUpProvider.notifier);
    scrollController = ScrollController();
    inputString = ref.watch(inputStringProvider.notifier);
    pageIndexProdiver = ref.watch(productsHomeCurrentIndexProvider.notifier);
    actionScan = ref.read(actionScanProvider.notifier);

  }

  @override
  Future<void> handleInputString(BuildContext context, WidgetRef ref, String inputData) async {
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return mainDataAsync.when(
      data: (movements) {
        if(movements==null) return Text(Messages.MOVEMENT_SEARCH,style: textStyleTitle);
        WidgetsBinding.instance.addPostFrameCallback((_) async {


        });
        List<IdempiereMovement> list = movements;
        if(list.isEmpty || list[0].id==null || list[0].id!<0) return Text(Messages.MOVEMENT_SEARCH,style: textStyleTitle);
        return Text('${Messages.RECORDS} ${list.length}',style: textStyleTitle);

      },error: (error, stackTrace) => Text('Error: $error'),
      loading: () => LinearProgressIndicator(
        minHeight: 36,
      ),
    );

  }

  @override
  void addQuantityText(BuildContext context, WidgetRef ref,
      TextEditingController quantityController,int quantity) {
    if(quantity==-1){
      quantityController.text = '';
      return;
    }
    String s =  quantityController.text;
    String s1 = s;
    String s2 ='';
    if(s.contains('.')) {
      s1 = s.split('.').first;
      s2 = s.split('.').last;
    }

    String r ='';
    if(s.contains('.')){
      r='$s1$quantity.$s2';
    } else {
      r='$s1$quantity';
    }

    int? aux = int.tryParse(r);
    if(aux==null || aux<=0){
      String message =  '${Messages.ERROR_QUANTITY} $quantity';
      showErrorMessage(context, ref, message);
      return;
    }
    quantityController.text = aux.toString();

  }


  @override
  BottomAppBar getBottomAppBar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
        height: 120,
        color: Colors.cyan[200] ,
        child: MovementDateFilterRow(
          onOk: (date, isIn) {
            findMovementAfterDate(date, isIn: isIn);
          },
        ),
    );


  }

  @override
  String get hinText {
    if(actionScan.state == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      return Messages.FIND_MOVEMENT;
    } else if(actionScan.state == Memory.ACTION_GET_LOCATOR_TO_VALUE) {
      return Messages.FIND_LOCATOR;
    }  else  if(actionScan.state == Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND) {
      return Messages.SKU_UPC;
    }  else {
      return Messages.INPUT_DATA;
    }

  }
 @override
  void findMovementAfterDate(DateTime date, {required bool? isIn}) {
    String dateString = date.toString().substring(0,10);
    Memory.sqlUsersData.mWarehouseID ;
    IdempiereWarehouse warehouse =Memory.sqlUsersData.mWarehouseID!;
    IdempiereMovement? movement = IdempiereMovement(
      movementDate: dateString,
    );
    if(isIn!=null){
      if(isIn){
        movement.mWarehouseToID = warehouse;
      } else {
        movement.mWarehouseID = warehouse;
      }
    } else {
      movement.mWarehouseID = warehouse;
      movement.mWarehouseToID = warehouse;
    }

    ref.read(movementNotCompletedToFindByDateProvider.notifier).update((state) => movement);


  }
  @override
  bool get showSearchBar => false;

  @override
  Widget getActionButtons(BuildContext context, WidgetRef ref) {
    bool? isIn = ref.watch(inOutProvider);

    return IconButton(
      icon: Icon(
        isIn ==null ? Icons.swap_vert : isIn ? Icons.arrow_downward : Icons.arrow_upward,
        color:  isIn ==null ? Colors.black : isIn ? Colors.green : Colors.red,
      ),
      onPressed: () {
      },
    );
  }

  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) {
    // TODO: implement setDefaultValues
    throw UnimplementedError();
  }


}



