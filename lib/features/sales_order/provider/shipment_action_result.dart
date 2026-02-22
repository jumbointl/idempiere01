class ShipmentActionItemResult {
  final String orderId;
  final bool success;
  final String? summary;
  final String? error;

  const ShipmentActionItemResult({
    required this.orderId,
    required this.success,
    this.summary,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'success': success,
    'summary': summary,
    'error': error,
  };
}
