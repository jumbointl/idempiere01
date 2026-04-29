import 'package:flutter_riverpod/legacy.dart';

/// Per-screen input provider for [ProductStoreOnHandScreen].
///
/// Mirrors the UPC/SKU code currently visible in the screen's read-only
/// TextField. Scan, manual dialog and URL launcher all converge on this
/// provider before firing the search.
final productCodeInputProvider = StateProvider<String>((ref) => '');
