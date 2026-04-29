import 'idempiere_product.dart';
import 'idempiere_storage_on_hande.dart';

/// Single product entry inside a locator detail screen.
///
/// Aggregates one or more [IdempiereStorageOnHande] rows that share the same
/// `M_Product_ID` within the same `M_Locator_ID`. The list keeps the original
/// rows so we can show the breakdown by attribute-set instance if needed.
class LocatorProductStock {
  LocatorProductStock({
    required this.product,
    required this.totalShow,
    required this.rawLines,
    this.totalInProgress,
  });

  final IdempiereProduct product;

  /// Sum of `QtyOnHand` across [rawLines].
  final double totalShow;

  /// Raw `m_storageonhand` rows for this product in the current locator.
  final List<IdempiereStorageOnHande> rawLines;

  /// Sum of qty across MovementLines + MInOutLines in `IP` that affect this
  /// product/locator. Filled by the "Extraer" action; null until then.
  double? totalInProgress;

  /// Expected on-hand once IP movements are completed:
  /// `expected = totalShow - totalInProgress`.
  /// Returns null while [totalInProgress] is still unknown.
  double? get expected =>
      totalInProgress == null ? null : totalShow - totalInProgress!;
}
