import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/pages/add_credit_card/add_new_card.dart';
import 'package:monalisa_app_001/src/pages/credit_cards/card_swipe.dart';
import 'package:monalisa_app_001/src/widgets/card_header_section.dart';
import 'package:monalisa_app_001/src/widgets/section_divider.dart';

import '../../widgets/half_circle.dart';
import '../transfer_history/recent_transactions.dart';

class CardsView extends StatelessWidget {
  const CardsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNewAppBar(context, child: _addCardhead(context)),
      body: ListView(
        children: [
          /// Credit Card Swiper
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: const CardSwipe(),
          ),

          const SectionDivider(),

          /// Budget Section
          _buildYourBudget(context),

          const SectionDivider(),

          /// Recent Transactions
          const RecentTransaction(width: double.infinity,),
        ],
      ),
    );
  }

  Widget _buildYourBudget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeaderSection(
            title: 'Your Budget',
            subtitle: 'for airpay card',
            trailing: Text(
              'Add Budget',
              style: context.bodyLarge.bold.k(context.primaryColor),
            ),
          ),
          16.s,
          Center(
            child: HalfCircleProgress(
              radius: 152,
              progress: 0.62,
              label: "\$42 / \$100",
              progressColor: context.primaryColor,
              backgroundColor: context.outline,
              widget: Container(
                margin: 32.mt,
                child: Column(
                  children: [
                    Icon(
                      TablerIcons.credit_card,
                      color: context.primaryColor,
                      size: 28.sp,
                    ),
                    10.s,
                    Text('You Spent', style: context.bodySmall.thin),
                    Text(7900.50.toDollar(), style: context.titleMedium.bold),
                    Text('of \$ 8,000.80', style: context.bodySmall.thin),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ListTile _addCardhead(BuildContext context) {
    return ListTile(
      contentPadding: customPad,
      leading: Text('Your Credit Cards', style: context.titleSmall.bold),
      title: Row(
        spacing: 5,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => AddCardScreen().launch(context),
            child: IconButton(
              icon: Icon(Icons.search, size: 24.sp),
              color: context.primaryColor,
              style: IconButton.styleFrom(
                backgroundColor: context.primaryColor.withValues(alpha: .15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: context.primaryColor, width: 1),
                ),
              ),
              onPressed: () => AddCardScreen().launch(context),
            ),
          ),
          GestureDetector(
            onTap: () => AddCardScreen().launch(context),
            child: IconButton(
              icon: Icon(Icons.add, size: 24.sp),
              color: context.primaryColor,
              style: IconButton.styleFrom(
                backgroundColor: context.primaryColor.withValues(alpha: .15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: context.primaryColor, width: 1),
                ),
              ),
              onPressed: () => AddCardScreen().launch(context),
            ),
          ),
          GestureDetector(
            onTap: () => AddCardScreen().launch(context),
            child: IconButton(
              icon: Icon(Icons.history, size: 24.sp),
              color: context.primaryColor,
              style: IconButton.styleFrom(
                backgroundColor: context.primaryColor.withValues(alpha: .15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: context.primaryColor, width: 1),
                ),
              ),
              onPressed: () => AddCardScreen().launch(context),
            ),
          ),
        ],
      ),
      /*trailing: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => AddCardScreen().launch(context),
          child: Container(
            margin: 2.m,
            child: BorderBox(
              color: context.primaryColor,
              borderRadius: 8,
              dashWidth: 4,
              dashSpace: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: 8.p,
                child: Icon(Icons.qr_code_scanner, size: 14.sp),
              ),
            ),
          ),
        ),
      ),*/
    );
  }
}
