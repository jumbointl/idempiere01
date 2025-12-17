import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/response_async_value.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/messages.dart';
import '../../providers/product_provider_common.dart';
import '../../providers/store_on_hand_provider.dart';
class MovementNoDataCard extends ConsumerStatefulWidget {
  Color? backgroundColor;
  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();

  MovementNoDataCard({super.key,this.backgroundColor,required ResponseAsyncValue response});


  @override
  ConsumerState<MovementNoDataCard> createState() => MovementNoDataCardState();
}

class MovementNoDataCardState extends ConsumerState<MovementNoDataCard> {
  late final ResponseAsyncValue responseAsyncValue ;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    responseAsyncValue = widget.responseAsyncValue;
  }
  @override
  Widget build(BuildContext context) {

    widget.backgroundColor ??= Colors.cyan[200];
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
    if(widget.backgroundColor!=null) color = widget.backgroundColor!;
    IconData icon = !responseAsyncValue.isInitiated ? Icons.scanner :
       responseAsyncValue.success ? Icons.check_circle : Icons.error;
    String title = !responseAsyncValue.isInitiated ? Messages.WAIT_FOR_SEARCH
        : responseAsyncValue.success ? Messages.SEARCH_WITH_SUCCESS_BUT_NO_DATA_FOUND
     : Messages.ERROR_SEARCH;
    Color iconColor = responseAsyncValue.isInitiated ? Colors.cyan.shade700 :
        responseAsyncValue.success ? Colors.green : Colors.red;
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
                        Text(title, style: TextStyle(fontSize: themeFontSizeLarge,
                            fontWeight: FontWeight.bold,color: textColor),),
                        Text(searchText, style: TextStyle(fontSize: themeFontSizeLarge,
                            fontWeight: FontWeight.bold,color: textColor),),
                        IconButton(onPressed: ()=>{},
                            icon: Icon(icon, size: 60, color: iconColor,))

                      ],
                    ),
            ),
    );
  }
}