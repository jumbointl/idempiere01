

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_status.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/custom_app_bar.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/products_home_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/widget/no_data_card.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/async_value_consumer_simple_state.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../common/time_utils.dart';
import '../../../../common/widget/date_filter_row_panel.dart';
import '../../../../common/widget/date_range_filter_row_panel.dart';
import '../../../../domain/idempiere/movement_and_lines.dart';
import '../../../../domain/idempiere/response_async_value.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/persitent_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../movement_no_data_card.dart';


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

class MovementListScreenState extends AsyncValueConsumerSimpleState<MovementListScreen> {

  @override
  void executeAfterShown() {
    ref.read(isScanningProvider.notifier).update((state) => false);
    final dates = ref.read(selectedDatesProvider);
    final inOut = ref.read(inOutFilterProvider);
    findMovementAfterDates(dates, inOut: inOut);
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
             selectedDatesProvider: selectedDatesProvider,
             values: ['ALL', 'IN', 'OUT', 'SWAP'],
             onOk: (date, inOut) {
             findMovementAfterDates(date, inOut: inOut);

         },
             onScanButtonPressed: () {
               context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/-1/-1');
             }

         ),
         mainDataAsync.when(
          data: (ResponseAsyncValue response) {

            if(!response.isInitiated) return   MovementNoDataCard(response: response,);

            WidgetsBinding.instance.addPostFrameCallback((_) async {


            });
            List<IdempiereMovement> list = response.data ?? [];
            if(list.isEmpty){
              return MovementNoDataCard(response: response,);
            }
            return getMovements(list);

          },error: (error, stackTrace) => Text('Error'),
           loading: () => LinearProgressIndicator(
             minHeight: 36,
           ),
             ),
       ]
     );
  }

  Widget getMovements(List<IdempiereMovement> movements) {
    final inOut = ref.watch(inOutFilterProvider);

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


        return GestureDetector(
          onTap: () {
            if(movementId<=0){
              showErrorMessage(context, ref, Messages.NOT_ENABLED);
              return;
            }
            Clipboard.setData(ClipboardData(text: movement.documentNo ?? ''));
            /*ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${Messages.COPIED_TO_CLIPBOARD}: ${movement.documentNo ?? ''}'),
              duration: const Duration(seconds: 1),
            ));*/
            String docStatus = movement.docStatus?.id ?? '';

            if(movement.docStatus?.id == 'DR'){
              context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
              /*String documentNo = movement.documentNo ?? '-1';
              if(RolesApp.cantConfirmMovement){
                showMovementOptionsSheet(context: context, documentNo: documentNo, movementId:
                   movementId, docStatus:docStatus);
              } else {
                context.go('${AppRouter.PAGE_MOVEMENTS_EDIT}/$movementId/1');
              }*/


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
        //if(movements==null) return Text(Messages.MOVEMENT_SEARCH,style: textStyleTitle);
        WidgetsBinding.instance.addPostFrameCallback((_) async {


        });
        if(!response.isInitiated) return NoDataCard();

        List<IdempiereMovement> list = response.data ?? [];
        String title = Messages.MOVEMENT_SEARCH;
        if(list.isEmpty || list[0].id==null || list[0].id!<0) {
          //return Text(Messages.MOVEMENT_SEARCH,style: textStyleTitle);
          return commonAppBarTitle(
            onBack: ()=>popScopeAction(context, ref),
          );
        }
        title = '${Messages.RECORDS} : ${list.length}';
        return commonAppBarTitle(
          title: title,
          showBackButton: true,
          onBack: ()=>popScopeAction(context, ref),
        );

        /*return Row(
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
            Text('${Messages.RECORDS} : ${list.length}',style: textStyleLarge),
          ],
        );*/

      },error: (error, stackTrace) => Text('Error: $error'),
      loading: () => LinearProgressIndicator(
        minHeight: 36,
      ),
    );

  }


 /* @override
  BottomAppBar getBottomAppBar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
        height: 105,
        color: Colors.cyan[200] ,
        child: MovementDateFilterRow(
          onOk: (date, isIn) {
            findMovementAfterDate(date, isIn: isIn);
          },
        ),
    );


  }*/

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
  void findMovementAfterDates(DateTimeRange dates, {required String inOut}) {
    String startDateString = dates.start.toString().substring(0,10);
    String endDateString = dates.end.toString().substring(0,10);
    Memory.sqlUsersData.mWarehouseID ;
    IdempiereWarehouse warehouse =Memory.sqlUsersData.mWarehouseID!;
    MovementAndLines? movement = MovementAndLines(
      filterMovementDateStartAt: startDateString,
      filterMovementDateEndAt: endDateString,

    );


    switch(inOut){
      case 'IN':
        movement.mWarehouseToID = warehouse;
        movement.filterWarehouseTo = warehouse ;
        break;
      case 'OUT':
        movement.mWarehouseID = warehouse;
        movement.filterWarehouseFrom = warehouse ;
        break;
      case 'SWAP':
        movement.mWarehouseID = warehouse;
        movement.mWarehouseToID = warehouse;
        movement.filterWarehouseFrom = warehouse ;
        movement.filterWarehouseTo = warehouse ;
        break;
      case 'ALL':
        movement.mWarehouseID = null;
        movement.mWarehouseToID = null;
        movement.filterWarehouseFrom = null ;
        movement.filterWarehouseTo = null ;
        break;
    }
    final docType = ref.read(documentTypeFilterProvider);
    widget.movementDateFilter = startDateString;

    movement.docStatus = IdempiereDocumentStatus(id:docType) ;
    movement.filterDocumentStatus =  IdempiereDocumentStatus(id:docType) ;
    ref.read(movementNotCompletedToFindByDateProvider.notifier).update((state) => movement);


  }
  /*void findMovementAfterDate(DateTime date, {required String inOut}) {
    String startDateString = date.toString().substring(0,10);
    Memory.sqlUsersData.mWarehouseID ;
    IdempiereWarehouse warehouse =Memory.sqlUsersData.mWarehouseID!;
    MovementAndLines? movement = MovementAndLines(
      filterMovementDateStartAt: startDateString,

    );


    switch(inOut){
      case 'IN':
        movement.mWarehouseToID = warehouse;
        movement.filterWarehouseTo = warehouse ;
        break;
      case 'OUT':
        movement.mWarehouseID = warehouse;
        movement.filterWarehouseFrom = warehouse ;
        break;
      case 'SWAP':
        movement.mWarehouseID = warehouse;
        movement.mWarehouseToID = warehouse;
        movement.filterWarehouseFrom = warehouse ;
        movement.filterWarehouseTo = warehouse ;
        break;
      case 'ALL':
        movement.mWarehouseID = null;
        movement.mWarehouseToID = null;
        movement.filterWarehouseFrom = null ;
        movement.filterWarehouseTo = null ;
        break;
    }
    final docType = ref.read(documentTyprFilterProvider);
    widget.movementDateFilter = startDateString;

    movement.docStatus = IdempiereDocumentStatus(id:docType) ;
    movement.filterDocumentStatus =  IdempiereDocumentStatus(id:docType) ;
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
            _showDocumentTypeFilterSheet(context, ref);
          },
          child: Text(
            docType,
            style: const TextStyle(color: Colors.purple),
          ),
        ),
      ),
    ];
  }
  void _showDocumentTypeFilterSheet(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    var documentTypeOptions = documentTypeOptionsAll;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // permite ver el borde redondeado
      builder: (context) {
        return Container(
          height: screenHeight * 0.7,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,               // fondo del modal
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final String selected = ref.watch(documentTypeFilterProvider);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      'Movement ${Messages.DOCUMENT_TYPE}',
                      style: TextStyle(
                        fontSize: themeFontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Expanded(
                    child: ListView(
                      children: documentTypeOptions.map((type) {
                        final color = _colorForDocType(type);

                        return Card(
                          elevation: 3,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            tileColor: color,
                            title: Text(
                              type,
                              style: TextStyle(
                                fontWeight: type == selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            trailing: type == selected
                                ? Icon(Icons.check_circle,
                                color: Colors.purple, size: 26)
                                : null,
                            onTap: () {
                              // actualizar provider
                              ref.read(documentTypeFilterProvider.notifier).state = type;

                              // recargar búsqueda
                              final dates = ref.read(selectedDatesProvider);
                              final inOut = ref.read(inOutFilterProvider);
                              findMovementAfterDates(dates, inOut: inOut);

                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Colores para cada tipo de documento
  Color _colorForDocType(String code) {
    switch (code) {
      case 'DR': // Draft / Borrador
        return Colors.grey.shade200;
      case 'CO': // Completed
        return Colors.green.shade200;
      case 'IP': // In Progress
        return Colors.cyan.shade200;
      case 'VO': // In Progress
        return Colors.amber.shade200;
      default:
        return Colors.grey.shade200;
    }
  }


  @override
  Future<void> setDefaultValues(BuildContext context, WidgetRef ref) async {
  }


  @override
  int get actionScanTypeInt => widget.actionTypeInt;




}



