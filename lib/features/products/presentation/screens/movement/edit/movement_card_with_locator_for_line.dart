// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';


import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../providers/locator_provider_for_Line.dart';
import '../../../providers/movement_provider_old.dart';

class MovementCardWithLocatorForLine extends ConsumerStatefulWidget {
  Color bgColor;
  MovementAndLines movementAndLines;
  double height = 160.0;
  double width = double.infinity;
  //MovementsScreen movementScreen;
  TextStyle movementStyle = const TextStyle(fontWeight: FontWeight.bold,color: Colors.white,
        fontSize: themeFontSizeLarge);
  MovementCardWithLocatorForLine({
    super.key,
    required this.bgColor,
    required this.height,
    required this.width,
    required this.movementAndLines,
    //required this.movementScreen,
  });

  @override
  ConsumerState<MovementCardWithLocatorForLine> createState() => MovementHeaderCardWithLocatorState();
}


class MovementHeaderCardWithLocatorState extends ConsumerState<MovementCardWithLocatorForLine> {
  String DR = Memory.IDEMPIERE_DOC_TYPE_DRAFT;
  late var selectedLocatorFrom;
  late var selectedLocatorTo;
  late var isScanningLocatorTo;
  @override
  Widget build(BuildContext context) {
    String titleLeft='';
    String titleRight='';
    String subtitleLeft='';
    String subtitleRight='';

    String date='';
    String id='';
    MovementAndLines movement = widget.movementAndLines;
    bool canConfirm = movement.canCompleteMovement ;

    var docStatus = ref.watch(movementDocumentStatusProvider.notifier);

    selectedLocatorFrom =widget.movementAndLines.lastLocatorFrom;
    selectedLocatorTo = ref.watch(selectedLocatorToForLineProvider.notifier);
    isScanningLocatorTo = ref.watch(isScanningLocatorToForLineProvider.notifier);
    if(movement.id != null && movement.id!>0){
      //id = movement.documentNo ?? '';
      id = movement.id.toString();
      date = movement.movementDate?.toString() ?? '';
      titleLeft = '${Messages.FROM}:${movement.mWarehouseID?.identifier ?? ''}';
      titleRight = '${Messages.TO}:${movement.mWarehouseToID?.identifier ?? ''}';
      subtitleLeft = '${Messages.DOC_STATUS}: ${movement.docStatus?.identifier ?? ''}';


      subtitleRight = canConfirm ? Messages.CONFIRM : '';


    } else {
      id = movement.name ?? Messages.EMPTY;
      titleLeft =movement.identifier ?? Messages.EMPTY;
    }

    widget.bgColor = themeColorPrimary;
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        //height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.bgColor,
          /*image: DecorationImage(
            image: AssetImage('assets/images/supply-chain.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
          ),*/
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.shadow.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
          border: Border.all(
            color: context.outline.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        padding: EdgeInsets.only(left: 16,right:16, top: 16,bottom: 16),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(id,style: widget.movementStyle,overflow: TextOverflow.ellipsis,),
                Text(
                  date,
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green, // Changed to transparent for IconButton
                    ),
                    onPressed: () {
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.info,
                        animType: AnimType.scale,
                        title: Messages.NOT_IMPLEMENTED,
                        desc: Messages.NOT_IMPLEMENTED_YET,
                        autoHide: const Duration(seconds: 3),
                        btnOkOnPress: () {},
                        btnOkColor: themeColorSuccessful,
                      ).show();
                    },
                    icon: Icon(Icons.print, color: Colors.white,)), // Changed to Icon for IconButton
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    titleLeft,
                    style: widget.movementStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    titleRight,
                    style: widget.movementStyle,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedLocatorFrom.state.value ?? selectedLocatorFrom.state.identifier ?? '',
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  selectedLocatorTo.state.value ?? selectedLocatorTo.state.identifier ?? '',
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitleLeft,
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                isScanningLocatorTo.state ? LinearProgressIndicator(minHeight: 16,) : canConfirm ? GestureDetector(
                  onTap: (){
                    print('canConfirm: $canConfirm');
                    print('movement.id: ${movement.id}');
                    if(!movement.canCompleteMovement){
                      AwesomeDialog(
                        context: context,
                        animType: AnimType.scale,
                        dialogType: DialogType.error,
                        body: Center(child: Text(
                          Messages.MOVEMENT_ALREADY_COMPLETED,
                          //style: TextStyle(fontStyle: FontStyle.italic),
                        ),), // correct here
                        title: Messages.MOVEMENT_ALREADY_COMPLETED,
                        desc:   '',
                        autoHide: const Duration(seconds: 3),
                        btnOkOnPress: () {},
                        btnOkColor: themeColorSuccessful,
                        btnCancelColor: themeColorError,
                        btnCancelText: Messages.CANCEL,
                        btnOkText: Messages.OK,
                      ).show();
                      return;
                    } else {
                      GoRouterHelper(context).push(AppRouter.PAGE_MOVEMENTS_CONFIRM_SCREEN,
                          extra: widget.movementAndLines);
                    }

                  },
                  child: Container(
                    color: docStatus.state ==DR ? Colors.green : themeColorPrimary,
                    child: Text(
                      subtitleRight ,
                      textAlign: TextAlign.end,
                      style: widget.movementStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ) :Text(
                  subtitleRight ,
                  textAlign: TextAlign.end,
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),

              ],
            ) ,
            /*Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.movementScreen.lastButtonPressed(context, ref, Memory.lastSearch);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: themeColorPrimary,
                      //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    ),
                    child: Text(Messages.LAST, style: widget.movementStyle, overflow: TextOverflow.ellipsis,),),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.movementScreen.findButtonPressed(context, ref, '');
                      //openSearchDialog(context, ref, false);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: themeColorPrimary,
                      //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    ),
                    child: Text(Messages.FIND, style: widget.movementStyle, overflow: TextOverflow.ellipsis,),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.movementScreen.newButtonPressed(context, ref, '');

                    },
                    style: TextButton.styleFrom(
                      backgroundColor: themeColorPrimary,
                      //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    ),
                    child: Text(Messages.NEW, style: widget.movementStyle, overflow: TextOverflow.ellipsis,),
                  ),
                ),

              ],
            ),*/
          ],
        ),
      ),
    );
  }

}
