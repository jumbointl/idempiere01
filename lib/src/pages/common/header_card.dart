// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';

import 'package:monalisa_app_001/src/core/resource/app_resources.dart';


class HeaderCard extends StatelessWidget {
  final Color bgColor;
  final num amount;
  final String titleLeft;
  final String titleRight;
  final String? subtitleLeft;
  final String? subtitleRight;
  final String expiry;
  final String id;
  double height = 160.0;
  double width = double.infinity;
  HeaderCard({
    super.key,
    required this.bgColor,
    required this.amount,
    required this.titleLeft,
    required this.expiry,
    required this.id,
    required this.titleRight,
    this.subtitleLeft,
    this.subtitleRight,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: height,
        width: width,
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
                Text(
                  id,
                  style: context.bodyMedium.bold
                      .k(context.titleInverse)
                      .copyWith(letterSpacing: 0.6),
                ),
                Text(
                  'Valid Thru: $expiry',
                  style: context.bodyMedium.bold.k(
                    context.titleInverse.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            //const Spacer(),

            6.s,
            /// Name & balance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titleLeft,
                  style: context.bodyMedium.bold
                      .k(context.titleInverse)
                      .copyWith(letterSpacing: 0.6),
                ),
                Text(
                  titleRight,
                  style: context.bodyMedium.bold
                      .k(context.titleInverse)
                      .copyWith(letterSpacing: 0.6),
                ),
              ],
            ),
            6.s,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitleLeft ?? '--',
                  style: context.bodyMedium.bold
                      .k(context.titleInverse)
                      .copyWith(letterSpacing: 0.6),
                ),
                Text(
                  subtitleRight ?? '--',
                  style: context.bodyMedium.bold
                      .k(context.titleInverse)
                      .copyWith(letterSpacing: 0.6),
                ),
              ],
            ),

            /*const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                        //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      ),
                      child: Text(Messages.LAST, style: context.bodySmall.bold.k(context.titleInverse)),
                    ),
                  ),
                  4.s,
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      ),
                      child: Text(Messages.NEW, style: context.bodySmall.bold.k(context.titleInverse)),
                    ),
                  ),
                  4.s,
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.amber,
                        //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      ),
                      child: Text(Messages.FIND, style: context.bodySmall.bold.k(context.titleInverse)),
                    ),
                  ),
                  4.s,
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green,
                        //padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      ),
                      child: Text(Messages.CONFIRM_SHORT, style: context.bodySmall.bold.k(context.titleInverse)),
                    ),
                  ),
                ],
              ),
          */
          ],
        ),
      ),
    );
  }
}
