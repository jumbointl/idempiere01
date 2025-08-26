// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';

import 'package:monalisa_app_001/src/core/resource/app_resources.dart';

class VirtualCard extends StatelessWidget {
  final Color bgColor;
  final num amount;
  final String name;
  final String expiry;
  const VirtualCard({
    super.key,
    required this.bgColor,
    required this.amount,
    required this.name,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          image: DecorationImage(
            image: Svg(AssetSvgs.splashBGLight),
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.shadow.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
          border: Border.all(
            color: context.outline.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top row: brand & card type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(AssetImages.monalisa_app_001Card, height: 24.h),
                Image(image: Svg(AssetSvgs.cardType), height: 24.h),
              ],
            ),

            const Spacer(),

            /// Name & balance
            Text(
              name,
              style: context.bodyMedium.bold
                  .k(context.titleInverse)
                  .copyWith(letterSpacing: 0.6),
            ),
            6.s,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image(image: Svg(AssetSvgs.flatChip), height: 36.h),
                12.s,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance',
                      style: context.labelSmall.k(context.titleInverse),
                    ),
                    2.s,
                    Text(
                      amount.toDollar(),
                      style: context.titleLarge.k(
                        context.primaryColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            /// Bottom row: expiry
            Text(
              'Valid Thru: $expiry',
              style: context.bodySmall.k(
                context.titleInverse.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
