

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_search_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_update_upc_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_product.dart';

class ProductsUpdateNotifier  extends StateNotifier<List<IdempiereProduct>>{
  ProductsUpdateNotifier(this.ref) : super([]);
  final Ref ref;

  void addNewUPCCode(String scannedData){
    ref.watch(newUPCToUpdateProvider.notifier).update((state) => scannedData);
    Future.delayed(const Duration(milliseconds: 500), () {
    });

    ref.watch(scannedCodeTimesProvider.notifier).update((state) => state+1);
    ref.watch(isScanningProvider.notifier).update((state) => false);
  }

  void updateProductUPC(BuildContext context) async {
    String id = ref.read(productForUpcUpdateProvider.notifier).state.id!.toString();
    String newUPC = ref.read(newUPCToUpdateProvider.notifier).state;

    if(id == '' || int.tryParse(id)==null || int.tryParse(id) == 0 || newUPC=='' ||
        int.tryParse(newUPC)==null || int.tryParse(newUPC) == 0)
    {
      await AwesomeDialog(
        context: context,
        animType: AnimType.scale,
        dialogType: DialogType.error,
        body: Center(child: Text(
          Messages.DATA_NOT_VALID,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),), // correct here
        title: 'ID: $id ,UPC: $newUPC' ,
        desc:   'ID: $id ,UPC: $newUPC' ,
        autoHide: const Duration(seconds: 5),
        btnOkOnPress: () {},
        btnOkColor: Colors.amber,
        btnCancelText: Messages.CANCEL,
        btnOkText: Messages.OK,
      ).show();
      return;
    }
    List<String> updateData =[id,newUPC];
      //ref.watch(isScanningProvider.notifier).update((state) => true);
      ref.read(dataToUpdateUPCProvider.notifier).update((state) => updateData);

  }

  void addBarcodeByUPCOrSKUForSearch(String data) {
    ref.watch(isScanningProvider.notifier).update((state) => true);
    ref.watch(dataToUpdateUPCProvider.notifier).state = [];
    ref.watch(newUPCToUpdateProvider.notifier).update((state) => '');
    Memory.lastSearch = data;
    ref.watch(scannedCodeForSearchByUPCOrSKUProvider.notifier).update((state) => data);
    ref.watch(scannedCodeTimesProvider.notifier).update((state) => state+1);

  }


}

