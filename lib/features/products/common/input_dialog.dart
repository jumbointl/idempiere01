


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/common/input_data_processor.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../config/theme/app_theme.dart';
import '../../shared/data/memory.dart';
import '../../shared/data/messages.dart';
import '../presentation/providers/common_provider.dart';
import '../presentation/providers/product_provider_common.dart';
import 'messages_dialog.dart';

double get fontSizeMedium => themeFontSizeNormal;
double get fontSizeLarge => themeFontSizeLarge;



Future<String?> openInputDialogWithResult(
    BuildContext context,
    WidgetRef ref,
    bool history,
    {required String text}

    ) async {
  var actionScan = ref.watch(actionScanProvider.notifier);
  print('actionScan.state -- ${actionScan.state}');

  String title = Messages.INPUT_DATA;

  if (actionScan.state == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
    title = Messages.FIND_MOVEMENT_BY_ID;
  } else if (actionScan.state ==
      Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND) {
    title = Messages.FIND_PRODUCT_BY_UPC_SKU;
  } else if (actionScan.state == Memory.ACTION_GET_LOCATOR_TO_VALUE) {
    title = Messages.FIND_LOCATOR;
  }

  TextEditingController controller = TextEditingController();
  controller.text = text ;
  if (history) {
    String lastSearch = Memory.lastSearch;

    if (actionScan.state == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      lastSearch = Memory.lastSearchMovement;
    }

    if (lastSearch == '-1') lastSearch = '';

    controller.text =
    lastSearch.isEmpty ? Messages.NO_RECORDS_FOUND : lastSearch;
  }

  final result = await showModalBottomSheet<String?>(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        fontSize: fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      keyboardType: TextInputType.none,
                    ),
                  ),

                  keyboardButtons(context, ref, controller),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    spacing: 10,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.pop(context, null);
                          },
                          child: Text(Messages.CANCEL),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            final text = controller.text;

                            if (text.isEmpty) {
                              showErrorMessage(
                                  context, ref, Messages.TEXT_FIELD_EMPTY);
                              return;
                            }

                            if (actionScan.state ==
                                Memory.ACTION_FIND_MOVEMENT_BY_ID) {
                              Memory.lastSearchMovement = text;
                            } else {
                              Memory.lastSearch = text;
                            }

                            // 🔥 ahora se usa la función callback
                            //onOk(context, ref, text);

                            Navigator.pop(context, text);
                          },
                          child: Text(Messages.CONFIRM),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  ref.read(isDialogShowedProvider.notifier).state = false;
  return result;
}

Future<void> openInputDialogWithAction({
    required WidgetRef ref,
    required bool history,
    required int actionScan,
    required void Function({required WidgetRef ref,required String inputData,required int actionScan}) onOk,
}) async {
  print('actionScan.state -- $actionScan');

  String title = Messages.INPUT_DATA;

  if (actionScan == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
    title = Messages.FIND_MOVEMENT_BY_ID;
  } else if (actionScan ==
      Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND) {
    title = Messages.FIND_PRODUCT_BY_UPC_SKU;
  } else if (actionScan == Memory.ACTION_GET_LOCATOR_TO_VALUE) {
    title = Messages.FIND_LOCATOR;
  }

  TextEditingController controller = TextEditingController();

  if (history) {
    String lastSearch = Memory.lastSearch;

    if (actionScan == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      lastSearch = Memory.lastSearchMovement;
    }

    if (lastSearch == '-1') lastSearch = '';

    controller.text =
    lastSearch.isEmpty ? Messages.NO_RECORDS_FOUND : lastSearch;
  }

  // ⬇️ Ahora retornamos el Future<String?>
  final result = await showModalBottomSheet<String?>(
    isScrollControlled: true,
    context: ref.context,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        fontSize: fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      keyboardType: TextInputType.none,
                    ),
                  ),

                  keyboardButtons(context, ref, controller),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    spacing: 10,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.pop(context, null); // ❗ devolvemos null
                          },
                          child: Text(Messages.CANCEL),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            final text = controller.text;

                            if (text.isEmpty) {
                              showErrorMessage(
                                  context, ref, Messages.TEXT_FIELD_EMPTY);
                              return;
                            }

                            if (actionScan ==
                                Memory.ACTION_FIND_MOVEMENT_BY_ID) {
                              Memory.lastSearchMovement = text;
                            } else {
                              Memory.lastSearch = text;
                            }

                            onOk(ref: ref, inputData: text,
                                actionScan: actionScan); // ❗ llamamos a onOk

                            Navigator.pop(context, text); // <-- 🔥 devolvemos text
                          },
                          child: Text(Messages.CONFIRM),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  ref.read(isDialogShowedProvider.notifier).state = false;

  print('Dialog closed with: $result');

  //return result; // 🔥 devolvemos el valor final al que llama
}

