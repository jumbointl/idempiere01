
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_confirm_screen.dart';

import 'movement_cancel_screen_state.dart';

class MovementCancelScreen extends MovementConfirmScreen {
  MovementCancelScreen({super.key, required super.movementAndLines,
    required super.argument});
  @override
  ConsumerState<MovementConfirmScreen> createState() => MovementCancelScreenState();

}

