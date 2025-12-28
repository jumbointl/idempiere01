import '../../../domain/entities/m_in_out_confirm.dart';
import '../../../presentation/providers/m_in_out_providers.dart'; // MInOutType

sealed class LoadMInOutAction {
  const LoadMInOutAction();
}

class LoadSuccess extends LoadMInOutAction {
  const LoadSuccess();
}

class LoadError extends LoadMInOutAction {
  final String message;
  const LoadError(this.message);
}

class NeedSelectConfirm extends LoadMInOutAction {
  final List<MInOutConfirm> confirms;
  const NeedSelectConfirm(this.confirms);
}

enum ConfirmCreateKind {
  pickLike,   // pickConfirm + qaConfirm
  shipment,   // shipmentConfirm
}

class NeedCreateConfirm extends LoadMInOutAction {
  final ConfirmCreateKind kind;
  final MInOutType targetType; // pickConfirm 或 qaConfirm 或 shipmentConfirm
  final String documentNo;
  final String mInOutId;

  const NeedCreateConfirm({
    required this.kind,
    required this.targetType,
    required this.documentNo,
    required this.mInOutId,
  });
}
