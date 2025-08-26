import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

class AppFonts extends AppTypo {
  @override
  String get fontFamily => 'Poppins';

  // Body text styles
  @override
  TextStyle get bodyLarge => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  @override
  TextStyle get bodyMedium => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  @override
  TextStyle get bodySmall => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  // Display styles for hero content
  @override
  TextStyle get displayLarge => TextStyle(
    fontSize: 40.sp,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
  );

  @override
  TextStyle get displayMedium => TextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );

  // Labels (for buttons, tags, chips)
  @override
  TextStyle get labelLarge => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );

  @override
  TextStyle get labelMedium => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  @override
  TextStyle get labelSmall => TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  // Titles (for section headers, headlines)
  @override
  TextStyle get titleLarge => TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
  );

  @override
  TextStyle get titleMedium => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );

  @override
  TextStyle get titleSmall => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );
}

// inspired by design systems like Material 3, Apple Human Interface Guidelines, and Tailwind CSS typography scale:

// ✅ Guidelines Applied:
// bodySmall → 12

// bodyMedium → 14

// bodyLarge → 16

// labelSmall → 11

// labelMedium → 12

// labelLarge → 14

// titleSmall → 16

// titleMedium → 18

// titleLarge → 20–22

// displayMedium → 30

// displayLarge → 36–40
