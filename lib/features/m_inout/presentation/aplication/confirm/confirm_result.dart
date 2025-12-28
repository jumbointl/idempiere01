import '../../../domain/entities/m_in_out.dart';

sealed class ConfirmResult {
  const ConfirmResult();
}

class ConfirmOk extends ConfirmResult {
  final MInOut document;
  const ConfirmOk(this.document);
}

class ConfirmDenied extends ConfirmResult {
  final String reason;
  const ConfirmDenied(this.reason);
}

class ConfirmFail extends ConfirmResult {
  final String message;
  const ConfirmFail(this.message);
}
