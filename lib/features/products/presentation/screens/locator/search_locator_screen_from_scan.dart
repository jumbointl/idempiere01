// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';


import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/locator_provider.dart';
import '../../providers/movement_provider.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/products_scan_notifier.dart';

class SearchLocatorScreenFromScan extends ConsumerStatefulWidget {

  late IdempiereLocator? locatorTo;
  double height = 300.0;
  double width = double.infinity;
  Color bgColor = themeColorPrimary;
  String stringToFind;
  TextStyle movementStyle = const TextStyle(fontWeight: FontWeight.bold,color: Colors.white,
        fontSize: themeFontSizeLarge);
  SearchLocatorScreenFromScan({
    super.key,
    required this.stringToFind,
  });

  @override
  ConsumerState<SearchLocatorScreenFromScan> createState() => SearchLocatorScreenFromScanState();
}


class SearchLocatorScreenFromScanState extends ConsumerState<SearchLocatorScreenFromScan> {
  late ProductsScanNotifier productsNotifier ;
  late AsyncValue getDataAsync;
  bool started = false;

  @override
  Widget build(BuildContext context) {
    productsNotifier = ref.watch(scanHandleNotifierProvider.notifier);
    getDataAsync = ref.watch(confirmMovementProvider);
    widget.locatorTo = IdempiereLocator();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if(widget.locatorTo==null){

      } else {
        if(widget.stringToFind.isNotEmpty){
          if(!started){
            started = true;
            Future.delayed(const Duration(seconds: 1), () {

            });
            productsNotifier.findLocatorToByValue(ref,widget.stringToFind);
            //productsNotifier.confirmMovement(widget.movement!.id);
          }

        }
      }

    });

    return Scaffold(
      appBar: AppBar(
        title: ListTile(title: Text(Messages.FIND_LOCATOR_TO,style: TextStyle(fontSize: themeFontSizeNormal),),
            subtitle: Text('MV : ${widget.locatorTo?.id ?? ''}',style: TextStyle(fontSize: themeFontSizeNormal),),
        ),
      ),
      body: SingleChildScrollView(
      child: Container(
        height: widget.height,
        width: widget.width,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: themeColorPrimary),
          borderRadius: BorderRadius.circular(10),
        ),
        child:  getDataAsync.when(data: (data){
          if(data==null){
            return Column(
              children: [
                Icon(Icons.search,size: 100,color: themeColorPrimary,),
                Text(widget.stringToFind,style: TextStyle(
                    fontSize: themeFontSizeNormal),
                ),
              ],
            );
          } else {
            if(data.id ==Memory.INITIAL_STATE_ID){
              return Column(
                children: [
                  Icon(Icons.search,size: 100,color: themeColorPrimary,),
                  Text(widget.stringToFind,style: TextStyle(
                      fontSize: themeFontSizeNormal),
                  ),
                ],
              );
            }
            widget.locatorTo = data;
            return Column(
              children: [
                getDataCard(context, ref),
                getConfirmBar(context, ref),
              ],
            );
          }
        },
            error:(error, stackTrace) => Text('Error: $error'),
            loading: ()=>LinearProgressIndicator(minHeight: 36,)),
      ),
    ));
  }
  Widget getDataCard(BuildContext context,WidgetRef ref){

    String value='';
    int id= -1;
    IdempiereLocator data = widget.locatorTo ?? IdempiereLocator();

    id = data.id ?? -1;
    id = data.id ?? -1;
    value = data.value ?? '';
    bool success = false;
    if(data.id != null && data.id!>0){
      success = true;
    }
    return Container(
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        spacing: 10,
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(success ? Icons.check_circle : Icons.error_outline,color:
            success ? Colors.green : Colors.red,size: 50,),
          Text(
            id.toString(),
            style: widget.movementStyle,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: widget.movementStyle,
            overflow: TextOverflow.ellipsis,
          ),

        ],
      ),
    );
  }

  Widget getConfirmBar(BuildContext context, WidgetRef ref) {
    bool canConfirm = (widget.locatorTo!=null && widget.locatorTo!.id != null && widget.locatorTo!.id! > 0);
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 10,
        children: [
          Expanded(
            child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                onPressed: (){ Navigator.pop(context);},
                child: Text(
                  Messages.CANCEL,
                )
            ),
          ),
          Expanded(
            child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
                onPressed: (){
                  if(!canConfirm){
                    AwesomeDialog(
                      context: context,
                      animType: AnimType.scale,
                      dialogType: DialogType.error,
                      body: Center(child: Text(
                        Messages.ERROR_LOCATOR_EMPTY,
                        //style: TextStyle(fontStyle: FontStyle.italic),
                      ),), // correct here
                      title: Messages.ERROR_LOCATOR_EMPTY,
                      desc:   '',
                      autoHide: const Duration(seconds: 3),
                      btnOkOnPress: () {},
                      btnOkColor: themeColorSuccessful,
                      btnCancelColor: themeColorError,
                      btnCancelText: Messages.CANCEL,
                      btnOkText: Messages.OK,
                    ).show();
                    return;
                  }
                  ref.read(selectedLocatorToProvider.notifier).state = widget.locatorTo!;
                  //Navigator.pop(context);
                },
                child: Text(Messages.CONFIRM)
            ),
          ),
        ]
    );

  }

}
