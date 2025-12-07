import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class InputDataProcessor {
  Future<void> handleInputString({required WidgetRef ref, required String inputData,
    required int actionScan});
  void addQuantityText(BuildContext context, WidgetRef ref, TextEditingController quantityController, int i);
}