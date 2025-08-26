import 'package:flutter/material.dart';

class TransactionModel {
  final IconData icon;
  final Color backgroundColor;
  final String name;
  final bool income;
  final double amount;
  final String time;

  TransactionModel({
    required this.icon,
    required this.backgroundColor,
    required this.name,
    required this.income,
    required this.amount,
    required this.time,
  });
}
