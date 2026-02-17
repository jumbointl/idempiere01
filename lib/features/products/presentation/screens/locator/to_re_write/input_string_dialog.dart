import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/common/input_dialog.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../../../../common/input_data_processor.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../../../../common/messages_dialog.dart';
class InputStringDialog extends ConsumerStatefulWidget implements InputDataProcessor {
  int dialogType = Memory.TYPE_DIALOG_SEARCH;
  String title = Messages.INPUT_DIALOG_TITLE;
  final StateProvider textStateProvider;
  final StateProvider fireActionProvider;
  InputStringDialog({required this.title
    , required this.textStateProvider,
    required this.fireActionProvider,
    required this.dialogType, super.key});


  @override
  ConsumerState<InputStringDialog> createState() => InputStringDialogState();



  @override
  Future<void> handleInputString(
      {required WidgetRef ref,
        required String inputData,
        required int actionScan}) async {
    if (inputData == '') {
      showErrorMessage(ref.context, ref, Messages.ERROR_LOCATOR_EMPTY);
    } else {
      var textState = ref.read(textStateProvider.notifier);
      textState.update((state) => inputData);
      ref.read(fireActionProvider.notifier).state++;
    }
  }

}

class InputStringDialogState extends ConsumerState<InputStringDialog> {
  late var textState;

  @override
  Widget build(BuildContext context) {
    debugPrint('Action Scan: ${ref.read(actionScanProvider)}');
     switch(widget.dialogType){
       case Memory.TYPE_DIALOG_SEARCH: // Barcode input dialog
         return IconButton(
           icon: const Icon(Icons.search), // Default icon
           onPressed: () async {
             getInputText(context,ref);
           },
           color: Colors.purple,
         );
       case Memory.TYPE_DIALOG_HISTOY: // Barcode input dialog
         return IconButton(
           icon: const Icon(Icons.history), // Default icon
           onPressed: () async {
             getInputText(context,ref);
           },
           color: Colors.purple,
         );
      default: // Tile input dialog
        return TextButton(
          child: Text(widget.title), // Default text
          onPressed: () async {
            getInputText(context,ref);
          },
        );
     }
  }
  Future<void> getInputText(BuildContext context, WidgetRef ref) async{
    bool history = false ;
    if(widget.dialogType == Memory.TYPE_DIALOG_HISTOY){
      history = true;
    }
    final actionScan = ref.read(actionScanProvider);
    openInputDialogWithAction(ref: ref, history:
    history,onOk: widget.handleInputString, actionScan:actionScan);


  }
}