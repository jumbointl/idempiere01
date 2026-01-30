


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
Future<String?> openInputDialogWithResultMultiLine(
    BuildContext context,
    WidgetRef ref,
    bool history, {
      required String title,
      required String value,
      required bool numberOnly,
      required int maxLines,
    }) async {
        return openInputDialogWithResult(context, ref, history,
            title: title, value: value,
            numberOnly: numberOnly, maxLines: maxLines);

    }

Future<String?> openInputDialogWithResult(
    BuildContext context,
    WidgetRef ref,
    bool history, {
      required String title,
      required String value,
      required bool numberOnly,
      int? maxLines = 1,
    }) async {
  final TextEditingController controller = TextEditingController();
  final FocusNode dialogFocusNode = FocusNode();


  // ===== Inicializar texto =====
  if (numberOnly) {
    final double? aux = double.tryParse(value);
    if (aux != null) {
      controller.text = aux.toInt().toString();
    } else {
      controller.text = value;
    }
  } else {
    controller.text = value;
  }
  String lastSearch = Memory.lastSearch;
  if (lastSearch == '-1') lastSearch = '';

  if (history) {

    controller.text = lastSearch.isEmpty ? Messages.NO_RECORDS_FOUND : lastSearch;
  } else {
    controller.text = lastSearch;
  }


  if (numberOnly) {
    ref.read(useNumberKeyboardProvider.notifier).state = true;
  }

  // (Opcional pero útil) Mientras el diálogo esté abierto, evita que la pantalla base reciba foco
  // y apaga scanner/teclado externo si lo usas.
  ref.read(enableScannerKeyboardProvider.notifier).state = false;
  ref.read(isDialogShowedProvider.notifier).state = true;
  final int actualAction = ref.read(actionScanProvider);
  ref.read(actionScanProvider.notifier).state = Memory.ACTION_NO_SCAN_ACTION;

  final String? result = await showModalBottomSheet<String?>(
    isScrollControlled: true,
    context: context,
    builder: (BuildContext sheetCtx) {
      return Consumer(
        builder: (context, ref, child) {
          final useNumberKeyboard = ref.watch(useNumberKeyboardProvider);
          final useScreenKeyBoard = ref.watch(useScreenKeyboardProvider);

          final bottomInset = MediaQuery.of(sheetCtx).viewInsets.bottom;

          // English: shared submit logic (button + Enter)
          void submit() {
            final text = controller.text.trim();
            dialogFocusNode.unfocus();
            FocusScope.of(sheetCtx).unfocus();
            Navigator.pop(sheetCtx, text);
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              ref.read(enableScannerKeyboardProvider.notifier).state = true;
              ref.read(isDialogShowedProvider.notifier).state = false;
              ref.read(actionScanProvider.notifier).state = actualAction;
              Navigator.pop(sheetCtx, null);
            },
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset,top: 150),
                child: FractionallySizedBox(
                  heightFactor: 0.92,
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ===== Title (top) =====
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),

                        // ===== Input row =====
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: useScreenKeyBoard && !numberOnly
                                    ? IconButton(
                                  icon: Icon(
                                    useNumberKeyboard
                                        ? Icons.keyboard
                                        : Icons.numbers,
                                    color: Colors.purple,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(useNumberKeyboardProvider.notifier)
                                        .state = !useNumberKeyboard;
                                  },
                                )
                                    : const SizedBox.shrink(),
                              ),
                              Expanded(
                                child: TextField(
                                  focusNode: dialogFocusNode,
                                  controller: controller,
                                  maxLines: maxLines,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                  keyboardType: numberOnly
                                      ? TextInputType.number
                                      : TextInputType.text,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => submit(),
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: IconButton(
                                  icon: Icon(
                                    useScreenKeyBoard
                                        ? Symbols.keyboard_off_rounded
                                        : Symbols.keyboard_rounded,
                                    color: Colors.purple,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(useScreenKeyboardProvider.notifier)
                                        .state = !useScreenKeyBoard;
                                    FocusScope.of(sheetCtx).unfocus();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ===== Keyboard panel =====
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (useScreenKeyBoard)
                                  useNumberKeyboard
                                      ? numberButtonsNoProcessor(
                                    ref: ref,
                                    context: sheetCtx,
                                    textController: controller,
                                    numberOnly: numberOnly,
                                  )
                                      : keyboardButtons(
                                      sheetCtx, ref, controller),
                              ],
                            ),
                          ),
                        ),

                        // ===== Buttons (always visible) =====
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    dialogFocusNode.unfocus();
                                    Navigator.pop(sheetCtx, null);
                                  },
                                  child: Text(Messages.CANCEL),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: submit,
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
            ),
          );
        },
      );
    },

  );

  // ✅ Al cerrar: liberar foco + restaurar scanner
  await Future.delayed(const Duration(milliseconds: 500));
  try {
    dialogFocusNode.unfocus();
    if(context.mounted)FocusScope.of(context).unfocus();
  } catch (_) {}
  if (dialogFocusNode.hasFocus) {
    dialogFocusNode.unfocus();
  }
  dialogFocusNode.dispose();
  controller.dispose();

  ref.read(isDialogShowedProvider.notifier).state = false;
  ref.read(enableScannerKeyboardProvider.notifier).state = true;
  ref.read(actionScanProvider.notifier).state = actualAction;

  return result;
}