Widget keyboardButtons(BuildContext context, WidgetRef ref,TextEditingController textController){
  double widthButton = (MediaQuery.of(context).size.width) /10;
  return Center(
    child: Column(
      spacing: 1,
      children: [

        LayoutBuilder(
            builder: (context, constraints) {
              return ToggleButtons(
                isSelected: List.generate(10, (_) => false),
                onPressed: (int index) {
                  addText(context, ref, textController, index.toString());
                },
                constraints: BoxConstraints.expand(width: (constraints.maxWidth-10 - (9 * 1)) / 10, height: widthButton), // 1 is for border width
                borderRadius: BorderRadius.circular(5),
                borderColor: Colors.black,
                children: List.generate(10, (index) => Text(
                  index.toString(),
                  style: TextStyle(color: Colors.black, fontSize: fontSizeMedium),
                )),
              );
            }
        ),
        LayoutBuilder(
            builder: (context, constraints) {
              final keyWidth = (constraints.maxWidth -10 - (9 * 1)) / 10;
              return ToggleButtons(
                isSelected: List.generate('QWERTYUIOP'.length, (_) => false),
                onPressed: (int index) {
                  addText(context, ref, textController, 'QWERTYUIOP'[index]);
                },
                constraints: BoxConstraints.expand(width: keyWidth, height: widthButton),
                borderRadius: BorderRadius.circular(5),
                borderColor: Colors.black,
                children: 'QWERTYUIOP'.split('').map((String char) => Text(
                  char,
                  style: TextStyle(color: Colors.black, fontSize: fontSizeMedium),
                )).toList(),
              );
            }
        ),
        LayoutBuilder(
            builder: (context, constraints) {
              final keyWidth = (constraints.maxWidth -10 - (9 * 1)) / 10;
              return ToggleButtons(
                isSelected: List.generate('ASDFGHJKLÑ'.length, (_) => false),
                onPressed: (int index) {
                  addText(context, ref, textController, 'ASDFGHJKLÑ'[index]);
                },
                constraints: BoxConstraints.expand(width: keyWidth, height: widthButton),
                borderRadius: BorderRadius.circular(5),
                borderColor: Colors.black,
                children: 'ASDFGHJKLÑ'.split('').map((String char) => Text(
                  char,
                  style: TextStyle(color: Colors.black, fontSize: fontSizeMedium),
                )).toList(),
              );
            }
        ),
        LayoutBuilder(
            builder: (context, constraints) {
              final keyWidth = (constraints.maxWidth -10 - (9 * 1)) / 10;
              return ToggleButtons(
                isSelected: List.generate('ZXCVBNM_-+'.length, (_) => false),
                onPressed: (int index) {
                  addText(context, ref, textController, 'ZXCVBNM_-+'[index]);
                },
                constraints: BoxConstraints.expand(width: keyWidth, height: widthButton),
                borderRadius: BorderRadius.circular(5),
                borderColor: Colors.black,
                children: 'ZXCVBNM_-+'.split('').map((String char) => Text(
                  char,
                  style: TextStyle(color: Colors.black, fontSize: fontSizeMedium),
                )).toList(),
              );
            }
        ),
        LayoutBuilder(
            builder: (context, constraints) {
              final keyWidth = (constraints.maxWidth -10 - (9 * 1)) / 10;
              return ToggleButtons(
                isSelected: List.generate('/,.;:&%@#"'.length, (_) => false),
                onPressed: (int index) {
                  addText(context, ref, textController, '/,.;:&%@#"'[index]);
                },
                constraints: BoxConstraints.expand(width: keyWidth, height: widthButton),
                borderRadius: BorderRadius.circular(5),
                borderColor: Colors.black,
                children: '/,.;:&%@#"'.split('').map((String char) => Text(
                  char,
                  style: TextStyle(color: Colors.black, fontSize: fontSizeMedium),
                )).toList(),
              );
            }
        ),
        SizedBox(height: 10,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: widthButton*3,
              height: widthButton,
              child: TextButton(
                onPressed: () => removeText(context,ref,textController),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),

                child: Text(
                  '<=',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeLarge,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: widthButton*3,
              height: widthButton,
              child: TextButton(
                onPressed: () => addText(context,ref,textController,' '),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),

                child: Text(
                  ' ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeLarge,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: widthButton*3,
              height: widthButton,
              child: TextButton(
                onPressed: () => textController.text = '',
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),

                child: Text(
                  Messages.CLEAR,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
            ),
          ],
        ),

      ],
    ),
  );


}
Widget numberButtons(BuildContext context, WidgetRef ref,TextEditingController quantityController, InputDataProcessor processor){
  double widthButton = 40 ;
  return Center(

    child: Column(
      children: [
        Row(
          spacing: 4,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,0),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '0',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,1),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '1',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,2),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),

                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '2',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,3),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '3',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,4),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '4',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),

          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 4,
          children: [


            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,5),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '5',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,6),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '6',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,7),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '7',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,8),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '8',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),

            TextButton(
              onPressed: () => processor.addQuantityText(context,ref,quantityController,9),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(widthButton, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '9',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),

          ],
        ),
        SizedBox(height: 20,),
        SizedBox(
          width: widthButton*5 + 4*4,
          height: 37,
          child: TextButton(
            onPressed: () => processor.addQuantityText(context,ref,quantityController,-1),
            style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: Size(widthButton*5 + 4*4, 37), // width of 5 buttons + 4 spacing
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(5),

                )
            ),

            child: Text(
              Messages.CLEAR,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSizeMedium
              ),
            ),
          ),
        ),

      ],
    ),
  );


}
void addText(BuildContext context,WidgetRef ref,TextEditingController textController,
    String text){
  textController.text = textController.text+text;
}
void removeText(BuildContext context,WidgetRef ref,TextEditingController textController){
  textController.text = textController.text.substring(0,textController.text.length-1);
}

