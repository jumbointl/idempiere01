import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/product_provider_common.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
class InputStringDialog extends ConsumerStatefulWidget {
  int dialogType = Memory.TYPE_DIALOG_SEARCH;
  String title = Messages.INPUT_DIALOG_TITLE;
  final AutoDisposeStateProvider textStateProvider;
  InputStringDialog({required this.title, required this.textStateProvider,
    required this.dialogType, super.key});


  @override
  ConsumerState<InputStringDialog> createState() => InputStringDialogState();
}

class InputStringDialogState extends ConsumerState<InputStringDialog> {
  late var textState;

  @override
  Widget build(BuildContext context) {
     textState = ref.watch(widget.textStateProvider.notifier);
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
    TextEditingController controller = TextEditingController();
    print("IconButton pressed, dialogType: ${widget.dialogType}");
    // You would typically show a dialog here using showDialog or a similar method.
    // Example:
    if(widget.dialogType == Memory.TYPE_DIALOG_HISTOY){
      String lastSearch = Memory.lastSearch;
      if(lastSearch.isEmpty){
        controller.text = Messages.NO_RECORDS_FOUND;
      } else {
        controller.text = lastSearch;
      }

    }
    bool stateActual = ref.watch(usePhoneCameraToScanProvider.notifier).state;
    ref.watch(usePhoneCameraToScanProvider.notifier).state = true;
    AwesomeDialog(
        context: context,
        headerAnimationLoop: false,
        dialogType: DialogType.noHeader,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Center(
            child: Column(
              spacing: 10,
              children: [
                Text(widget.title),
                TextField(
                  controller: controller,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
        ),
        title: widget.title,
        desc: widget.title,
        btnCancelText: Messages.CANCEL,
        btnOkText: Messages.OK,
        btnOkOnPress: () {
          ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
          final result = controller.text;
          print('-------------------------result $result');
          Memory.lastSearch = result;
          if(result==''){
            AwesomeDialog(
              context: context,
              animType: AnimType.scale,
              dialogType: DialogType.error,
              body: Center(child: Text(
                Messages.ERROR_LOCATOR_EMPTY,
              ),), // correct here
              title: Messages.ERROR_LOCATOR_EMPTY,
              desc:   '',
              autoHide: const Duration(seconds: 3),
              btnOkOnPress: () {},
              btnOkColor: Colors.amber,
              btnCancelText: Messages.CANCEL,
              btnOkText: Messages.OK,
            ).show();
            return;
          }
          textState.state = result;
        },
        btnCancelOnPress: (){
          ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
          return ;
        }
    ).show();

  }
}