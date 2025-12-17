// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';


import 'movement_confirm_screen_state.dart';

class MovementConfirmScreen extends ConsumerStatefulWidget {

  MovementAndLines movementAndLines;
  final String argument;
  double height = 300.0;
  double width = double.infinity;
  Color bgColor = themeColorPrimary;
  TextStyle movementStyle = const TextStyle(fontWeight: FontWeight.bold,color: Colors.white,
        fontSize: themeFontSizeLarge);
  MovementConfirmScreen({
    super.key,
    required this.movementAndLines,
    required this.argument,
  });

  @override
  ConsumerState<MovementConfirmScreen> createState() => MovementConfirmScreenState();
}


