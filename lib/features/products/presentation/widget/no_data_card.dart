import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../providers/product_provider_common.dart';
import '../providers/store_on_hand_provider.dart';
class NoDataCard extends ConsumerStatefulWidget {

  const NoDataCard({super.key});


  @override
  ConsumerState<NoDataCard> createState() => ProductDetailCardState();
}

class ProductDetailCardState extends ConsumerState<NoDataCard> {

  @override
  Widget build(BuildContext context) {
    int count = ref.watch(scannedCodeTimesProvider.notifier).state;
    String scannedCode = ref.watch(scannedCodeForStoredOnHandProvider) ?? Messages.EMPTY;
    bool searchFiledByMOLIConfigurableSKU = ref.watch(searchByMOLIConfigurableSKUProvider.notifier).state;
    String searchText = 'UPC: $scannedCode';
    if(searchFiledByMOLIConfigurableSKU){
      searchText = 'M_SKU: $scannedCode';
    } else {
      int? aux = int.tryParse(scannedCode);
      if(aux==null){
        searchText = 'SKU: scannedCode';
      }
    }




    bool hideText = false;
    if(scannedCode == Messages.EMPTY || scannedCode == ''){
      hideText = true;
    }
    Color color = themeColorGrayLight;
    String image ='assets/images/not-found.png';
    (count.isEven) ? image ='assets/images/no_data1.png' : image ='assets/images/no_data2.png';
    if(count == 0) image ='assets/images/barcode_scan.png';
    return Container(
      width: MediaQuery.of(context).size.width-30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
      child:  hideText ?  IconButton(onPressed: ()=>{}, icon: Image.asset(image)) : Row(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          (count.isEven) ? Expanded(child: Text(searchText, style: const TextStyle(fontSize: themeFontSizeTitle),))
              : IconButton(onPressed: ()=>{}, icon: Image.asset(image)) ,
          (count.isEven) ? IconButton(onPressed: ()=>{}, icon: Image.asset(image))
              : Expanded(child: Text(searchText, style: const TextStyle(fontSize: themeFontSizeTitle),)),
        ],
      ),
    );
  }
}