Widget getSearchBar(BuildContext context,WidgetRef ref,String hintText, int actionScan,
    void Function({required WidgetRef ref,required String inputData,required int actionScan
     }) onOk, ){
  var isScanning = ref.watch(isScanningProvider.notifier);
  var usePhoneCamera = ref.watch(usePhoneCameraToScanProvider.notifier);
  var inputString = ref.watch(inputStringProvider.notifier);



  return
    SizedBox(
      //width: double.infinity,
      width: MediaQuery.of(context).size.width - 30,
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 5,
        children: [
          IconButton(onPressed: (){
            isScanning.state = false ;
            usePhoneCamera.state = !usePhoneCamera.state;
            ref.read(isDialogShowedProvider.notifier).state = false;
          }, icon: Icon(usePhoneCamera.state?
          Icons.camera : Icons.barcode_reader, color:
          ref.watch(isDialogShowedProvider.notifier).state? Colors.red : Colors.purple,)),
          Expanded(
            child: Text(
              inputString.state =='' ? hintText : inputString.state,
              textAlign: TextAlign.center,
            ),
          ) ,
          IconButton(onPressed:() async {
            if(context.mounted){
              openInputDialogWithAction(ref: ref,history: true,onOk:onOk,
                  actionScan:actionScan);
            }
          },
              icon: Icon( Icons.search, color:isScanning.state ?Colors.grey: Colors.purple,)),
          IconButton(onPressed:() async {
            //isScanning.state = false ;
            //isDialogShowed.state = true;
            //await Future.delayed(const Duration(microseconds: 100));
            if(context.mounted){
              openInputDialogWithAction(ref: ref,history: false,onOk:onOk, actionScan: actionScan);
            }
          },
              icon: Icon( Icons.history, color:isScanning.state?Colors.grey: Colors.purple,)),

        ],
      ),
    );

}
String getTip(int action) {
  switch(action){
    case Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND:
      return ' (UPC)';
    case Memory.ACTION_GET_LOCATOR_TO_VALUE:
      return ' (LOC)';
    case Memory.ACTION_FIND_MOVEMENT_BY_ID:
      return ' (MV)';
    case Memory.ACTION_GO_TO_STORAGE_ON_HAND_PAGE_WITH_UPC:
      return ' (GO UPC)';
    case Memory.ACTION_FIND_PRINTER_BY_QR:
      return ' (PRINTER)';
    default:
      return '';


  }

}

