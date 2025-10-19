import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class InputDataProcessor {
  Future<void> handleInputString(BuildContext context, WidgetRef ref, String inputData);
  void addQuantityText(BuildContext context, WidgetRef ref, TextEditingController quantityController, int i);
}