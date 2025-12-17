import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_confirm_screen_state.dart';

import '../../../../../shared/data/memory.dart';
import '../../../../../shared/data/messages.dart';
import '../provider/new_movement_provider.dart';

class MovementCancelScreenState extends MovementConfirmScreenState {
  MovementCancelScreenState createState() => MovementCancelScreenState();
  @override
  AsyncValue get actionAsync => ref.watch(cancelMovementProvider);
  @override
  String get getTitleMessage => Messages.CANCEL_MOVEMENT;
  @override
  bool get isActionSuccess  {
    String doc = widget.movementAndLines.docStatus?.id ?? '';
    print('isActionSuccess $doc = ${Memory.IDEMPIERE_DOC_TYPE_CANCEL}');
    return doc == Memory.IDEMPIERE_DOC_TYPE_CANCEL;
  }
  @override
  Future<void> actionAfterShow(WidgetRef ref) async{
    print('MovementCancelScreenState') ;
    if(movementAndLines?.canCancelMovement==false){
      String message = Messages.ERROR_CANNOT_CANCEL_MOVEMENT;
      showAutoCloseErrorDialog(context, ref,
          message,5);
      return;
    }
    if(!started){
      started = true;
      stateNotifier.cancelMovement(widget.movementAndLines.id);
    }
  }
}