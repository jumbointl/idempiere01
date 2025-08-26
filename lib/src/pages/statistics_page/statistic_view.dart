import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/components/custom_safe.dart';
import 'package:monalisa_app_001/src/widgets/card_header_section.dart';
import 'package:monalisa_app_001/src/widgets/line_chart.dart';
import 'package:monalisa_app_001/src/widgets/section_divider.dart';

import '../transfer_history/recent_transactions.dart';
import 'wallet_info.dart';

class StatisticView extends StatelessWidget {
  const StatisticView({super.key});

  @override
  Widget build(BuildContext context) {
    return SaferGurd(
      child: Scaffold(
        body: ListView(
          children: [
            /// Header + Bar Chart
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardHeaderSection(
                    title: 'Jan 25 - May 30',
                    subtitle: '2025',
                    trailing: Text('5 Months').onTap(() {}),
                  ),
                  16.s,
                  const BarChartSample(),
                ],
              ),
            ),

            const SectionDivider(),

            /// Quick Actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: const QuickAction(),
            ),

            const SectionDivider(),

            /// Recent Transactions
            const RecentTransaction(width: double.infinity,),
          ],
        ),
      ),
    );
  }
}
