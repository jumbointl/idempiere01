


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/features/products/common/async_value_consumer_screen_state.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_status.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/custom_app_bar.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';

import '../../../../../auth/domain/entities/warehouse.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/time_utils.dart';
import '../../../../common/widget/date_filter_row_panel.dart';
import '../../../../common/widget/date_range_filter_row_panel.dart';
import '../../../../common/widget/show_document_type_filter_sheet.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/persitent_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../movement_no_data_card.dart';


class MovementListScreenNew extends ConsumerStatefulWidget {

  int countScannedCamera =0;
  late var allowedLocatorId;
  bool isMovementSearchedShowed = false;

  static const String COMMAND_DO_NOTHING ='-1';
  List<String> movementDateFilter;

  int actionTypeInt=0;

  MovementListScreenNew({super.key,required this.movementDateFilter});


  @override
  ConsumerState<ConsumerStatefulWidget> createState() => MovementListScreenNewState();



}

class MovementListScreenNewState extends AsyncValueConsumerState<MovementListScreenNew> {
  IdempiereLocator? lastSavedLocatorFrom;
  Color colorBackgroundHasMovementId = Colors.cyan[200]!;
  Color colorBackgroundNoMovementId = Colors.white;
  int sameLocator = 0;
  final double singleProductDetailCardHeight = 160;
  Warehouse? userWarehouse;
  @override
  late var isDialogShowed;

  @override
  void executeAfterShown() {
    ref.read(isScanningProvider.notifier).update((state) => false);
    final dates = ref.read(selectedDatesProvider);
    final inOut = ref.read(inOutFilterProvider);
    findMovementAfterDates(ref: ref, dates: dates, inOut: inOut);
    ref.read(pageFromProvider.notifier).state = 1 ;
  }

