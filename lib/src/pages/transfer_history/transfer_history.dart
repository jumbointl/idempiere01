import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/widgets/card_header_section.dart';
import 'package:monalisa_app_001/src/pages/transfer_history/recent_transactions.dart';

class TransferHistory extends StatelessWidget {
  static const String route = '/history';
  const TransferHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildNewAppBar(
        context,
        child: CustomAppBar(title: 'TransAction History'),
      ),
      body: SafeArea(
        child: Column(
          spacing: 32.h,
          children: [
            Padding(
              padding: kPadding.px,
              child: Column(
                spacing: 32.h,
                children: [
                  CardHeaderSection(
                    title: 'Jan 25 - May 30',
                    subtitle: '2025',
                    trailing: Text('5 Months').onTap(() {}),
                  ),
                  //AppSearchBar(),
                ],
              ),
            ),

            RecentTransaction(radius: 0,width: double.infinity,),
          ],
        ).scrollable(),
      ),
    );
  }
}
