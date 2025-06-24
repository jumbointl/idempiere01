import 'package:formz/formz.dart';

enum TitleError { empty }

class Title extends FormzInput<String, TitleError> {
  const Title.pure() : super.pure('');

  const Title.dirty(super.value) : super.dirty();

  String? get errorMessage {
    if (isValid || isPure) return null;
    if (displayError == TitleError.empty) return 'Este campo es requerido';
    return null;
  }

  @override
  TitleError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return TitleError.empty;
    return null;
  }
}