  @override
  double getWidth(){ return MediaQuery.of(context).size.width - 30;}




  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) {
    return Colors.cyan[200];
  }

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync => ref.watch(findMovementNotCompletedByDateProvider);

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {

     return Column(
       children: [
         DateRangeFilterRowPanel(
           values: ['ALL', 'IN', 'OUT', 'SWAP'],
           selectedDatesProvider: selectedDatesProvider,
           onOk: (dates, inOut) {
           findMovementAfterDates(ref: ref, dates: dates, inOut: inOut);
         },
           onScanButtonPressed: () {
             context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/-1/-1');
           }
         ),
         mainDataAsync.when(
          data: (ResponseAsyncValue response) {
            if(!response.isInitiated) {
              return   asyncValueResultResumeCard(ref, response);
            }
            if(response.isInitiated){
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                   actionAfterAsyncValueShow(ref, response);

              });
            }
            late List<IdempiereMovement> list;
            if(response.success){
              if(response.data!=null){
                list = IdempiereMovement.fromJsonString(response.data!) ?? [];
                if(list.isEmpty) return  asyncValueResultResumeCard(ref, response);
                return getMovements(list,response.success);
              } else {
                return  asyncValueResultResumeCard(ref, response);
              }

            } else {

              return  asyncValueResultResumeCard(ref, response);
            }




          },error: (error, stackTrace) => Text('Error'),
           loading: () => LinearProgressIndicator(
             minHeight: 36,
           ),
             ),
       ]
     );
  }
  Widget asyncValueResultResumeCard(WidgetRef ref,ResponseAsyncValue response) {
    return MovementNoDataCard(response: response,);
  }

  Widget getMovements(List<IdempiereMovement> movements, bool success) {
    // Lee el valor actual de IN/OUT desde Riverpod
    final inOut = ref.watch(inOutFilterProvider); // true = IN, false = OUT
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movements.length,
      itemBuilder: (context, index) {
        final movement = movements[index];
        int movementId = movement.id ?? -1;
        late IconData iconData;
        late Color textColor;
        switch(inOut) {
          case 'IN':
            iconData = Icons.arrow_downward;
            textColor = Colors.green;
            break;
          case 'OUT':
            iconData = Icons.arrow_upward;
            textColor = Colors.red;
            break;
          case 'SWAP':
            iconData = Icons.swap_horiz;
            textColor = Colors.blue;
            break;
          case 'ALL':
            iconData = Icons.all_inclusive;
            textColor = Colors.black;
            break;

        }
        Color? iconColor = Colors.purple;


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
              showErrorMessage(context, ref, Messages.NOT_ENABLED);
              return;
            }
            Clipboard.setData(ClipboardData(text: movement.documentNo ?? ''));
            String docStatus = movement.docStatus?.id ?? '';

            if(movement.docStatus?.id == 'DR'){
              context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');

            } else if(movement.docStatus?.id == 'IP'){
              String documentNo = movement.documentNo ?? '-1';
              if(RolesApp.canConfirmMovementWithConfirm){
                showMovementOptionsSheet(context: context, documentNo: documentNo, movementId:
                movementId, docStatus:docStatus);
              } else {
                context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
              }


            } else {
              context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
            }

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

  void showMovementOptionsSheet({
    required BuildContext context,
    required String documentNo,
    required int movementId,
    required String docStatus,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // para ver el borde redondeado
      builder: (BuildContext bc) {
        return FractionallySizedBox(
          heightFactor: 0.7, // 70% de la pantalla
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 8),

                  // INVENTORY MOVE (azul)
                  Card(
                    color: Colors.blue,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: docStatus=='IP' ? ListTile(
                      leading: const Icon(Icons.inventory, color: Colors.white),
                      title: Text(
                        Messages.MOVE_CONFIRM,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/mInOut/moveconfirm/$documentNo');
                      },
                    ) : Container(),
                  ),

                  // VIEW MOVEMENT (ciano)
                  Card(
                    color: Colors.cyan,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.line_style, color: Colors.white),
                      title: Text(
                        Messages.VIEW_MOVEMENT,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
                      },
                    ),
                  ),

                  // CANCEL (gris)
                  Card(
                    color: Colors.grey,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.cancel, color: Colors.white),
                      title: Text(
                        Messages.CANCEL,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }




  @override
  void initialSetting(BuildContext context, WidgetRef ref) {

    ref.invalidate(persistentLocatorToProvider);
    isScanning = ref.watch(isScanningProvider);
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
      data: (ResponseAsyncValue response) {
        if(!response.isInitiated) {
          return Text(Messages.MOVEMENT_SEARCH,style: textStyleTitle);
        }
        if(response.success && response.data!=null) {
          List<IdempiereMovement> list = response.data;
          String title = Messages.MOVEMENT_SEARCH;
          if (list.isEmpty || list[0].id == null || list[0].id! < 0) {
            return commonAppBarTitle(
              onBack: () => popScopeAction(context, ref),
            );
          }
          title = '${Messages.RECORDS} : ${list.length}';
          return commonAppBarTitle(
            title: title,
            showBackButton: true,
            onBack: () => popScopeAction(context, ref),
          );
        } else {
          return Text(Messages.MOVEMENT_SEARCH,style: textStyleTitle);
        }

      },error: (error, stackTrace) => Text('Error: $error'),
      loading: () => LinearProgressIndicator(
        minHeight: 36,
      ),
    );

  }


  Future<void> findMovementAfterDates({required WidgetRef ref,required DateTimeRange dates, required String inOut}) async {
    String startDateString = dates.start.toString().substring(0,10);
    String endDateString = dates.end.toString().substring(0,10);
    Memory.sqlUsersData.mWarehouseID ;
    IdempiereWarehouse warehouse =Memory.sqlUsersData.mWarehouseID!;

    MovementAndLines movement  = MovementAndLines(
      filterMovementDateStartAt: startDateString,
      filterMovementDateEndAt: endDateString,
    );

    switch(inOut){
      case 'IN':
        movement.mWarehouseToID = warehouse;
        break;
      case 'OUT':
        movement.mWarehouseID = warehouse;
        break;
      case 'SWAP':
        movement.mWarehouseID = warehouse;
        movement.mWarehouseToID = warehouse;
        break;
      case 'ALL':
        movement.mWarehouseID = null;
        movement.mWarehouseToID = null;
        break;
    }
    final docType = ref.read(documentTypeFilterProvider);
    widget.movementDateFilter = [startDateString,endDateString];

    movement.docStatus = IdempiereDocumentStatus(id:docType) ;
    ref.read(movementNotCompletedToFindByDateProvider.notifier).update((state) => movement);


  }
  /*Future<void> findMovementAfterDate(DateTime date, {required String inOut}) async {
    String dateString = date.toString().substring(0,10);
    Memory.sqlUsersData.mWarehouseID ;
    IdempiereWarehouse warehouse =Memory.sqlUsersData.mWarehouseID!;
    IdempiereMovement? movement = IdempiereMovement(
      movementDate: dateString,
    );
    MovementAndLines m ;

    switch(inOut){
      case 'IN':
        movement.mWarehouseToID = warehouse;
        break;
      case 'OUT':
        movement.mWarehouseID = warehouse;
        break;
      case 'SWAP':
        movement.mWarehouseID = warehouse;
        movement.mWarehouseToID = warehouse;
        break;
      case 'ALL':
        movement.mWarehouseID = null;
        movement.mWarehouseToID = null;
        break;
    }
    final docType = ref.read(documentTyprFilterProvider);
    widget.movementDateFilterStart = dateString;

    movement.docStatus = IdempiereDocumentStatus(id:docType) ;
    ref.read(movementNotCompletedToFindByDateProvider.notifier).update((state) => movement);


  }*/
  @override
  bool get showSearchBar => false;

  @override
  List<Widget> getActionButtons(BuildContext context, WidgetRef ref) {
    final String docType = ref.watch(documentTypeFilterProvider);

    return [

      Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: Colors.white,
          ),
          onPressed: () {
            showDocumentTypeFilterMultipleDatesSheet(context: context, ref: ref,
            onDataChange: findMovementAfterDates,
            title: Messages.DOCUMENT_TYPE,
            documentTypeOptions: documentTypeOptionsAll,
            selectedProvider: documentTypeFilterProvider,
            datesRangeProvider: selectedDatesProvider,

            );
          },
          child: Text(
            docType,
            style: const TextStyle(color: Colors.purple),
          ),
        ),
      ),
    ];
  }




  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {
  }


  @override
  int get actionScanTypeInt => widget.actionTypeInt;

  void actionAfterAsyncValueShow(WidgetRef ref, ResponseAsyncValue response) {
    if(!response.success){
      showResultBottomSheetMessages(ref: ref, title: Messages.ERROR,
          message: response.message ?? Messages.ERROR,
          success: response.success, onOk: ()async{

        },) ;
    }
  }

  @override
  void afterAsyncValueAction(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement afterAsyncValueAction
  }

  @override
  Widget asyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueErrorHandle
    throw UnimplementedError();
  }

  @override
  Widget asyncValueSuccessPanel(WidgetRef ref, {required ResponseAsyncValue result}) {
    // TODO: implement asyncValueSuccessPanel
    throw UnimplementedError();
  }



}



