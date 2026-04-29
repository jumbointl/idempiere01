import 'idempiere_locator.dart';
import 'locator_product_stock.dart';

/// Result payload for the "scan locator value -> list its product stocks" flow.
class LocatorWithProductStocks {
  LocatorWithProductStocks({
    required this.locator,
    required this.products,
  });

  final IdempiereLocator locator;
  final List<LocatorProductStock> products;
}
