import 'idempiere_product.dart';

enum LocatorIpLineSource { mov, minout }

/// Single line of an in-progress (`DocStatus = 'IP'`) document that affects a
/// given (locator, product) pair. Consolidates `m_movementline` and
/// `m_inoutline` results for display in the BottomSheet.
class LocatorIpLine {
  LocatorIpLine({
    required this.source,
    required this.documentNo,
    required this.movementDate,
    required this.qty,
    this.product,
    this.description,
    this.lineNo,
  });

  final LocatorIpLineSource source;
  final String documentNo;
  final DateTime? movementDate;
  final double qty;
  final IdempiereProduct? product;
  final String? description;
  final int? lineNo;

  String get sourceTag =>
      source == LocatorIpLineSource.mov ? 'MOV' : 'MINOUT';
}
