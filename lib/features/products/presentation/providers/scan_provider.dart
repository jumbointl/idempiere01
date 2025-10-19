import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

final scanTextControllerProvider = StateProvider<TextEditingController>((ref) {
  return TextEditingController();
});