import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../providers/product_provider_common.dart';
import '../providers/store_on_hand_provider.dart';
import '../screens/store_on_hand/memory_products.dart';
class NoStorageOnHandRecordsCard extends ConsumerStatefulWidget {
  final double width ;
  final double imageWidth = 100;
  const NoStorageOnHandRecordsCard({required this.width,super.key});


  @override
  ConsumerState<NoStorageOnHandRecordsCard> createState() => NoStorageOnHandRecordsCardState();
}

class NoStorageOnHandRecordsCardState extends ConsumerState<NoStorageOnHandRecordsCard> {

  @override
  Widget build(BuildContext context) {
    int count = ref.watch(scannedCodeTimesProvider.notifier).state;
    String locatorName = MemoryProducts.movementAndLines.lastLocatorFrom?.value ?? '';
    String scannedCode = ref.watch(scannedCodeForStoredOnHandProvider) ?? Messages.EMPTY;
    bool searchFiledByMOLIConfigurableSKU = ref.watch(searchByMOLIConfigurableSKUProvider.notifier).state;
    String searchText = '${Messages.NOT_DATA_OF_SAME_LOCATOR_AVAILABLE}: UPC:';
    if(searchFiledByMOLIConfigurableSKU){
      searchText = Messages.NOT_DATA_OF_SAME_LOCATOR_AVAILABLE;
    } else {
      int? aux = int.tryParse(scannedCode);
      if(aux==null){
        searchText = '${Messages.NOT_DATA_OF_SAME_LOCATOR_AVAILABLE}: SKU:';
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
      child:  hideText ?  IconButton(onPressed: ()=>{},
          icon: Image.asset(image, width: widget.imageWidth, height: widget.imageWidth,))
          : SizedBox(
            height: 250,
            child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    children: [
            Text(locatorName,style: TextStyle(fontSize: themeFontSizeTitle),),
            Text(scannedCode,style: TextStyle(fontSize: themeFontSizeTitle)),
            if (count.isEven) ...[
              Text(searchText, style: const TextStyle(fontSize: themeFontSizeTitle)),
              IconButton(
                icon: Image.asset(image, width: 150, height: 150),
                onPressed: () {},
              ),
            ] else ...[
              IconButton(
                icon: Image.asset(image, width: 150, height: 150),
                onPressed: () {},
              ),
              Text(searchText, style: const TextStyle(fontSize: themeFontSizeTitle)),
            ],



                    ],
                  ),
          ),
    );
  }
}