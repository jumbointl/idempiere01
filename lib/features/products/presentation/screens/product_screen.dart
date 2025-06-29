import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/messages.dart';
import '../providers/product_screen_provider.dart';
import '../widget/no_data_card.dart';
import '../widget/product_detail_card.dart';
import '../widget/scan_product_barcode_button.dart';
import '../widget/storage_on__hand_card.dart';


class ProductScreen extends ConsumerWidget {
  int count =0;
  ProductScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(futureProvider);
    final productsStoredAsync = ref.watch(futureProductsStoredProvider);
    final productsNotifier = ref.watch(scanStateNotifierProvider.notifier);
    final double width = MediaQuery.of(context).size.width -30;
    return Scaffold(

      appBar: AppBar(
        title: Text(Messages.PRODUCT),
        bottom: PreferredSize(
          preferredSize: Size(MediaQuery.of(context).size.width,40),
          child: SizedBox(width: width, child: ScanProductBarcodeButton(productsNotifier))),

      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [

            Container(
              width: MediaQuery.of(context).size.width - 30,
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: productAsync.when(
                data: (product) => (product.id != null && product.id! > 0) ? ProductDetailCard(product) : const NoDataCard(),
                error: (error, stackTrace) => Text('Error: $error'),
                loading: () => const LinearProgressIndicator(backgroundColor: Colors.cyan,
                  color: Colors.purple, minHeight: 20,),
              ),
            ),
            Expanded(
                child: productsStoredAsync.when(
              data: (storages) => ListView.builder(
                itemCount: storages.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final product = storages[index];
                  return StorageOnHandCard(product, index+1, storages.length,width: width-10);
                },
              ),
              error: (error, stackTrace) => Text('Error: $error'),
              loading: () => const LinearProgressIndicator(),
            ))

          ],
        ),
      ),

    );
  }
}