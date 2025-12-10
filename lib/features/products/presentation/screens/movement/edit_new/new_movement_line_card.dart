import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/input_dialog.dart';
import '../../../../common/messages_dialog.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../providers/product_provider_common.dart';
import '../provider/new_movement_provider.dart';
class NewMovementLineCard extends ConsumerStatefulWidget {
  final IdempiereMovementLine movementLine;
  final double width;
  final int index;
  final int totalLength;
  bool? showLocators = false;
  final bool canEdit;

  var productsNotifier;
  NewMovementLineCard( {required this.width, required this.movementLine, super.key,
    required this.index, required this.totalLength, this.showLocators, required this.canEdit});


  @override
  ConsumerState<NewMovementLineCard> createState() => NewMovementLineCardState();
}

class NewMovementLineCardState extends ConsumerState<NewMovementLineCard> {

  double? height =210;
  late AsyncValue quantityAsync ;
  late var movementQuatity;
  @override
  Widget build(BuildContext context) {

    final int lineId = widget.movementLine.id ?? widget.index;
    quantityAsync = ref.watch(editQuantityToMoveProvider(lineId));
    movementQuatity = ref.watch(movementLineQuantityToMoveProvider(lineId));

    widget.productsNotifier = ref.watch(scanStateNotifierForLineProvider);
    String quantity = Memory.numberFormatter0Digit.format(widget.movementLine.movementQty ?? 0);
    Color backGroundColor = Colors.cyan[800]!;
    TextStyle textStyleTitle = TextStyle(fontSize: themeFontSizeNormal, color: Colors.white,fontWeight: FontWeight.bold);
    TextStyle textStyle = TextStyle(fontSize: themeFontSizeSmall, color: Colors.white,fontWeight: FontWeight.bold);
    TextStyle textStyleTitleBlue = TextStyle(fontSize: themeFontSizeNormal, color: Colors.white,
        fontWeight: FontWeight.bold,backgroundColor: themeColorPrimary);
    String productName = widget.movementLine.productName ?? '' ;
    if(widget.showLocators??false){
      height = 190;
    } else {
      height = 150;
    }
    if(productName.length>40) height = (height!+10.0);
    return Container(
      height: height,
      width: widget.width,
      decoration: BoxDecoration(
        color: backGroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Text(widget.movementLine.productName ?? '--',style: textStyle,),
          Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: widget.width / 5,


                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Messages.ID,style: textStyleTitle),
                    if(widget.canEdit)
                      GestureDetector(
                        onTap: (){
                          editQuantityToMoveDialog(context, ref);
                        },
                        child: Text(Messages.QUANTITY_SHORT, style: textStyleTitleBlue),
                      )
                    else Text(Messages.QUANTITY_SHORT,style: textStyleTitle),
                    Text(Messages.UPC,style: textStyleTitle),
                    Text(Messages.SKU,style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(Messages.FROM,style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(Messages.TO,style: textStyleTitle),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.movementLine.id ?? '--'}',style: textStyleTitle),
                    widget.canEdit ? quantityAsync.when(
                        data: (result) {
                          // If there is no result yet, show current quantity in normal style
                          if (result == null) {
                            return Text(quantity, style: textStyleTitle);
                          }

                          final bool isSuccess = result > 0;

                          // Which quantity text will be displayed?
                          final String displayedQuantity = isSuccess
                              ? Memory.numberFormatter0Digit.format(result)
                              : quantity;

                          // Which style will be used?
                          final TextStyle displayedStyle = textStyleTitle;
                          // Post-frame side effects (snackbar/dialog)
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (result == null || !context.mounted) return;

                            if (isSuccess) {
                              int id = widget.movementLine.mMovementID?.id ?? -1;
                              if(id>0){
                                String goToPage =  '${AppRouter.PAGE_MOVEMENTS_EDIT}/$id/-1';
                                showSuccessMessageThenGoTo(context, ref, goToPage);
                              } else {
                                showErrorMessage(context, ref, '${Messages.ERROR} : $id');
                              }

                            } else {
                              showErrorMessage(context, ref, Messages.ERROR);
                            }
                          });

                          return Text(
                            displayedQuantity,
                            style: displayedStyle,
                          );
                        },
                        error: (error, stackTrace) => Text('Error: $error'),
                        loading: () => LinearProgressIndicator(minHeight: 36,)
                    ) : Text(quantity,style: textStyleTitle),
                    Text(widget.movementLine.uPC ?? '--',style: textStyleTitle),
                    Text(widget.movementLine.sKU ?? '--',style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(widget.movementLine.mLocatorID?.identifier ?? '--',style: textStyleTitle),
                    if(widget.showLocators ?? false)Text(widget.movementLine.mLocatorToID?.identifier ?? '--',style: textStyleTitle),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> editQuantityToMoveDialog(BuildContext context, WidgetRef ref) async {
    TextEditingController quantityController = TextEditingController();
    ref.read(isDialogShowedProvider.notifier).state = true;
    setState(() {

    });
    await Future.delayed(Duration(milliseconds: 100));

    double qtyOnHand = widget.movementLine.movementQty ?? 0;
    quantityController.text = Memory.numberFormatter0Digit.format(qtyOnHand);
    final int lineId = widget.movementLine.id ?? widget.index;
    if(context.mounted) {
      AwesomeDialog(
        context: context,
        animType: AnimType.scale,
        dialogType: DialogType.noHeader,
        body: SizedBox(
          height: 300,
          width: 350, //Set the desired height for the AlertDialog
          child: Column(
            spacing: 5,
            children: [
              Text(Messages.QUANTITY_TO_MOVE, style: TextStyle(
                fontSize: fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: TextField(
                  autofocus: false,
                  enabled: false,
                  controller: quantityController,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: fontSizeLarge,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10,),
              _numberButtons(context, ref, quantityController),
            ],
          ),
        ),
        title: Messages.QUANTITY_TO_MOVE,
        desc: '',
        btnOkOnPress: () async {

          await Future.delayed(Duration(milliseconds: 100));
          String quantity = quantityController.text;
          if (quantity.isEmpty) {
            String message = '${Messages.ERROR_QUANTITY} ${Messages.EMPTY}';
            if(context.mounted) showErrorMessage(context, ref, message);
            return;
          }

          double? aux = double.tryParse(quantity);
          if (aux != null && aux >= 0) {
            widget.movementLine.movementQty = aux;
            ref.read(movementLineForEditQuantityToMoveProvider(lineId).notifier).state = widget.movementLine;

          } else {
            String message = '${Messages.ERROR_QUANTITY} ${aux == null
                ? Messages.EMPTY
                : quantity}';
            if(context.mounted) showErrorMessage(context, ref, message);
            return;
          }


          ref.read(isDialogShowedProvider.notifier).state = false;
          setState(() {

          });
        },
        btnOkColor: Colors.green,
        buttonsTextStyle: const TextStyle(color: Colors.white),
        btnCancelText: Messages.CANCEL,
        btnCancelOnPress: () {
          ref.read(isDialogShowedProvider.notifier).state = false;
          setState(() {

          });
        },
        btnCancelColor: Colors.red,
        btnOkText: Messages.OK,
      ).show();
    }
  }
  Widget _numberButtons(BuildContext context, WidgetRef ref,TextEditingController quantityController){
    double widthButton = 40 ;
    return Center(

      //margin: EdgeInsets.only(left: 10, right: 10,),
      child: Column(
        children: [
          Row(
            spacing: 4,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,0),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '0',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,1),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '1',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,2),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),

                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '2',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,3),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '3',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,4),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '4',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),

            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 4,
            children: [


              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,5),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '5',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,6),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '6',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,7),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '7',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,8),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '8',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),

              TextButton(
                onPressed: () => _addQuantityText(context,ref,quantityController,9),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(widthButton, 37),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),
                child: Text(
                  '9',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),

            ],
          ),
          SizedBox(height: 20,),
          SizedBox(
            width: widthButton*5 + 4*4,
            height: 37,
            child: TextButton(
              onPressed: () => _addQuantityText(context,ref,quantityController,-1),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton*5 + 4*4, 37), // width of 5 buttons + 4 spacing
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),

              child: Text(
                Messages.CLEAR,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
          ),

        ],
      ),
    );


  }
  void _addQuantityText(BuildContext context, WidgetRef ref,
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



}