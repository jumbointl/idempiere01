
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/common_screen_state.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_status.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_type.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/products_home_provider.dart';
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

  static const String COMMAND_DO_NOTHING ='-1';
  String movementDateFilter;

  int actionTypeInt=0;

  MovementListScreen({super.key,required this.movementDateFilter});


  @override
  ConsumerState<ConsumerStatefulWidget> createState() => MovementListScreenState();



}

class MovementListScreenState extends CommonConsumerState<MovementListScreen> {
  IdempiereLocator? lastSavedLocatorFrom;
  Color colorBackgroundHasMovementId = Colors.cyan[200]!;
  Color colorBackgroundNoMovementId = Colors.white;
  int sameLocator = 0;
  final double singleProductDetailCardHeight = 160;
  Warehouse? userWarehouse;
  @override
  late var isDialogShowed;

  @override
  late var usePhoneCamera;


  @override
  void executeAfterShown() {
    ref.read(isScanningProvider.notifier).update((state) => false);
    final date = ref.read(selectedDateProvider);
    final isIn = ref.read(inOutProvider); // bool?
    findMovementAfterDate(date, isIn: isIn);
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
        int movementId = movement.id ?? -1;

        var iconData = isIn == null ? Icons.swap_vert : isIn ? Icons.arrow_downward : Icons.arrow_upward;
        Color? iconColor = Colors.purple;
        var textColor = isIn == null ? Colors.black : isIn ? Colors.green : Colors.red;

        int userWarehouseId = Memory.sqlUsersData.mWarehouseID?.id ?? -1;
        int warehouseFromId = movement.mWarehouseID?.id ?? -2;
        int warehouseToId = movement.mWarehouseToID?.id ?? -3;
        Color borderColor = movement.colorMovementDocumentType ?? Colors.white;

        if(userWarehouseId>0 && warehouseFromId>0 && warehouseToId>0){
          if(warehouseFromId==warehouseToId){
            iconData = Icons.swap_horiz;
            textColor = Colors.black;
            iconColor = Colors.blue;
            borderColor = Colors.grey[300]!;
          } else if(warehouseToId==userWarehouseId){
            iconData = Icons.arrow_downward ;
            textColor = Colors.black;
            iconColor = Colors.green;
            borderColor = Colors.grey[300]!;
          } else if(warehouseFromId==userWarehouseId){
            iconData = Icons.arrow_upward;
            textColor = Colors.black;
            iconColor = Colors.red;
            borderColor = Colors.grey[300]!;
          } else {
            iconData = Icons.error;
            textColor = Colors.red;
            iconColor = Colors.red;
            borderColor = Colors.white;
          }
        } else {
          iconData = Icons.error;
        }
        Color docColor = movement.colorMovementDocumentTypeDark ?? Colors.red[800]!;
        var fontSize = themeFontSizeSmall;
        /*if(movement.documentNo!=null && movement.documentNo!.length >20){
          fontSize = themeFontSizeSmall;
        }*/




        return GestureDetector(
          onTap: () {
            if(movementId<=0){
              return;
            }
            context.go('${AppRouter.PAGE_MOVEMENTS_SEARCH}/$movementId');
          },

          child: Card(
            elevation: 2.0,
            color: borderColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              leading: Icon(Icons.circle,color: docColor),
              trailing: movementId > 0
                  ? Icon(iconData,color: iconColor,) : null,
              title: Text(movement.documentNo ?? '$movementId',
                  style: TextStyle(color: textColor,fontSize: fontSize)),
              subtitle: Text(
                '${Messages.DATE}: ${movement.movementDate ?? ''}',
                  style: TextStyle(color: textColor,fontSize: fontSize),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
      const SizedBox(height: 2),
    );
  }





  @override
  void initialSetting(BuildContext context, WidgetRef ref) {

    ref.invalidate(persistentLocatorToProvider);
    isScanning = ref.watch(isScanningProvider);
    usePhoneCamera = ref.watch(usePhoneCameraToScanProvider);
    isDialogShowed = ref.watch(isDialogShowedProvider);
    inputString = ref.watch(inputStringProvider);
    pageIndexProdiver = ref.watch(productsHomeCurrentIndexProvider);
    actionScan = ref.watch(actionScanProvider);

  }

  @override
  Future<void> handleInputString({required WidgetRef ref, required String inputData,
    required int actionScan}) async {
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
        return Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              onPressed: () => popScopeAction(context, ref),
            ),
            Text('${Messages.RECORDS} :( ${list.length} )',style: textStyleTitle),
          ],
        );

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
    if(actionScan == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      return Messages.FIND_MOVEMENT;
    } else if(actionScan == Memory.ACTION_GET_LOCATOR_TO_VALUE) {
      return Messages.FIND_LOCATOR;
    }  else  if(actionScan == Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND) {
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
    final docType = ref.read(documentTyprFilterProvider);
    widget.movementDateFilter = dateString;

    movement.docStatus = IdempiereDocumentStatus(id:docType) ;
    ref.read(movementNotCompletedToFindByDateProvider.notifier).update((state) => movement);


  }
  @override
  bool get showSearchBar => false;

  @override
  List<Widget> getActionButtons(BuildContext context, WidgetRef ref) {
    final String docType = ref.watch(documentTyprFilterProvider);

    return [TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: () => _showDocumentTypeFilterSheet(context, ref),
      child: Text(
        docType, // DR / IP / CO
        style: TextStyle(
          color: Colors.purple,
          fontSize: themeFontSizeTitle,
          fontWeight: FontWeight.bold,
        ),
      ),
    )];
  }
  void _showDocumentTypeFilterSheet(BuildContext context, WidgetRef ref) {
    final String current = ref.read(documentTyprFilterProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final String selected = ref.watch(documentTyprFilterProvider);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Messages.DOCUMENT_TYPE, // crea este mensaje si aún no existe
                    style: TextStyle(
                      fontSize: themeFontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Lista de opciones
                  ...documentTypeOptions.map((type) {
                    return ListTile(
                      title: Text(
                        type, // por ahora mostramos el código; luego puedes mapearlo a texto bonito
                        style: TextStyle(
                          fontWeight: type == selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: type == selected
                          ? Icon(Icons.check, color: themeColorPrimary)
                          : null,
                      onTap: () {
                        // actualizar provider
                        ref.read(documentTyprFilterProvider.notifier).state = type;

                        // aquí puedes disparar el reload de movimientos si el filtro afecta la búsqueda
                        final date = ref.read(selectedDateProvider);
                        final isIn = ref.read(inOutProvider);
                        findMovementAfterDate(date, isIn: isIn); // reutilizando tu método

                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),

                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) {
    // TODO: implement setDefaultValues
    throw UnimplementedError();
  }

  @override
  void changeUsePhoneCameraToScanState(BuildContext context, WidgetRef ref) {
    // 🧠 Riverpod se encarga del rebuild, sin setState
    print('usePhoneCamera: $usePhoneCamera');
    ref.read(usePhoneCameraToScanProvider.notifier).state = !usePhoneCamera;
    ref.read(isDialogShowedProvider.notifier).state = false;
  }

  @override
  // TODO: implement actionScanTypeInt
  int get actionScanTypeInt => widget.actionTypeInt;


}



