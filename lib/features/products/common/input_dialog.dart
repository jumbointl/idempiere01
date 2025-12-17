


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    {required String title , required String value,
      required bool numberOnly}

    ) async {

  TextEditingController controller = TextEditingController();
  if(numberOnly){
    double? aux = double.tryParse(value);
    if(aux!=null){
      int valueInt = aux.toInt() ;
      controller.text = valueInt.toString() ;
    }

  } else {
    controller.text = value;
  }


  if (history) {
    String lastSearch = Memory.lastSearch;


    if (lastSearch == '-1') lastSearch = '';

    controller.text =
    lastSearch.isEmpty ? Messages.NO_RECORDS_FOUND : lastSearch;
  }
  if(numberOnly) ref.read(useNumberKeyboardProvider.notifier).state = true;

  final result = await showModalBottomSheet<String?>(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {


      return Consumer(
        builder: (context, ref, child) {
          final useNumberKeyboard = ref.watch(useNumberKeyboardProvider);
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 5,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Row(
                          children: [
                            SizedBox(width: 60,),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                textAlign: TextAlign.center,
                                style: TextStyle(

                                  fontSize: fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                                keyboardType: TextInputType.none,
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: (numberOnly ==true) ? Container(): IconButton(
                                onPressed: () {
                                  final oldValue =
                                  ref.read(useNumberKeyboardProvider);
                                  ref
                                      .read(useNumberKeyboardProvider.notifier)
                                      .state = !oldValue;
                                  print(ref.read(useNumberKeyboardProvider));
                                },
                                icon: Icon(
                                  useNumberKeyboard
                                      ? Icons.keyboard
                                      : Icons.numbers,
                                  color: Colors.purple,),
                              ) ,
                            ),
                          ],
                        ),
                      ),

                      useNumberKeyboard ? numberButtonsNoProcessor(ref: ref, context:
                      context, textController: controller)
                          : keyboardButtons(context, ref, controller),

                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          spacing: 10,
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: ()
                                {
                                  Navigator.pop(context, null);
                                },
                                child: Text(Messages.CANCEL),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () {
                                  String text = controller.text;
                                  Navigator.pop(context, text);
                                },
                                child: Text(Messages.CONFIRM),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  ref.read(isDialogShowedProvider.notifier).state = false;
  return result;
}
Future<bool?> openBottomSheetConfirmationDialog(


    {required  WidgetRef ref, required String title ,
      required String message,String? subtitle ='',
      }

    ) async {


  final result = await showModalBottomSheet<bool?>(
    isScrollControlled: true,
    context: ref.context,
    builder: (BuildContext context) {


      return Consumer(
        builder: (context, ref, child) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      spacing: 5,
                      children: [
                        Icon(Symbols.live_help,size: 60,color: Colors.amber.shade700),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        if(subtitle!=null && subtitle.isNotEmpty)Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: fontSizeLarge,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),


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
                                onPressed: ()
                                {
                                  Navigator.pop(context, null);
                                },
                                child: Text(Messages.CANCEL),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () {
                                  Navigator.pop(context, true);
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
            ),
          );
        },
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
  bool? numberOnly,
  required void Function({
  required WidgetRef ref,
  required String inputData,
  required int actionScan,
  }) onOk,
}) async {
  String title = Messages.INPUT_DATA;

  if (actionScan == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
    title = Messages.FIND_MOVEMENT_BY_ID;
  } else if (actionScan == Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND) {
    title = Messages.FIND_PRODUCT_BY_UPC_SKU;
  } else if (actionScan == Memory.ACTION_GET_LOCATOR_TO_VALUE) {
    title = Messages.FIND_LOCATOR;
  }

  final controller = TextEditingController();

  if (history) {
    String lastSearch = Memory.lastSearch;

    if (actionScan == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
      lastSearch = Memory.lastSearchMovement;
    }

    if (lastSearch == '-1') lastSearch = '';

    controller.text =
    lastSearch.isEmpty ? Messages.NO_RECORDS_FOUND : lastSearch;
  }

  final result = await showModalBottomSheet<String?>(
    isScrollControlled: true,
    context: ref.context,
    builder: (BuildContext context) {
      // 👇 Aqui usamos um Consumer para ter um WidgetRef reativo
      return Consumer(
        builder: (context, ref, _) {
          final useNumberKeyboard = ref.watch(useNumberKeyboardProvider);

          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 5,
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
                        child: Row(
                          children: [
                            Expanded(
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
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                final oldValue =
                                ref.read(useNumberKeyboardProvider);
                                ref
                                    .read(useNumberKeyboardProvider.notifier)
                                    .state = !oldValue;
                              },
                              icon: Icon(
                                useNumberKeyboard
                                    ? Icons.keyboard
                                    : Icons.numbers,
                              color: Colors.purple,),
                            ),
                          ],
                        ),
                      ),
                      (numberOnly==true)  ? numberButtonsNoProcessor(
                          context: context, ref: ref, textController: controller,
                          numberOnly: true):
                      useNumberKeyboard
                          ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: numberButtonsNoProcessor
                              (context: context, ref: ref, textController: controller,)
                          )
                          : keyboardButtons(context, ref, controller),
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
                                  showErrorMessage(context, ref,
                                      Messages.TEXT_FIELD_EMPTY);
                                  return;
                                }

                                if (actionScan ==
                                    Memory.ACTION_FIND_MOVEMENT_BY_ID) {
                                  Memory.lastSearchMovement = text;
                                } else {
                                  Memory.lastSearch = text;
                                }

                                onOk(
                                  ref: ref,
                                  inputData: text,
                                  actionScan: actionScan,
                                );

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
    },
  );

  ref.read(isDialogShowedProvider.notifier).state = false;

  print('Dialog closed with: $result');
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

Widget numberButtonsNoProcessor(
    {required BuildContext context,required WidgetRef ref,
      required TextEditingController textController,
      bool? numberOnly =false }) {
  final double keyboardWidth = MediaQuery.of(context).size.width * 0.56;
  final double buttonWidth = keyboardWidth/5.5;


  // Definimos los botones numéricos
  final List<NumButtonData?> numericButtons = [
    NumButtonData(label: '1', value: 1),
    NumButtonData(label: '2', value: 2),
    NumButtonData(label: '3', value: 3),
    NumButtonData(label: '4', value: 4),
    NumButtonData(label: '5', value: 5),
    NumButtonData(label: '6', value: 6),
    NumButtonData(label: '7', value: 7),
    NumButtonData(label: '8', value: 8),
    NumButtonData(label: '9', value: 9),
    null, // celda vacía para completar 3x4
    NumButtonData(label: '0', value: 0),
    null, // celda vacía para completar 3x4
  ];

  return Center(
    child: Column(
      spacing: 10,
      children: [
        // ⬇️ Grid 3x4 con los números
        SizedBox(
          width: keyboardWidth,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1, // cuadrado
            children: numericButtons.map((btn) {
              if (btn == null) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () =>{
                  (numberOnly==true) ?
                 addQuantityText(context, ref, textController, btn.value)
                  : addText(context, ref, textController, btn.value.toString()),
                },

                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  btn.label,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ⬇️ Fila de controles especiales: -, ., <=, CLEAR
        SizedBox(
          width: keyboardWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // -
              TextButton(
                onPressed: () =>
                    addQuantityText(context, ref, textController, -4),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, buttonWidth),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  '-',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium,
                  ),
                ),
              ),

              // .
              TextButton(
                onPressed: () =>
                    addQuantityText(context, ref, textController, -3),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, buttonWidth),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  '.',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium,
                  ),
                ),
              ),

              // <=
              TextButton(
                onPressed: () =>
                    addQuantityText(context, ref, textController, -2),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, buttonWidth),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  '<=',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium,
                  ),
                ),
              ),

              // CLEAR (ocupa más ancho)
              SizedBox(
                height: buttonWidth,
                width: buttonWidth*2,
                child: TextButton(
                  onPressed: () =>
                      addQuantityText(context, ref, textController, -1),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(
                    Messages.CLEAR,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
Future<void> getDoubleDialog({
  required WidgetRef ref,
  required double quantity,
  required StateProvider<double> targetProvider,   // 👈 NUEVO
}) async {
  final TextEditingController quantityController = TextEditingController();
  final double qtyOnHand = quantity;
  BuildContext context = ref.context;

  quantityController.text = quantity.toStringAsFixed(0);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              spacing: 5,
              children: [
                Text(
                  Messages.QUANTITY_TO_MOVE,
                  style: TextStyle(
                    fontSize: fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: TextField(
                    enabled: false,
                    controller: quantityController,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: fontSizeLarge,
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                numberButtonsNoProcessor(
                  ref: ref,
                  textController: quantityController,
                  context: ctx,
                  numberOnly: true,
                ),


                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () {
                          ref.read(targetProvider.notifier).state = 0;
                          Navigator.of(ctx).pop();
                        },
                        child: Text(Messages.CANCEL),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final txt = quantityController.text.trim();

                          if (txt.isEmpty) {
                            showErrorMessage(ctx, ref,
                                '${Messages.ERROR_QUANTITY} ${Messages.EMPTY}');
                            return;
                          }

                          final double? aux = double.tryParse(txt);

                          if (aux != null && aux > 0) {
                            if (aux <= qtyOnHand) {
                              ref.read(targetProvider.notifier).state = aux;
                              Navigator.of(ctx).pop();
                            } else {
                              final msg =
                                  '${Messages.ERROR_QUANTITY} ${Memory.numberFormatter0Digit.format(aux)} > ${Memory.numberFormatter0Digit.format(qtyOnHand)}';

                              showErrorMessage(ctx, ref, msg);

                              quantityController.text =
                                  Memory.numberFormatter0Digit.format(qtyOnHand);
                              return;
                            }
                          } else {
                            showErrorMessage(
                                ctx,
                                ref,
                                '${Messages.ERROR_QUANTITY} '
                                    '${aux == null ? Messages.EMPTY : txt}');
                            return;
                          }
                        },
                        child: Text(Messages.OK),
                      ),
                    ),
                  ],
                ),

                //SizedBox(height: Memory.BOTTOM_BAR_HEIGHT),
              ],
            ),
          ),
        ),
      );
    },
  );
}


void addQuantityText(BuildContext context, WidgetRef ref,
    TextEditingController quantityController,int quantity) {

  String currentText = quantityController.text;
  if(quantity>=0){
    currentText = '$currentText$quantity';
    double? newQuantity = double.tryParse(currentText);
    if (newQuantity != null) {
      quantityController.text = currentText;
    }
  } else if(quantity==-1){
    quantityController.text ='';
  } else if(quantity==-2) {
    quantityController.text = currentText.substring(0, currentText.length - 1);
  } else if(quantity==-3){
    quantityController.text = '$currentText.';
  } else if(quantity==-4){
    if(!currentText.startsWith('-')) quantityController.text = '-$currentText';

  }


}

void addText(BuildContext context,WidgetRef ref,TextEditingController textController,
    String text){
  textController.text = textController.text+text;
}
void removeText(BuildContext context,WidgetRef ref,TextEditingController textController){
  textController.text = textController.text.substring(0,textController.text.length-1);
}




