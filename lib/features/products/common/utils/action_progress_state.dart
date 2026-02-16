import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

@immutable
class ActionProgressState {
  final bool visible;
  final int step;
  final int totalSteps;
  final String message;
  final bool? isOpen;
  final BuildContext? dialogContext;


  const ActionProgressState({
    this.visible = false,
    this.step = 0,
    this.totalSteps = 6,
    this.message = '',
    this.isOpen = false,
    this.dialogContext,
  });

  /// Progress value 0 → 1 for LinearProgressIndicator
  double get value {
    if (totalSteps <= 0) return 0;
    final v = step / totalSteps;
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }

  ActionProgressState copyWith({
    bool? visible,
    int? step,
    int? totalSteps,
    String? message, bool? isOpen,
    BuildContext? dialogContext,
  }) {
    return ActionProgressState(
      visible: visible ?? this.visible,
      step: step ?? this.step,
      totalSteps: totalSteps ?? this.totalSteps,
      message: message ?? this.message,
      isOpen: isOpen ?? this.isOpen,
      dialogContext: dialogContext ?? this.dialogContext,
    );
  }
}

class ActionProgressNotifier extends StateNotifier<ActionProgressState> {
  ActionProgressNotifier() : super(const ActionProgressState());

  /// Start progress flow
  void start({String message = 'Iniciando proceso...'}) {
    state = state.copyWith(
      visible: true,
      step: 0,
      message: message,
    );
  }

  /// Set step progress
  void setStep(int step, String message) {
    state = state.copyWith(
      visible: true,
      step: step,
      message: message,
    );
  }

  /// Advance 1 step automatically
  void next(String message) {
    final nextStep = state.step + 1;
    state = state.copyWith(
      visible: true,
      step: nextStep > state.totalSteps ? state.totalSteps : nextStep,
      message: message,
    );
  }

  /// Finish progress
  void finish({String message = 'Completado'}) {
    state = state.copyWith(
      step: state.totalSteps,
      message: message,
      visible: true,
    );
  }

  /// Hide dialog / reset
  void hide() {
    state = const ActionProgressState();
  }

  /// Force reset but keep hidden
  void reset() {
    state = state.copyWith(
      step: 0,
      message: '',
    );
  }
  void markDialogOpened(BuildContext ctx) {
    state = state.copyWith(isOpen: true, dialogContext: ctx);
  }

  void markDialogClosed() {
    state = state.copyWith(isOpen: false, dialogContext: null);
  }

}
final actionProgressProvider =
StateNotifierProvider<ActionProgressNotifier, ActionProgressState>(
      (ref) => ActionProgressNotifier(),
);
