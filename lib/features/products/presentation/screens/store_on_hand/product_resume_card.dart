import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../auth/domain/entities/warehouse.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/data/memory.dart';
import '../../providers/store_on_hand_provider.dart';
import '../../widget/no_data_card.dart';

class ProductResumeCard extends ConsumerStatefulWidget {
  final double width;
  final List<IdempiereStorageOnHande> storages;

  const ProductResumeCard(this.storages,this.width, {super.key});

  @override
  ConsumerState<ProductResumeCard> createState() => ProductResumeCardState();
}

class ProductResumeCardState extends ConsumerState<ProductResumeCard> {
  @override
  Widget build(BuildContext context) {
    final results = calculateResult(widget.storages);
      bool hideResult = false;
    if(results.isNotEmpty && results[0]=='0'){
      hideResult = true;
    }

    bool searchFiledByMOLIConfigurableSKU = ref.watch(searchByMOLIConfigurableSKUProvider);
    String scannedCode = ref.watch(scannedCodeForStoredOnHandProvider) ?? '';
    String searchText = '(UPC)';
    if(searchFiledByMOLIConfigurableSKU){
      searchText = '(M_SKU)';
    } else {
      int? aux = int.tryParse(scannedCode);
      if(aux==null){
        searchText = '(SKU)';
      }
    }
    double widthLarge = widget.width/3*2;
    double widthSmall = widget.width/3;
    return Container(
      decoration: BoxDecoration(
        color: hideResult ? themeColorGrayLight : themeColorSuccessful,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            results.isNotEmpty ? Expanded(
                    flex: widthSmall.toInt(), // Use widthLarge for this column's width
                  child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     Text(results[0], style: const TextStyle(fontSize: themeFontSizeLarge,fontWeight: FontWeight.bold)),
                ],
            ),) : NoDataCard(),
          if(results.length>1) Expanded(
            flex: widthLarge.toInt(), // Use widthLarge for this column's width
            child: Column(
              spacing: 5,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                   Text('${results[1]} $searchText', style: const TextStyle(fontSize: themeFontSizeLarge,fontWeight: FontWeight.bold)),
              ],
            ),),
        ],
      ),
    );
  }
  List<String> calculateResult(List<IdempiereStorageOnHande> storages) {


    Warehouse? w = ref.read(authProvider).selectedWarehouse;
    int warehouseUser = w?.id ?? 0;
    String warehouseName = w?.name ?? '';
    double quantity = 0;
    for (var data in storages) {
      int warehouseID = data.mLocatorID?.mWarehouseID?.id ?? 0;

      if (warehouseID == warehouseUser) {
        quantity += data.qtyOnHand ?? 0;
      }
    }

    String aux = Memory.numberFormatter0Digit.format(quantity);
    return [aux,warehouseName];
  }
}