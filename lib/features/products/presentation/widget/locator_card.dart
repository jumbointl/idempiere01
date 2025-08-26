import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../screens/movement/products_home_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_locator.dart';
import '../providers/locator_provider.dart';
import '../providers/movement_provider.dart';
class LocatorCard extends ConsumerStatefulWidget {


  bool? selected = false;
  final IdempiereLocator data;

  final int index;

  String? title;
  double? width;
  final bool searchLocatorFrom;

  LocatorCard({required this.searchLocatorFrom,
    required this.data,this.selected, this.title, super.key,
    required this.index, this.width});


  @override
  ConsumerState<LocatorCard> createState() => LocatorCardState();
}

class LocatorCardState extends ConsumerState<LocatorCard> {
   late var saveDataToState;

  @override
  Widget build(BuildContext context) {

    if(widget.data.mWarehouseID?.name!=null){
      widget.data.mWarehouseID?.identifier = widget.data.mWarehouseID?.name;
    }
    if(widget.data.value ==null){
      widget.data.value = widget.data.identifier;
    }

    String warehouseName = widget.data.mWarehouseID?.identifier  ?? '';
    String locatorName = widget.data.value ?? '';

    Color backGroundColor = themeColorPrimaryLight2;

    return GestureDetector(
      onTap: () {
          if(widget.data.id==null || widget.data.id!<=0){
            showErrorMessage(context, ref, Messages.NO_DATA_AVAILABLE);
            return;
          }

          if(widget.searchLocatorFrom){
            //ref.read(selectedLocatorFromProvider.notifier).update((state) => widget.data);
            ref.read(scannedLocatorFromProvider.notifier).update((state) => widget.data.value ?? '');

          } else {
            ref.read(selectedLocatorToProvider.notifier).update((state) => widget.data);
          }

          int id1 = ref.read(selectedLocatorToProvider.notifier).state.id ?? 0;
          int id2 = ref.read(selectedLocatorFromProvider.notifier).state.id ?? 0;
          if(id1>0 && id2>0 && id1!=id2){
            ref.read(canCreateMovementProvider.notifier).state = true;
          } else {
            ref.read(canCreateMovementProvider.notifier).state = false;
          }
          ref.read(isLocatorScreenShowedProvider.notifier).state = false;
          ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.pageFromIndex;
          print('------------------ memory pagefrom ${Memory.pageFromIndex}');
          print('------------------ memory pagefrom ${ref.read(productsHomeCurrentIndexProvider.notifier).state}');

          Navigator.pop(context);



      },
      child: SingleChildScrollView(
        child: Container(
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
              Text(locatorName, style: TextStyle(color: Colors.purple),),
              Text(warehouseName),

            ],
          ),
        ),
      ),
    );
  }
   void showErrorMessage(BuildContext context, WidgetRef ref, String message) {
     if (!context.mounted) {
       Future.delayed(const Duration(seconds: 1));
       if(!context.mounted) return;
     }
     AwesomeDialog(
       context: context,
       animType: AnimType.scale,
       dialogType: DialogType.error,
       body: Center(child: Column(
         children: [
           Text(message,
             style: TextStyle(fontStyle: FontStyle.italic),
           ),
         ],
       ),),
       title:  message,
       desc:   '',
       autoHide: const Duration(seconds: 3),
       btnOkOnPress: () {},
       btnOkColor: Colors.amber,
       btnCancelText: Messages.CANCEL,
       btnOkText: Messages.OK,
     ).show();
     return;
   }

}