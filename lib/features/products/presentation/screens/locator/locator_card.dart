import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/persitent_provider.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../providers/locator_provider_for_Line.dart';
import '../../providers/product_provider_common.dart';
import '../movement/provider/products_home_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../providers/locator_provider.dart';
import '../store_on_hand/memory_products.dart';
class LocatorCard extends ConsumerStatefulWidget {


  bool? selected = false;
  final IdempiereLocator data;

  final int index;

  String? title;
  double? width;
  final bool searchLocatorFrom;
  final bool forCreateLine;

  LocatorCard({required this.searchLocatorFrom,
    required this.forCreateLine,
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

    Color backGroundColor = Colors.white;

    return GestureDetector(
      onTap: () {
          if(widget.data.id==null || widget.data.id!<=0){
            showErrorMessage(context, ref, Messages.NO_DATA_AVAILABLE);
            return;
          }

          if(widget.searchLocatorFrom){
            if(widget.forCreateLine){
              ref.read(scannedLocatorFromForLineProvider.notifier).update((state) => widget.data.value ?? '');
            } else {
              ref.read(scannedLocatorFromProvider.notifier).update((state) => widget.data.value ?? '');
            }
          } else {
            if(widget.forCreateLine){
              ref.read(selectedLocatorToProvider.notifier).state = widget.data;
              //ref.read(scannedLocatorToForLineProvider.notifier).update((state) => widget.data.value ?? '');
            } else {
              ref.read(selectedLocatorToProvider.notifier).state = widget.data;
              //ref.read(scannedLocatorToProvider.notifier).update((state) => widget.data.value ?? '');
            }

          }


          ref.read(usePhoneCameraToScanForLineProvider.notifier).state = MemoryProducts.lastUsePhoneCameraState ;
          ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.pageFromIndex;
          ref.read(isDialogShowedProvider.notifier).state = false ;
          Future.delayed(const Duration(microseconds: 100));

          Navigator.pop(context);



      },
      child: SingleChildScrollView(
        child: Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: backGroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: themeColorPrimary,
              width: 1,
            ),
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