Widget buttonScanWithPhone(BuildContext context,WidgetRef ref,InputDataProcessor processor) {
  var isScanning = ref.watch(isScanningProvider);
  var actionScan = ref.watch(actionScanProvider);

  Color backgroundColor =  Colors.cyan[800]!;
  return TextButton(

    style: TextButton.styleFrom(
      backgroundColor: isScanning ? Colors.grey :backgroundColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),

    ),
    onPressed: isScanning ? null :  () async {
      ref.watch(isScanningProvider.notifier).state = true;
      String? result= await SimpleBarcodeScanner.scanBarcode(
        context,
        barcodeAppBar: BarcodeAppBar(
          appBarTitle: Messages.SCANNING,
          centerTitle: false,
          enableBackButton: true,
          backButtonIcon: Icon(Icons.arrow_back_ios),
        ),
        isShowFlashIcon: true,
        delayMillis: 300,
        cameraFace: CameraFace.back,
      );
      if(result!=null){
        isScanning = false;
        if(context.mounted){
          processor.handleInputString(ref:ref, inputData: result, actionScan: actionScan);
        }
      } else {
        isScanning = false;
      }
    },
    child: Text(Messages.OPEN_CAMERA+getTip(actionScan),style: TextStyle(fontSize: themeFontSizeLarge,
        color: Colors.white),),

  );
}
Future<int?> openInputNumberDialogWithResult(
    BuildContext context,
    WidgetRef ref,
    bool history,

    ) async {
  var actionScan = ref.watch(actionScanProvider.notifier);
  print('actionScan.state -- ${actionScan.state}');

  String title = Messages.INPUT_DATA;

  if (actionScan.state == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
    title = Messages.FIND_MOVEMENT_BY_ID;
  } else if (actionScan.state ==
      Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND) {
    title = Messages.FIND_PRODUCT_BY_UPC_SKU;
  } else if (actionScan.state == Memory.ACTION_GET_LOCATOR_TO_VALUE) {
    title = Messages.FIND_LOCATOR;
  }

  TextEditingController controller = TextEditingController();

  if (history) {
    String lastSearch = Memory.lastSearch;

    if (actionScan.state == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      lastSearch = Memory.lastSearchMovement;
    }

    if (lastSearch == '-1') lastSearch = '';

    controller.text =
    lastSearch.isEmpty ? Messages.NO_RECORDS_FOUND : lastSearch;
  }

  final int? result = await showModalBottomSheet<int?>(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        fontSize: fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      keyboardType: TextInputType.none,
                    ),
                  ),

                  keyboardButtons(context, ref, controller),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    spacing: 10,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            Navigator.pop(context, null);
                          },
                          child: Text(Messages.CANCEL),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            final text = controller.text;

                            if (text.isEmpty) {
                              showErrorMessage(
                                  context, ref, Messages.TEXT_FIELD_EMPTY);
                              return;
                            }

                            if (actionScan.state ==
                                Memory.ACTION_FIND_MOVEMENT_BY_ID) {
                              Memory.lastSearchMovement = text;
                            } else {
                              Memory.lastSearch = text;
                            }

                            // 🔥 ahora se usa la función callback
                            //onOk(context, ref, text);

                            Navigator.pop(context, int.tryParse(text));
                          },
                          child: Text(Messages.CONFIRM),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  ref.read(isDialogShowedProvider.notifier).state = false;
  return result;
}