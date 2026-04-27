import 'package:flutter/material.dart';

/// Five light colors used to identify MInOut sessions in the Multiple Receipt
/// flow. Index rotates: 0,1,2,3,4,0,1,...
const List<Color> _multiReceiptPalette = <Color>[
  Color(0xFFE3F2FD), // light blue
  Color(0xFFE8F5E9), // light green
  Color(0xFFFFF3E0), // light orange
  Color(0xFFF3E5F5), // light purple
  Color(0xFFFCE4EC), // light pink
];

const List<Color> _multiReceiptPaletteAccent = <Color>[
  Color(0xFF1976D2),
  Color(0xFF388E3C),
  Color(0xFFF57C00),
  Color(0xFF7B1FA2),
  Color(0xFFC2185B),
];

Color colorForSessionIndex(int index) =>
    _multiReceiptPalette[index % _multiReceiptPalette.length];

Color accentForSessionIndex(int index) =>
    _multiReceiptPaletteAccent[index % _multiReceiptPaletteAccent.length];

String labelForSessionIndex(int index) =>
    '${(index % _multiReceiptPalette.length) + 1}';
