import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../providers/product_provider_common.dart';
import '../providers/store_on_hand_provider.dart';
class NoRecordsCard extends ConsumerStatefulWidget {
  final double width ;
  const NoRecordsCard({required this.width,super.key});


  @override
  ConsumerState<NoRecordsCard> createState() => ProductDetailCardState();
}

class ProductDetailCardState extends ConsumerState<NoRecordsCard> {

  @override
  Widget build(BuildContext context) {
    int count = ref.watch(scannedCodeTimesProvider.notifier).state;

    String scannedCode = ref.watch(scannedCodeForStoredOnHandProvider) ?? Messages.EMPTY;
    bool searchFiledByMOLIConfigurableSKU = ref.watch(searchByMOLIConfigurableSKUProvider.notifier).state;
    String searchText = '${Messages.NO_RECORDS_FOUND}: UPC: $scannedCode';
    if(searchFiledByMOLIConfigurableSKU){
      searchText = '${Messages.NO_RECORDS_FOUND}: M_SKU: $scannedCode';
    } else {
      int? aux = int.tryParse(scannedCode);
      if(aux==null){
        searchText = '${Messages.NO_RECORDS_FOUND}: SKU: scannedCode';
      }
    }




    bool hideText = false;
    if(scannedCode == Messages.EMPTY || scannedCode == ''){
      hideText = true;
    }
    Color color = themeColorGrayLight;
    String image ='assets/images/not-found.png';
    (count.isEven) ? image ='assets/images/no_records_found1.png' : image ='assets/images/no_records_found2.png';
    if(count == 0) image ='assets/images/no-image.jpg';
    return Container(
      width: widget.width,
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