import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class QuickAction extends StatelessWidget {
  const QuickAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        //color: context.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ListTileCard(
              icon: TablerIcons.wallet,
              money: 120.0,
              label: 'Wallet',
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _ListTileCard(
              icon: TablerIcons.pig_money,
              money: 340.0,
              label: 'Savings',
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTileCard extends StatelessWidget {
  final IconData icon;
  final double money;
  final String label;

  const _ListTileCard({
    required this.icon,
    required this.money,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.divider.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            height: 48.r,
            width: 48.r,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.primaryColor, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.bodySmall.copyWith(
                  color: context.secondaryContent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                money.toDollar(),
                style: context.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.titleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
