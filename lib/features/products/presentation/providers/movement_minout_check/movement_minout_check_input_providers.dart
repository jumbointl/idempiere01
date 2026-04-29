import 'package:flutter_riverpod/legacy.dart';

/// DocumentNo typed manually, scanned, or seeded from a deep link / URL
/// launcher. Bound to the read-only TextField in the screen header so
/// scan, manual dialog and URL launcher all converge on the same source.
final docNoInputProvider = StateProvider<String>((ref) => '');
