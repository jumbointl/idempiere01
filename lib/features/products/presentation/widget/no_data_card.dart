import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_product.dart';
import '../providers/product_screen_provider.dart';
class NoDataCard extends ConsumerStatefulWidget {

  const NoDataCard({super.key});


  @override
  ConsumerState<NoDataCard> createState() => ProductDetailCardState();
}

class ProductDetailCardState extends ConsumerState<NoDataCard> {

  @override
  Widget build(BuildContext context) {
    int count = ref.watch(scannedCodeTimesProvider.notifier).state;
    Color color = (count.isEven) ? themeColorWarningLight : themeColorWarning;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: IconButton(onPressed: ()=>{}, icon: Image.asset('assets/images/not-found.png')),
    );
  }
}