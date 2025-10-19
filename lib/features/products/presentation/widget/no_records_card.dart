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
  ConsumerState<NoRecordsCard> createState() => NoRecordlCardState();
}

class NoRecordlCardState extends ConsumerState<NoRecordsCard> {

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
        searchText = '${Messages.NO_RECORDS_FOUND}: SKU: $scannedCode';
      }
    }




    bool hideText = false;
    if(scannedCode == Messages.EMPTY || scannedCode == ''){
      hideText = true;
    }
    Color color = themeColorGrayLight;
    IconData icon1 = Icons.warning;
    IconData icon2 = Icons.crisis_alert;
    IconData icon = Icons.warning;
    String image ='assets/images/not-found.png';
    (count.isEven) ? icon = icon1 : icon = icon2;
    (count.isEven) ? image ='assets/images/no_records_found1.png' : image ='assets/images/no_records_found2.png';
    if(count == 0) image ='assets/images/no-image.jpg';
    return Container(
      width: widget.width,
      height: 180,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
      child:  hideText ?  IconButton(onPressed: ()=>{}, icon: Icon(icon,color: Colors.white, size: 80,)) : Column(
        // spacing: 5, // gap between adjacent chips
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          (count.isEven) ? Text(searchText, style: const TextStyle(fontSize: themeFontSizeTitle),)
              : IconButton(onPressed: ()=>{}, icon: Icon(icon,color: Colors.amberAccent, size: 80,)) ,
          (count.isEven) ? IconButton(onPressed: ()=>{}, icon: Icon(icon,color: Colors.redAccent, size: 80,))
              : Text(searchText, style: const TextStyle(fontSize: themeFontSizeTitle),),
        ],
      ),
    );
  }
}