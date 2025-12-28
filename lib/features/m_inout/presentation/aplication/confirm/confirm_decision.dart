
enum ConfirmFlow {
  directConfirm,        // 直接 setDocAction
  confirmWithLines,     // 需要先 updateLineConfirm
  notAllowed,           // 不可 confirm
}

class ConfirmDecision {
  final bool allowed;
  final ConfirmFlow flow;
  final String? reason;

  const ConfirmDecision({
    required this.allowed,
    required this.flow,
    this.reason,
  });

  static const notAllowed = ConfirmDecision(
    allowed: false,
    flow: ConfirmFlow.notAllowed,
  );
}
