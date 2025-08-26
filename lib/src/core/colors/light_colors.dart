import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

class AppLightColors extends ThemeKolors {
  @override
  Brightness get themeMode => Brightness.light;

  @override
  Color get background => Kolors.gray50; // Clean, modern background

  @override
  Color get cardBackground => Kolors.gray100; // Clear contrast from background

  @override
  Color get dividerColor => Kolors.gray200; // Light dividers

  @override
  Color get forground => Kolors.gray900; // Primary text color

  @override
  Color get inputBackground => Kolors.gray200; // Matches background

  @override
  Color get outlineColor => Kolors.gray300; // Clean outlines

  @override
  Color get primaryColor => Kolors.indigo500; // Slightly deeper Indigo

  @override
  Color get secondaryButton => Kolors.gray100; // Light, subtle

  @override
  Color get secondaryContent => Kolors.gray600; // Description text, icons

  @override
  Color get shadowColor => Kolors.neutral100; // Light shadow
}
