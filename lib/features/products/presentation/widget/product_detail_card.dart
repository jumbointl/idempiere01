import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../providers/products_scan_notifier.dart';
import '../providers/store_on_hand_provider.dart';
class ProductDetailCard extends ConsumerStatefulWidget {
  final IdempiereProduct product;
  final ProductsScanNotifier productsNotifier ;
  const ProductDetailCard({required this.productsNotifier, required this.product, super.key});


  @override
  ConsumerState<ProductDetailCard> createState() => ProductDetailCardState();
}

class ProductDetailCardState extends ConsumerState<ProductDetailCard> {


  @override
  Widget build(BuildContext context) {
    String att = widget.product.mAttributeSetInstanceID?.identifier  ?? '';
    if(att==''){
      att = '${Messages.ATTRIBUET_INSTANCE}: ${widget.product.mAttributeSetInstanceID?.identifier  ?? '--'}';
    }
    Color backGroundColor = themeColorPrimaryLight2;
    bool canSearch = true ;
    if(widget.product.mOLIConfigurableSKU == null || widget.product.mOLIConfigurableSKU == '') {
      canSearch = false;
      backGroundColor = Colors.amber[200]!;

    }
    if(ref.watch(searchByMOLIConfigurableSKUProvider.notifier).state){
      backGroundColor = Colors.amber[200]!;
    } else {
      backGroundColor = themeColorPrimaryLight2;
    }
    return GestureDetector(
      onTap: () {
        if(!ref.watch(searchByMOLIConfigurableSKUProvider.notifier).state){

          if(!canSearch){
            AwesomeDialog(
              context: context,
              animType: AnimType.scale,
              body: Center(child: Text(
                Messages.SKU_NULL,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),),
              dialogType: DialogType.info, // correct here
              title: Messages.SKU_EQUAL_MOLI_SKU,
              desc:   '',
              btnOkOnPress: () {},
              btnOkColor: Colors.amber,
            ).show();
            return;
          }
          widget.productsNotifier.addBarcodeByMOLISKU(widget.product.mOLIConfigurableSKU ?? '');
        } else {
          String upc = widget.product.uPC ?? '';
          if(upc == ''){
            AwesomeDialog(
              context: context,
              animType: AnimType.scale,
              dialogType: DialogType.error,
              body: Center(child: Text(
                Messages.ERROR_UPC_EMPTY,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),), // correct here
              title: Messages.ERROR_UPC_EMPTY,
              desc:   '',
              btnOkOnPress: () {},
              btnOkColor: Colors.amber,
            ).show();
            return;
          }

          widget.productsNotifier.addBarcodeByUPCOrSKUForStoreOnHande(upc);
        }


      },
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: backGroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              Text(widget.product.name ?? '${Messages.NAME}--'),
              Text('UPC: ${widget.product.uPC ?? 'UPC--'}'),
              Text('SKU: ${widget.product.sKU ?? 'SKU--'}'),
              Text('M_SKU: ${widget.product.mOLIConfigurableSKU ?? 'M_SKU--'}'),
              Text(att),
        
            ],
          ),
        ),
      ),
    );
  }
}