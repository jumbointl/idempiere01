import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:intl/intl.dart';

class MoneyDisplay extends StatelessWidget {
  final double amount;
  final Color? color;
  const MoneyDisplay({super.key, required this.amount, this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            NumberFormat("#,###").format(amount), // Formats as 5,000,000
            style: context.displayLarge.bold.k(color ?? context.titleColor),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Text(
            '\$',
            style: context.bodyMedium.k(color ?? context.titleColor),
          ),
        ),
      ],
    );
  }
}
