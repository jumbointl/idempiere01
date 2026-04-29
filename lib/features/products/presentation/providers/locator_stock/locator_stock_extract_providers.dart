import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/locator_ip_line.dart';
import '../../../domain/idempiere/locator_product_stock.dart';
import 'find_ip_lines.dart';

/// Date range used by the "Extract IP lines" button.
/// Defaults to [today - 15 days, today].
final dateFromProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  final base = now.subtract(const Duration(days: 15));
  return DateTime(base.year, base.month, base.day);
});

final dateToProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 23, 59, 59);
});

/// Per-product cache of extracted IP lines (keyed by `M_Product_ID`).
/// `null` entry = not extracted yet for current session.
final ipLinesByProductProvider =
    StateProvider<Map<int, List<LocatorIpLine>>>((ref) => <int, List<LocatorIpLine>>{});

class ExtractIpLinesArgs {
  ExtractIpLinesArgs({
    required this.locator,
    required this.productStock,
  });

  final IdempiereLocator locator;
  final LocatorProductStock productStock;
}

/// Run the IP extraction for one (locator, product). Stores result in
/// [ipLinesByProductProvider] and updates `productStock.totalInProgress`.
Future<List<LocatorIpLine>> extractIpLinesForProduct(
  WidgetRef ref,
  ExtractIpLinesArgs args,
) async {
  final dateFrom = ref.read(dateFromProvider);
  final dateTo = ref.read(dateToProvider);

  final lines = await findIpLinesForLocatorProduct(
    locator: args.locator,
    product: args.productStock.product,
    dateFrom: dateFrom,
    dateTo: dateTo,
  );

  final total = lines.fold<double>(0, (acc, l) => acc + l.qty);
  args.productStock.totalInProgress = total;

  final productId = args.productStock.product.id;
  if (productId != null) {
    final current = ref.read(ipLinesByProductProvider);
    ref.read(ipLinesByProductProvider.notifier).state = <int, List<LocatorIpLine>>{
      ...current,
      productId: lines,
    };
  }

  return lines;
}
