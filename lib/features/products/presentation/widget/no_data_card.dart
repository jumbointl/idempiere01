import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../providers/product_screen_provider.dart';
class NoDataCard extends ConsumerStatefulWidget {

  const NoDataCard({super.key});


  @override
  ConsumerState<NoDataCard> createState() => ProductDetailCardState();
}

class ProductDetailCardState extends ConsumerState<NoDataCard> {

  @override
  Widget build(BuildContext context) {
    int count = ref.watch(scannedCodeTimesProvider.notifier).state;
    String scannedCode = ref.watch(scannedCodeProvider) ?? Messages.EMPTY;
    bool hideText = false;
    if(scannedCode == Messages.EMPTY || scannedCode == ''){
      hideText = true;
    }
    Color color = themeColorGrayLight;
    String image ='assets/images/not-found.png';
    (count.isEven) ? image ='assets/images/no_data1.png' : image ='assets/images/no_data2.png';
    if(count == 0) image ='assets/images/barcode_scan.png';
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
      child:  hideText ?  IconButton(onPressed: ()=>{}, icon: Image.asset(image)) : Row(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          (count.isEven) ? Expanded(child: Text(scannedCode, style: const TextStyle(fontSize: themeFontSizeTitle),))
              : IconButton(onPressed: ()=>{}, icon: Image.asset(image)) ,
          (count.isEven) ? IconButton(onPressed: ()=>{}, icon: Image.asset(image))
              : Expanded(child: Text(scannedCode, style: const TextStyle(fontSize: themeFontSizeTitle),)),
        ],
      ),
    );
  }
}