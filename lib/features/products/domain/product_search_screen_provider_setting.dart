import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../presentation/providers/products_scan_notifier.dart';

abstract class ProductSearchScreenProviderSetting {
  void setProvidersAndConfigureParameters(BuildContext context,WidgetRef ref);
  Widget getProductDetailCard({required ProductsScanNotifier productsNotifier, required product});
}