import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../providers/product_provider_common.dart';
import '../providers/store_on_hand_provider.dart';
class NoDataCard extends ConsumerStatefulWidget {
  Color? backgroundColor;

  NoDataCard({super.key,this.backgroundColor});


  @override
  ConsumerState<NoDataCard> createState() => NoDataCardState();
}

class NoDataCardState extends ConsumerState<NoDataCard> {

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
        searchText = 'SKU: $scannedCode';
      }
    }




    bool hideText = false;
    if(scannedCode == Messages.EMPTY || scannedCode == ''){
      hideText = true;
    }
    Color color = themeColorGrayLight;
    Color textColor = Colors.white;
    count.isEven ? color = Colors.orangeAccent : color = Colors.redAccent;
    String image ='assets/images/not-found.png';
    (count.isEven) ? image ='assets/images/no_data1.png' : image ='assets/images/no_data2.png';
    if(count == 0) image ='assets/images/barcode_scan.png';
    IconData icon = Icons.warning;
    return Container(
      width: MediaQuery.of(context).size.width-30,
      height: 130,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
      child:  hideText ?  IconButton(onPressed: ()=>{}, icon: Image.asset(image, width: 60, height: 60,))
            : SizedBox(
              width: MediaQuery.of(context).size.width-30,
              height: 120,
              child: Column(
                      spacing: 5,
                      children: [
                        Text(searchText, style: TextStyle(fontSize: themeFontSizeLarge,
                            fontWeight: FontWeight.bold,color: textColor),),
                        IconButton(onPressed: ()=>{},
                            icon: Icon(icon, size: 60, color: textColor,))

                      ],
                    ),
            ),
    );
  }
}