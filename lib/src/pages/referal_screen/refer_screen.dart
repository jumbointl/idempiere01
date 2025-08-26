import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/components/appbar_builder.dart';
import 'package:monalisa_app_001/src/components/primary_button.dart';
import 'package:monalisa_app_001/src/core/utility/snack_bar.dart';

class ReferralScreen extends ConsumerWidget {
  static const String route = '/referral';

  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: buildNewAppBar(context, child: const CustomAppBar()),
      body: Padding(
        padding: 16.px,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  20.s,
                  _buildHeader(context),
                  30.s,
                  _buildReferralCodeSection(context),
                  // _buildInviteSection(context),
                  const Spacer(),
                  _buildShareButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(TablerIcons.trophy, size: 64, color: context.primaryColor),
        16.s,
        Text('Refer and Earn', style: context.titleMedium),
        8.s,
        Text(
          'Invite your friends and earn rewards when they join and transact.',
          style: context.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReferralCodeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Referral Code', style: context.bodyLarge.bold),
        12.s,
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SWIFT123', style: context.titleSmall),
              IconButton(
                onPressed: () {
                  context.showSnackBar('Copied to clipboard');
                },
                icon: Icon(Icons.copy, color: context.primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildShareButton(BuildContext context) {
    return Column(
      children: [
        PrimaryButton(
          label: 'Invite Now',
          color: context.primaryColor,
          textColor: context.titleInverse,
          onPressed: () {
            context.showSnackBar('Invitation sent');
          },
        ),
        16.s,
        PrimaryButton(
          label: 'Share via Apps',
          dataIcon: TablerIcons.share_3,
          color: context.secondaryButton,
          textColor: context.primaryColor,
          borderColor: context.outline,
          iconColor: context.primaryColor,
          onPressed: () {
            context.showSnackBar('Sharing options opened');
          },
        ),
        30.s,
      ],
    );
  }
}
