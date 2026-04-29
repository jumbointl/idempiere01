import 'package:flutter_riverpod/legacy.dart';

/// Locator value typed manually, scanned, or seeded from a deep link /
/// URL launcher. Bound to the read-only TextField in the screen header.
final locatorValueInputProvider = StateProvider<String>((ref) => '');

/// Optional `M_Product_ID` filter typed manually or seeded from a deep
/// link / URL launcher. When not null, the search appends
/// `AND M_Product_ID eq <id>` to the `m_storageonhand` filter.
final productIdInputProvider = StateProvider<int?>((ref) => null);
