import 'package:flutter_riverpod/legacy.dart';
import 'package:formz/formz.dart';
import 'package:monalisa_app_001/features/auth/presentation/providers/auth_provider.dart';
import 'package:monalisa_app_001/features/shared/shared.dart';

// LoginFormState3 - StateNotifierProvider - consume afuera
final loginFormProvider =
    StateNotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>((ref) {
  final loginUserCallback = ref.watch(authProvider.notifier).login;
  return LoginFormNotifier(loginUserCallback: loginUserCallback);
});

// 2 - Como implementamos un notifier
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  final Function(String, String, bool) loginUserCallback;
  LoginFormNotifier({
    required this.loginUserCallback,
  }) : super(LoginFormState());

  void onUserNameChange(String value) {
    final newUserName = Title.dirty(value);
    state = state.copyWith(
        userName: newUserName,
        isValid: Formz.validate([newUserName, state.password]));
  }

  void onPasswordChanged(String value) {
    final newPassword = Password.dirty(value);
    state = state.copyWith(
        password: newPassword,
        isValid: Formz.validate([newPassword, state.userName]));
  }

  Future<void> onFormSubmit() async {
    _touchEveryField();
    if (!state.isValid) return;
    state = state.copyWith(isPosting: true);
    await loginUserCallback(state.userName.value, state.password.value, false);
    state = state.copyWith(isPosting: false);
  }

  void _touchEveryField() {
    final userName = Title.dirty(state.userName.value);
    final password = Password.dirty(state.password.value);
    state = state.copyWith(
      isFormPosted: true,
      userName: userName,
      password: password,
      isValid: Formz.validate([userName, password]),
    );
  }
}

// 1 - State del provider
class LoginFormState {
  final bool isPosting;
  final bool isFormPosted;
  final bool isValid;
  final Title userName;
  final Password password;

  LoginFormState({
    this.isPosting = false,
    this.isFormPosted = false,
    this.isValid = false,
    this.userName = const Title.dirty(''),
    this.password = const Password.pure(),
  });

  LoginFormState copyWith({
    bool? isPosting,
    bool? isFormPosted,
    bool? isValid,
    Title? userName,
    Password? password,
  }) =>
      LoginFormState(
        isPosting: isPosting ?? this.isPosting,
        isFormPosted: isFormPosted ?? this.isFormPosted,
        isValid: isValid ?? this.isValid,
        userName: userName ?? this.userName,
        password: password ?? this.password,
      );
}
