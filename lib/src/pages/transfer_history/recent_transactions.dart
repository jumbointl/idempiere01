// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

import 'package:monalisa_app_001/src/core/constants/app_constants.dart';
import 'package:monalisa_app_001/src/data/samples/transaction_sample.dart';

class RecentTransaction extends StatelessWidget {
  final double radius;
  final double width;
  const RecentTransaction({super.key, this.radius = 16, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: kPadding.p,
      decoration: BoxDecoration(
        color: context.cardBackground.withValues(alpha: .85),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(children: [_buildTitle(context), const _TransactionList()]),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Recent Transactions', style: context.titleSmall.bold),
        TextButton(
          onPressed: () {
            // TODO: Navigate to full list
          },
          style: TextButton.styleFrom(
            backgroundColor: context.primaryColor.withValues(alpha: 0.3),
            foregroundColor: context.primaryColor.withValues(alpha: 0.8),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(40, 20), // Defines a small button size
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: context.labelSmall.bold,
          ),
          child: const Text('See All'),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: transactions.map((tx) {
        final isIncome = tx.income;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: tx.backgroundColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(tx.icon, color: tx.backgroundColor, size: 22.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.name, style: context.bodyMedium.bold),
                    SizedBox(height: 4.h),
                    Text(
                      tx.time,
                      style: context.bodySmall.copyWith(
                        color: context.secondaryContent,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${tx.amount.toDollar()}',
                    style: context.bodyLarge.copyWith(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: (isIncome ? Colors.green : Colors.red).withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      isIncome ? 'Income' : 'Expense',
                      style: context.bodySmall.copyWith(
                        color: isIncome ? Colors.green : Colors.red,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
