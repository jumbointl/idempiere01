// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';

class ActionMenu extends StatelessWidget {
  const ActionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionIcon(
            icon: AssetSvgs.sentMoney,
            label: 'Transfer',
            onTap: () {
              Future.microtask(() {
                if (context.mounted) context.pushName(ContactPage.route);
              });
            },
          ),
          _ActionIcon(
            icon: AssetSvgs.receiveMoney,
            label: 'Receive',
            onTap: () => context.pushName(ReceivePage.route),
          ),
          _ActionIcon(
            icon: AssetSvgs.walletPlus,
            label: 'Withdraw',
            onTap: () => context.pushName(QrScannerScreen.route),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionIcon({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: context.primaryColor.withValues(alpha: .13),
          shape: const CircleBorder(),
          elevation: 0.3,
          shadowColor: context.shadow.withValues(alpha: 0.04),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: context.primaryColor.withValues(alpha: 0.15),
            child: SizedBox(
              height: 52,
              width: 52,
              child: Center(
                child: SvgPicture.asset(icon, height: 32, width: 32),
              ),
            ),
          ),
        ),
        6.s,
        Text(label, style: context.bodyMedium.bold),
      ],
    );
  }
}
