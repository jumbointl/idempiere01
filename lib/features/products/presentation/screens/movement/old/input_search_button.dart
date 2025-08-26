
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/src/pages/common/search_dialog.dart';

import '../../../providers/product_provider_common.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
class InputSearchButton extends ConsumerStatefulWidget {
  bool useLastSearch=false;
  SearchDialog searchDialog ;
  InputSearchButton({required this.searchDialog, required this.useLastSearch,super.key});

  @override
  ConsumerState<InputSearchButton> createState() => InputSearchButtonState();

}


class InputSearchButtonState extends ConsumerState<InputSearchButton> {

  @override
  Widget build(BuildContext context) {


    return IconButton(
      onPressed: () {
        print('------------------RE');
        openSearchDialog(context, widget.useLastSearch);
      },
      icon: Icon(widget.useLastSearch ? Icons.history : Icons.search, size: 24.sp),
      color: Colors.purple,

    );
  }
  Future<void> openSearchDialog(BuildContext context, bool history) async{
    TextEditingController controller = TextEditingController();
    if(history){
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
                Text(Messages.FIND),
                TextField(
                  controller: controller,
                  //style: const TextStyle(fontStyle: FontStyle.italic),
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
        ),
        title: Messages.FIND_BY_ID,
        desc: Messages.FIND_BY_ID,
        btnCancelText: Messages.CANCEL,
        btnOkText: Messages.OK,
        btnOkOnPress: () {
          ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
          final result = controller.text;
          print('-------------------------result $result');
          if(result==''){
            AwesomeDialog(
              context: context,
              animType: AnimType.scale,
              dialogType: DialogType.error,
              body: Center(child: Text(
                Messages.ERROR_ID,
                //style: TextStyle(fontStyle: FontStyle.italic),
              ),), // correct here
              title: Messages.ERROR_ID,
              desc:   '',
              autoHide: const Duration(seconds: 3),
              btnOkOnPress: () {},
              btnOkColor: Colors.amber,
              btnCancelText: Messages.CANCEL,
              btnOkText: Messages.OK,
            ).show();
            return;
          }
          ref.read(widget.searchDialog.getSearchStringProvider().notifier).state = result;
        },
        btnCancelOnPress: (){
          ref.watch(usePhoneCameraToScanProvider.notifier).state = stateActual;
          return ;
        }
    ).show();

  }
}
