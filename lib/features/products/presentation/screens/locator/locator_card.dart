import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/locator_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/store_on_hand/action_notifier.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../common/messages_dialog.dart';
import '../../providers/product_provider_common.dart';
import '../../../../shared/data/messages.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
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

    Color backGroundColor = Colors.white;

    return GestureDetector(
      onTap: () {
          if(widget.data.id==null || widget.data.id!<=0){
            showErrorMessage(context, ref, Messages.NO_DATA_AVAILABLE);
            return;
          }

          if(widget.searchLocatorFrom){
            //To do not implement
          } else {
            ref.invalidate(selectedLocatorToProvider);
            ref.read(findLocatorToActionProvider).handleInputString(
                ref: ref, inputData: widget.data.value ?? '',
                actionScan: Memory.ACTION_GET_LOCATOR_TO_VALUE);

          }


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


}