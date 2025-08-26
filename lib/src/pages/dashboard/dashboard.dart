// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/widgets/dash_board_head.dart';

import 'package:monalisa_app_001/src/widgets/quick_action.dart';
import 'package:monalisa_app_001/src/pages/credit_cards/card_swipe.dart';
import 'package:monalisa_app_001/src/pages/transfer_history/recent_transactions.dart';
import 'package:monalisa_app_001/src/widgets/section_divider.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNewAppBar(
        height: 70.h,
        context,
        child: const DashboardHeader(),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: 16.s), // Top spacing
            /// Swipable Cards Section
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: const SliverToBoxAdapter(child: CardSwipe()),
            ),

            const SliverToBoxAdapter(child: SectionDivider()),

            /// Action Menu (Send, Receive, etc.)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              sliver: const SliverToBoxAdapter(child: ActionMenu()),
            ),

            const SliverToBoxAdapter(child: SectionDivider()),

            /// Recent Transactions
            const SliverToBoxAdapter(child: RecentTransaction(width: double.infinity,)),
          ],
        ),
      ),
    );
  }
}
