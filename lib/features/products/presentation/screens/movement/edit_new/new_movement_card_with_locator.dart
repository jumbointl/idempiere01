// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:slide_to_confirm/slide_to_confirm.dart';


import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/widget/show_delete_confirmation_sheet.dart';
import '../../../providers/product_provider_common.dart';
import '../provider/products_home_provider.dart';

class NewMovementCardWithLocator extends ConsumerStatefulWidget {
  Color bgColor;
  final MovementAndLines movementAndLines;
  final String argument;
  //double height = 180.0;
  double width = double.infinity;
  //MovementsScreen movementScreen;
  TextStyle movementStyle = const TextStyle(fontWeight: FontWeight.bold,color: Colors.white,
        fontSize: themeFontSizeLarge);
  NewMovementCardWithLocator({
    super.key,
    required this.bgColor,
    //required this.height,
    required this.width,
    required this.movementAndLines,
    required this.argument,
  });

  @override
  ConsumerState<NewMovementCardWithLocator> createState() => MovementHeaderCardWithLocatorState();
}


class MovementHeaderCardWithLocatorState extends ConsumerState<NewMovementCardWithLocator> {
  Widget get getActionCompleteMessage {
    if(widget.movementAndLines.canCompleteMovement){
      return GestureDetector(
        onTap: (){
            AwesomeDialog(
              context: context,
              animType: AnimType.scale,
              dialogType: DialogType.question,
              body: Center(child: Text(
                Messages.COMPLETE,
                //style: TextStyle(fontStyle: FontStyle.italic),
              ),), // correct here
              title: '${Messages.COMPLETE_MOVEMENT}?',
              desc:   '',
              //autoHide: const Duration(seconds: 3),
              btnOkOnPress: () {
                GoRouterHelper(context).go(
                    AppRouter.PAGE_MOVEMENTS_CONFIRM_SCREEN,
                    extra: widget.movementAndLines);
              },
              btnCancelOnPress: () {},
              btnOkColor: themeColorSuccessful,
              btnCancelColor: themeColorError,
              btnCancelText: Messages.CANCEL,
              btnOkText: Messages.OK,
            ).show();

        },
        child: Container(
          color: Colors.green,
          child: SizedBox(
            width: 100,
            child: Text(
               Messages.COMPLETE ,
              textAlign: TextAlign.end,
              style: widget.movementStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ) ;
    } else {
      return Text('');
    }
  }
  Widget get getActionCancelMessage {
    if(widget.movementAndLines.canCancelMovement){
      return GestureDetector(
        onTap: (){
          showDeleteConfirmationSheet(
            context: context,
            ref: ref,
            onConfirm: ({required BuildContext context, required WidgetRef ref}) async {
              print('MovementCancelScreenState card') ;
              GoRouterHelper(context).go(
                  AppRouter.PAGE_MOVEMENTS_CANCEL_SCREEN,
                  extra: widget.movementAndLines);
            }

          );
        },
        child: Container(
          color: Colors.red,
          child: SizedBox(
            width: 100,
            child: Text(
              Messages.CANCEL ,
              textAlign: TextAlign.end,
              style: widget.movementStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ) ;
    } else {
      return Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.bgColor = themeColorPrimary;
    if(widget.movementAndLines.hasMovement && widget.movementAndLines.colorMovementDocumentType!=null){
      widget.bgColor = widget.movementAndLines.colorMovementDocumentTypeDark! ;
    }
    String titleLeft='';
    String titleRight='';
    String subtitleLeft='';
    String subtitleRight='';

    String date='';
    String id='';
    String documentType = widget.movementAndLines.cDocTypeID?.identifier ?? 'DOC';
    if(widget.movementAndLines.hasMovement){      //id = movement.documentNo ?? '';
      id = widget.movementAndLines.id.toString();
      date = widget.movementAndLines.movementDate?.toString() ?? '';
      titleLeft = '${Messages.FROM}:${widget.movementAndLines.mWarehouseID?.identifier ?? ''}';
      titleRight = '${Messages.TO}:${widget.movementAndLines.mWarehouseToID?.identifier ?? ''}';
      subtitleLeft = '${Messages.DOC_STATUS}: ${widget.movementAndLines.docStatus?.identifier ?? ''}';
      //subtitleRight = getActionMessage ;
    } else {
      id = widget.movementAndLines.name ?? Messages.EMPTY;
      titleLeft =widget.movementAndLines.identifier ?? Messages.EMPTY;
    }

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        //height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.bgColor,
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

                      GoRouterHelper(ref.context).push(AppRouter.PAGE_MOVEMENT_BARCODE_LIST,
                          extra: widget.movementAndLines);

                    },
                    icon: Icon(Icons.qr_code, color: Colors.white,)),
                IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green, // Changed to transparent for IconButton
                    ),
                    onPressed: () {
                      ref.read(productsHomeCurrentIndexProvider.notifier).state =
                          Memory.PAGE_INDEX_MOVEMENT_PRINTER_SETUP;
                      ref.read(actionScanProvider.notifier).state = Memory.ACTION_FIND_MOVEMENT_BY_ID;

                      GoRouterHelper(ref.context).go(AppRouter.PAGE_MOVEMENT_PRINTER_SETUP,
                          extra: widget.movementAndLines);

                    },
                    icon: Icon(Icons.print, color: Colors.white,)), // Cha// Changed to Icon for IconButton
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
                  documentType,
                  style: widget.movementStyle,
                  overflow: TextOverflow.ellipsis,
                ),
                getActionCancelMessage,
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
                getActionCompleteMessage
              ],
            ) ,
          ],
        ),
      ),
    );
  }


}
