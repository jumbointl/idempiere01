
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../../../../config/router/app_router.dart';
import '../../../../../../config/theme/app_theme.dart';
import '../../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../../domain/idempiere/idempiere_warehouse.dart';
import '../../../providers/common_provider.dart';
import '../../../providers/product_provider_common.dart';
import '../../../providers/products_scan_notifier_for_line.dart';
class StorageOnHandCardForLine extends ConsumerStatefulWidget {
  final ProductsScanNotifierForLine notifier;
  final IdempiereStorageOnHande storage;
  final int index;
  final int listLength;
  final Color colorSameWarehouse = themeColorSuccessfulLight;
  final Color colorDifferentWarehouse = themeColorGrayLight;
  final double width;
  final double height = 120;
  IdempiereLocator? allowedLocatorFrom;
  final MovementAndLines movementAndLines;
  String? argument;

  StorageOnHandCardForLine(

      this.notifier,
      this.storage,
      this.index,
      this.listLength, {
      required this.movementAndLines,
      required this.width,this.allowedLocatorFrom,
        super.key, required this.argument,});


  @override
  ConsumerState<StorageOnHandCardForLine> createState() =>StorageOnHandCardForLineState();
}

class StorageOnHandCardForLineState extends ConsumerState<StorageOnHandCardForLine> {
  late var usePhoneCamera ;
  late var allowedLocatorId;
  MovementAndLines get movementAndLines {
    if(widget.argument!=null && widget.argument!.isNotEmpty && widget.argument!='-1') {
      return MovementAndLines.fromJson(jsonDecode(widget.argument!));
    } else {
      return widget.movementAndLines;
    }
  }
  //late int movementId;

  @override
  Widget build(BuildContext context) {
    // No sé porque, sin hacer preguntas no muestras....widget.movementAndLines
    String lines = '0';
    if(movementAndLines.hasMovement){
      lines = movementAndLines.movementLines?.length.toString() ?? '0';
      if(movementAndLines.hasMovementLines){
        widget.allowedLocatorFrom = movementAndLines.lastLocatorFrom;
      } else {
        widget.allowedLocatorFrom = widget.storage.mLocatorID;
      }
    }


    usePhoneCamera = ref.watch(usePhoneCameraToScanForLineProvider.notifier);
    allowedLocatorId = widget.allowedLocatorFrom?.id ?? -1;
    final warehouse = ref.read(authProvider).selectedWarehouse;
    int warehouseID = warehouse?.id ?? 0;
    IdempiereWarehouse? warehouseStorage = widget.storage.mLocatorID?.mWarehouseID;
    bool canMove = false ;
    Color background = widget.colorDifferentWarehouse;
    if(allowedLocatorId > 0){
      if(widget.storage.mLocatorID?.id != allowedLocatorId){
        background = widget.colorDifferentWarehouse;
      } else {
        background = widget.colorSameWarehouse;
        canMove = true;
      }

    } else {
      if(warehouseStorage?.id == warehouseID){
        background = widget.colorSameWarehouse;
        canMove = true;
      }
    }

    double widthLarge = (widget.width-15)/3*2;
    double widthSmall = (widget.width-15)/3;
    String warehouseName = warehouseStorage?.identifier ?? '';
    double qtyOnHand = widget.storage.qtyOnHand ?? 0;
    String quantity = Memory.numberFormatter0Digit.format(qtyOnHand) ;
    return  GestureDetector(
      onTap: () async {
        if(!canMove){
          showErrorMessage(context, ref, Messages.ERROR_CANNOT_MOVE_STORAGE);
          return;
        }

        IdempiereProduct product = widget.storage.mProductID ?? IdempiereProduct();
        List<IdempiereMovementLine>? movementLines = MemoryProducts.movementAndLines.movementLines;
        bool isProductMoved = false;
        if(MemoryProducts.movementAndLines.hasMovementLines){
          List<IdempiereProduct> products = [];
          for(int i=0;i<movementLines!.length;i++){
            if(movementLines[i].mProductID != null){
              products.add(movementLines[i].mProductID!);
            }
          }
          for(int i=0;i<products.length;i++){
            if(products[i].id == product.id){
              isProductMoved = true;
              break;
            }
          }

        }
        if(isProductMoved){
          AwesomeDialog(
            context: context,
            animType: AnimType.scale,
            dialogType: DialogType.error,
            body: Center(child: Text(
              Messages.ERROR_PRODUCT_REAPEATED,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),), // correct here
            title: Messages.ERROR_UPC_EMPTY,
            desc:   '',
            autoHide: const Duration(seconds: 3),
            btnOkOnPress: () {},
            btnOkColor: Colors.amber,
            btnCancelText: Messages.CANCEL,
            btnOkText: Messages.OK,
          ).show();
          return;

        }

        ref.read(isDialogShowedProvider.notifier).update((state)=>true);
        ref.read(isScanningFromDialogProvider.notifier).update((state)=>false);
        _selectLocatorDialog(ref,movementAndLines);

      },
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: widthSmall,
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Messages.WAREHOUSE_SHORT),
                    Text(Messages.LOCATOR_SHORT),
                    Text(Messages.QUANTITY_SHORT),
                    Text(Messages.ATTRIBUET_INSTANCE),

                  ],
                ),
              ),
              SizedBox(
                width: widthLarge,
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(warehouseName),
                    Text(widget.storage.mLocatorID?.value ?? '', overflow: TextOverflow.ellipsis),
                    Text(
                      quantity,
                      style: TextStyle(
                        color: qtyOnHand < 0 ? Colors.redAccent : Colors.black,
                      ),
                    ),
                    Text(widget.storage.mAttributeSetInstanceID?.identifier ?? '', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
  Future<void> _selectLocatorDialog(WidgetRef ref, MovementAndLines movementAndLines) async {


    MemoryProducts.index = widget.index;
    MemoryProducts.listLength = widget.listLength;
    MemoryProducts.storage = widget.storage;
    MemoryProducts.width = widget.width;
    movementAndLines.nextProductIdUPC = widget.storage.mProductID?.id?.toString() ?? '-1';
    ref.read(actionScanProvider.notifier).update((state) => Memory.ACTION_GET_LOCATOR_TO_VALUE);
    ref.read(productsHomeCurrentIndexProvider.notifier).state = Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND;
    String argument = movementAndLines.nextProductIdUPC ??'-1';
    if(ref.context.mounted) {
      ref.context.go(
          '${AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND_FOR_LINE}/$argument',
          extra: movementAndLines);
    }

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


