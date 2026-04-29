import 'idempiere_locator.dart';
import 'idempiere_product.dart';

/// Source document type for [MovementMInOutCheckScreen].
enum MovementMInOutCheckSource { movement, minout }

extension MovementMInOutCheckSourceX on MovementMInOutCheckSource {
  String get label =>
      this == MovementMInOutCheckSource.movement ? 'Movement' : 'MInOut';
}

/// Per-line "stock check" status for a single product inside a locator.
enum LocatorCheckLineStatus {
  /// Stock available >= required.
  ok,

  /// Some stock but not enough (`0 < available < required`).
  partial,

  /// No stock — either no row in `m_storageonhand` or `QtyOnHand == 0`.
  missing,
}

/// One line of the source document (movement / minout) that we want to fulfil.
class MovementMInOutCheckLine {
  MovementMInOutCheckLine({
    required this.product,
    required this.locator,
    required this.qtyToMove,
    this.lineNo,
    this.documentLineId,
  });

  final IdempiereProduct product;
  final IdempiereLocator? locator;
  final double qtyToMove;
  final int? lineNo;
  final int? documentLineId;
}

/// All [MovementMInOutCheckLine]s assigned to the same `M_Locator_ID`.
///
/// The group also caches the total stock available per product (sum of
/// `QtyOnHand` from `m_storageonhand`) so the UI can compare required vs
/// available cheaply.
class MovementMInOutCheckLocatorGroup {
  MovementMInOutCheckLocatorGroup({
    required this.locator,
    required this.linesAssigned,
    required this.totalRequiredByProduct,
    required this.totalAvailableByProduct,
  });

  final IdempiereLocator locator;
  final List<MovementMInOutCheckLine> linesAssigned;

  /// Sum of `qtyToMove` per `M_Product_ID` across [linesAssigned].
  final Map<int, double> totalRequiredByProduct;

  /// Sum of `QtyOnHand` per `M_Product_ID` from `m_storageonhand` of this
  /// locator. Products without a row default to `0`.
  final Map<int, double> totalAvailableByProduct;

  /// Distinct products assigned to this locator.
  int get countAssigned => totalRequiredByProduct.length;

  /// Distinct products whose stock is below the required qty.
  int get countMissing {
    int n = 0;
    for (final entry in totalRequiredByProduct.entries) {
      final avail = totalAvailableByProduct[entry.key] ?? 0;
      if (avail < entry.value) n++;
    }
    return n;
  }

  bool get allOk => countMissing == 0;

  LocatorCheckLineStatus statusForProduct(int productId, double required) {
    final avail = totalAvailableByProduct[productId] ?? 0;
    if (avail <= 0) return LocatorCheckLineStatus.missing;
    if (avail >= required) return LocatorCheckLineStatus.ok;
    return LocatorCheckLineStatus.partial;
  }
}

/// Result payload for a "scan DocumentNo -> check stock per locator" run.
class MovementMInOutCheckPayload {
  MovementMInOutCheckPayload({
    required this.source,
    required this.documentNo,
    required this.headerId,
    required this.locatorGroups,
    required this.linesWithoutLocator,
  });

  final MovementMInOutCheckSource source;
  final String documentNo;
  final int headerId;
  final List<MovementMInOutCheckLocatorGroup> locatorGroups;

  /// Document lines with no `M_Locator_ID` set — surfaced separately so the
  /// user can still see them.
  final List<MovementMInOutCheckLine> linesWithoutLocator;
}
