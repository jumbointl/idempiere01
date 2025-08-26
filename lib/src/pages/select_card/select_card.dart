import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/pages/credit_cards/card_swipe.dart';
import 'package:monalisa_app_001/src/pages/select_card/widget/sent_money_success.dart';
import 'package:monalisa_app_001/src/widgets/global_layout.dart';
import 'package:monalisa_app_001/src/widgets/display_amount.dart';

import '../contact_page/contact_page.dart';

class SelectCard extends StatelessWidget {
  static const String route = '/select_card';
  const SelectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlobalPageLayout(
        headerPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        header: DefaultLayoutHeader(title: 'Select Card'),
        footer: CardContent(),
        contentHeight: .75.h,
      ),
    );
  }
}

class CardContent extends StatelessWidget {
  const CardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kPadding.p,
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Consider enabling this for subtle depth:
          // BoxShadow(
          //   color: context.shadow.withValues(alpha:0.08),
          //   blurRadius: 12,
          //   offset: Offset(0, 4),
          // ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amount Section
          Text('Amount', style: context.bodySmall.k(context.titleColor)),
          5.s,
          MoneyDisplay(amount: 64678, color: context.primaryColor),

          12.s,
          const Divider(height: 1),

          // Recipient
          12.s,
          Text('To', style: context.bodySmall.k(context.titleColor)),
          10.s,
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(AssetImages.person2),
            ),
            title: Text(
              'John Doe',
              style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'john.doe@example.com',
              style: context.bodySmall.copyWith(color: context.subtitleColor),
            ),
          ),

          // Sender
          12.s,
          Text('From', style: context.bodySmall.k(context.titleColor)),
          10.s,
          CardSwipe(),

          // CTA Button
          50.s,
          PrimaryButton(
            label: 'Continue',
            onPressed: () {
              showSentMoneySuccessDialog(context);
            },
          ),
        ],
      ),
    );
  }
}
