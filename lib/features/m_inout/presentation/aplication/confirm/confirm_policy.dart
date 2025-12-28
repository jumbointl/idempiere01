import '../../providers/m_in_out_providers.dart';
import 'confirm_decision.dart';

class ConfirmPolicy {
  /// 🎯 對外唯一入口
  ConfirmDecision evaluate(MInOutStatus state) {
    final mInOut = state.mInOut;
    if (mInOut == null) {
      return const ConfirmDecision(
        allowed: false,
        flow: ConfirmFlow.notAllowed,
        reason: 'Documento no cargado',
      );
    }

    // 1️⃣ 立即可 confirm（不看 lines）
    if (_isImmediateConfirm(state)) {
      return const ConfirmDecision(
        allowed: true,
        flow: ConfirmFlow.directConfirm,
      );
    }

    // 2️⃣ 需要檢查 lines
    if (!_allLinesValid(state)) {
      return const ConfirmDecision(
        allowed: false,
        flow: ConfirmFlow.notAllowed,
        reason: 'Existen líneas pendientes o inválidas',
      );
    }

    // 3️⃣ 確認流程類型
    return ConfirmDecision(
      allowed: true,
      flow: _confirmFlowByType(state.mInOutType),
    );
  }

  // ================= helpers =================

  bool _isImmediateConfirm(MInOutStatus state) {
    final type = state.mInOutType;
    final docStatus = state.mInOut?.docStatus.id?.toString();

    // Move 永遠可 confirm
    if (type == MInOutType.move) return true;

    // Shipment / Receipt 在 IP 狀態可直接 confirm
    if ((type == MInOutType.shipment || type == MInOutType.receipt) &&
        docStatus == 'IP') {
      return true;
    }

    return false;
  }

  bool _allLinesValid(MInOutStatus state) {
    final validStatuses = <String>{
      'correct',
      'manually-correct',
      if (state.rolCompleteLow) 'minor',
      if (state.rolCompleteLow) 'manually-minor',
      if (state.rolCompleteOver) 'over',
      if (state.rolCompleteOver) 'manually-over',
    };

    return state.mInOut?.lines.every(
          (line) =>
      line.verifiedStatus != null &&
          line.verifiedStatus != 'pending' &&
          validStatuses.contains(line.verifiedStatus),
    ) ??
        false;
  }

  ConfirmFlow _confirmFlowByType(MInOutType type) {
    switch (type) {
      case MInOutType.shipment:
      case MInOutType.receipt:
      case MInOutType.move:
        return ConfirmFlow.directConfirm;

      case MInOutType.shipmentConfirm:
      case MInOutType.receiptConfirm:
      case MInOutType.pickConfirm:
      case MInOutType.qaConfirm: // ✅ QA = pickConfirm 規則
      case MInOutType.moveConfirm:
        return ConfirmFlow.confirmWithLines;
    }
  }
}