Future<bool?> openBottomSheetConfirmationDialog(


    {required  WidgetRef ref, required String title ,
      required String message,String? subtitle ='',
      }

    ) async {

   int actualAction = ref.read(actionScanProvider);
   ref.read(isDialogShowedProvider.notifier).state = true;
   ref.read(actionScanProvider.notifier).state = Memory.ACTION_NO_SCAN_ACTION;

  final result = await showModalBottomSheet<bool?>(
    isScrollControlled: true,
    context: ref.context,
    builder: (BuildContext context) {


      return Consumer(
        builder: (context, ref, child) {
          return FractionallySizedBox(
            heightFactor: 0.8,
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
   ref.read(actionScanProvider.notifier).state = actualAction;
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


  String lastSearch = Memory.lastSearch;


  String title = Messages.INPUT_DATA;

  if (actionScan == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
    title = Messages.FIND_MOVEMENT_BY_ID;
  } else if (actionScan == Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND) {
    title = Messages.FIND_PRODUCT_BY_UPC_SKU;
  } else if (actionScan == Memory.ACTION_GET_LOCATOR_TO_VALUE) {
    title = Messages.FIND_LOCATOR;
  }

  final controller = TextEditingController();
  lastSearch = Memory.lastSearch;
  if (actionScan == Memory.ACTION_FIND_MOVEMENT_BY_ID) {
    lastSearch = Memory.lastSearchMovement;
  }
  if (lastSearch == '-1') lastSearch = '';
  if (history) {
    controller.text =
    lastSearch.isEmpty ? Messages.NO_RECORDS_FOUND : lastSearch;
  } else {
    controller.text = lastSearch;
  }
  ref.read(actionScanProvider.notifier).state = Memory.ACTION_NO_SCAN_ACTION;
  ref.read(isDialogShowedProvider.notifier).state = true;
  final result = await showModalBottomSheet<String?>(
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    context: ref.context,
    builder: (BuildContext context) {
      return Consumer(
        builder: (context, ref, _) {
          final useNumberKeyboard = ref.watch(useNumberKeyboardProvider);
          final useScreenKeyBoard = ref.watch(useScreenKeyboardProvider);

          // English: Use viewInsets to push content above the system keyboard
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          // English: Local helper to run "confirm" logic from both button and Enter key
          void submit() {
            final text = controller.text.trim();

            if (text.isEmpty) {
              showErrorMessage(context, ref, Messages.TEXT_FIELD_EMPTY);
              return;
            }

            ref.read(isDialogShowedProvider.notifier).state = false;
            ref.read(actionScanProvider.notifier).state = actionScan;

            onOk(
              ref: ref,
              inputData: text,
              actionScan: actionScan,
            );

            Navigator.pop(context, text);
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              ref.read(isDialogShowedProvider.notifier).state = false;
              ref.read(actionScanProvider.notifier).state = actionScan;
              Navigator.pop(context, null);
            },
            child: SafeArea(
              child: Padding(
                // English: This is the key line that makes the sheet move up with the keyboard
                padding: EdgeInsets.only(bottom: bottomInset,top: 150),
                child: FractionallySizedBox(
                  heightFactor: 0.92,
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // English: Header pinned to the top
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),

                        // English: Text field row pinned near the top
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: useScreenKeyBoard
                                    ? IconButton(
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
                                    color: Colors.purple,
                                  ),
                                )
                                    : const SizedBox.shrink(),
                              ),
                              Expanded(
                                child: TextField(
                                  autofocus: true,
                                  maxLines: 1,
                                  controller: controller,
                                  style: TextStyle(
                                    fontSize: fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                  keyboardType: numberOnly == true
                                      ? TextInputType.number
                                      : TextInputType.text,

                                  // English: Show "done" (or "search") button on keyboard
                                  textInputAction: TextInputAction.done,

                                  // English: Pressing Enter submits
                                  onSubmitted: (_) => submit(),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final oldValue =
                                  ref.read(useScreenKeyboardProvider);
                                  ref
                                      .read(useScreenKeyboardProvider.notifier)
                                      .state = !oldValue;
                                },
                                icon: Icon(
                                  useScreenKeyBoard
                                      ? Symbols.keyboard_off_rounded
                                      : Symbols.keyboard_rounded,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // English: Keyboard panel area scrollable if needed
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                if (useScreenKeyBoard)
                                  (numberOnly == true)
                                      ? numberButtonsNoProcessor(
                                    context: context,
                                    ref: ref,
                                    textController: controller,
                                    numberOnly: true,
                                  )
                                      : (useNumberKeyboard
                                      ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: numberButtonsNoProcessor(
                                      context: context,
                                      ref: ref,
                                      textController: controller,
                                    ),
                                  )
                                      : keyboardButtons(context, ref, controller)),
                              ],
                            ),
                          ),
                        ),

                        // English: Bottom buttons pinned and always visible
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    ref.read(isDialogShowedProvider.notifier).state =
                                    false;
                                    ref.read(actionScanProvider.notifier).state =
                                        actionScan;
                                    Navigator.pop(context, null);
                                  },
                                  child: Text(Messages.CANCEL),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.green,
                                  ),
                                  // English: Same submit logic as Enter key
                                  onPressed: submit,
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
            ),
          );
        },
      );
    },
  );


  ref.read(isDialogShowedProvider.notifier).state = false;

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
              width: widthButton*2,
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
              width: widthButton*2,
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
              width: widthButton * 2,
              height: widthButton,
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(5),
                  onTap: () async {

                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text == null) {
                      if(context.mounted)showErrorMessage(context, ref, Messages.NO_DATA_ON_CLIPBOARD);
                      return;
                    }

                    textController.text = data!.text!;
                  },
                  child: const Icon(
                    Icons.content_paste,
                    color: Colors.purple,
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
  final double keyboardWidth = MediaQuery.of(context).size.width * 0.55;
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
/*Future<void> getDoubleDialog({
  required WidgetRef ref,
  required double quantity,
  required StateProvider<double> targetProvider,   // 👈 NUEVO
}) async {
  final TextEditingController quantityController = TextEditingController();
  final double qtyOnHand = quantity;
  BuildContext context = ref.context;

  quantityController.text = quantity.toStringAsFixed(0);
  final int actualAction = ref.read(actionScanProvider);
  ref.read(actionScanProvider.notifier).state = Memory.ACTION_NO_SCAN_ACTION;
  ref.read(isDialogShowedProvider.notifier).state = true;
  final useScreenKeyBoard = ref.watch(useScreenKeyboardProvider);


  await showModalBottomSheet(
    isDismissible: false,
    enableDrag: false,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          textAlign: TextAlign.end,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: fontSizeLarge,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: IconButton(
                          onPressed: () {
                            final oldValue =
                            ref.read(useScreenKeyboardProvider);
                            ref
                                .read(useScreenKeyboardProvider.notifier)
                                .state = !oldValue;


                          },

                          icon: Icon(
                            useScreenKeyBoard
                                ? Symbols.keyboard_off_rounded
                                : Symbols.keyboard_rounded,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ],
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
                          ref.read(actionScanProvider.notifier).state = actualAction;
                          ref.read(isDialogShowedProvider.notifier).state = false;
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
                              ref.read(actionScanProvider.notifier).state = actualAction;
                              ref.read(isDialogShowedProvider.notifier).state = false;
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
}*/

Future<void> getDoubleDialog({
  required WidgetRef ref,
  required double quantity,
  required StateProvider<double> targetProvider,
}) async {
  final quantityController = TextEditingController();
  final focusNodeQty = FocusNode();

  final double qtyOnHand = quantity;
  final context = ref.context;

  quantityController.text = quantity.toStringAsFixed(0);

  final int actualAction = ref.read(actionScanProvider);
  ref.read(actionScanProvider.notifier).state = Memory.ACTION_NO_SCAN_ACTION;
  ref.read(isDialogShowedProvider.notifier).state = true;

  bool focusRequested = false;
  bool isClosing = false;
  try {
    await showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        // ✅ Consumer para que ref2.watch reactive el UI del bottomsheet
        return Consumer(
          builder: (context, ref2, _) {
            final useScreenKeyBoard = ref2.watch(useScreenKeyboardProvider);

            // ✅ Pedir foco solo cuando se usa teclado del sistema
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isClosing) return;
              if (!ctx.mounted) return;
              if (!focusNodeQty.canRequestFocus) return;
              if (!focusNodeQty.context!.mounted ?? true) return;
              if (!useScreenKeyBoard &&
                  !focusRequested &&
                  focusNodeQty.canRequestFocus) {
                focusNodeQty.requestFocus();
                focusRequested = true;
              }
            });
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset,top: 150),
              child: FractionallySizedBox(
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
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  focusNode: focusNodeQty,
                                  controller: quantityController,
                                  textAlign: TextAlign.end,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    // English: same logic as OK button
                                    final txt = quantityController.text.trim();
                                    final aux = double.tryParse(txt);
                                    if (aux != null && aux > 0 && aux <= qtyOnHand) {
                                      ref2.read(targetProvider.notifier).state = aux;
                                      ref2.read(actionScanProvider.notifier).state = actualAction;
                                      ref2.read(isDialogShowedProvider.notifier).state = false;
                                      Navigator.of(ctx).pop();
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 60,
                                child: IconButton(
                                  onPressed: () {
                                    final oldValue =
                                    ref2.read(useScreenKeyboardProvider);

                                    // Si se va a activar el teclado en pantalla,
                                    // quitamos foco para esconder el teclado del sistema.
                                    final newValue = !oldValue;
                                    ref2
                                        .read(useScreenKeyboardProvider.notifier)
                                        .state = newValue;

                                    if (newValue) {
                                      FocusScope.of(ctx).unfocus();
                                      focusRequested = false; // 👈 importante
                                    } else {
                                      // volveremos a pedir foco en el postFrame
                                      focusRequested = false;
                                    }
                                  },
                                  icon: Icon(
                                    useScreenKeyBoard
                                        ? Symbols.keyboard_off_rounded
                                        : Symbols.keyboard_rounded,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ Solo mostrar tu teclado “en pantalla” cuando está activo
                        if (useScreenKeyBoard)
                          numberButtonsNoProcessor(
                            ref: ref2,
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
                                  isClosing = true;
                                  FocusScope.of(ctx).unfocus();
                                  ref2.read(targetProvider.notifier).state = 0;
                                  ref2.read(actionScanProvider.notifier).state =
                                      actualAction;
                                  ref2
                                      .read(isDialogShowedProvider.notifier)
                                      .state = false;
                                  Navigator.of(ctx).pop();
                                },
                                child: Text(Messages.CANCEL),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  final txt = quantityController.text.trim();
                                  if (txt.isEmpty) {
                                    showErrorMessage(
                                      ctx,
                                      ref2,
                                      '${Messages.ERROR_QUANTITY} ${Messages.EMPTY}',
                                    );
                                    return;
                                  }

                                  final aux = double.tryParse(txt);
                                  if (aux != null && aux > 0) {
                                    if (aux <= qtyOnHand) {
                                      isClosing = true;
                                      FocusScope.of(ctx).unfocus();
                                      ref2
                                          .read(targetProvider.notifier)
                                          .state = aux;
                                      ref2
                                          .read(actionScanProvider.notifier)
                                          .state = actualAction;
                                      ref2
                                          .read(isDialogShowedProvider.notifier)
                                          .state = false;
                                      Navigator.of(ctx).pop();
                                    } else {
                                      final msg =
                                          '${Messages.ERROR_QUANTITY} ${Memory.numberFormatter0Digit.format(aux)} > ${Memory.numberFormatter0Digit.format(qtyOnHand)}';
                                      showErrorMessage(ctx, ref2, msg);
                                      quantityController.text =
                                          Memory.numberFormatter0Digit
                                              .format(qtyOnHand);
                                    }
                                  } else {
                                    showErrorMessage(
                                      ctx,
                                      ref2,
                                      '${Messages.ERROR_QUANTITY} '
                                          '${aux == null ? Messages.EMPTY : txt}',
                                    );
                                  }
                                },
                                child: Text(Messages.OK),
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
  } finally {
    await Future.delayed(const Duration(milliseconds: 500));
    focusNodeQty.dispose();
    quantityController.dispose();
  }
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




