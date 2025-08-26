// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

import 'package:monalisa_app_001/src/components/pin_keyboard.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/pages/contact_page/contact_page.dart';
import 'package:monalisa_app_001/src/pages/select_card/select_card.dart';
import 'package:monalisa_app_001/src/widgets/global_layout.dart';
import 'package:monalisa_app_001/src/widgets/display_amount.dart';

class SelectAmount extends StatefulWidget {
  static const String route = '/select_amount';
  const SelectAmount({super.key});

  @override
  State<SelectAmount> createState() => _SelectAmountState();
}

class _SelectAmountState extends State<SelectAmount> {
  String amount = '0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: GlobalPageLayout(
        headerPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        header: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            24.s,
            DefaultLayoutHeader(title: 'Sent Amount'),
            24.s,
            MoneyDisplay(
              amount: double.tryParse(amount) ?? 0.0,
              color: context.titleInverse, // More consistent than raw black
            ),
          ],
        ),
        contentHeight: 0.62,
        footer: _buildFooter(context),
      ),
    );
  }

  Container _buildFooter(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: kPadding.p,
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 30.r,
                backgroundImage: AssetImage(AssetImages.person1),
              ),
              title: Hero(tag: 'avatar_1', child: Text('Emery Dokidis')),
              subtitle: Text('+880 1567 56585', style: context.bodySmall),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(5000.toDollar(), style: context.bodyMedium.bold),
                  SizedBox(height: 3.h),
                  Text(
                    '2nd May 2020',
                    style: context.bodySmall.k(context.secondaryContent),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.w),
              child: PinKeyboard(
                backgroundColor: context.background,
                keyFontSize: 32.sp,
                swapPosition: true,
                keyShape: KeyShape.rectangle,
                onDigitPressed: (String x) {
                  setState(() {
                    amount = amount == '0' ? x : amount + x;
                  });
                },
                onDeletePressed: () {
                  setState(() {
                    if (amount.length > 1) {
                      amount = amount.substring(0, amount.length - 1);
                    } else {
                      amount = '0';
                    }
                  });
                },
                onDonePressed: () {
                  Future.microtask(() {
                    if (context.mounted) {
                      context.pushName(
                        SelectCard.route,
                      ); // Replace with your route
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
