import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

class AppDarkColors extends ThemeKolors {
  @override
  Brightness get themeMode => Brightness.dark;

  @override
  Color get background => Kolors.stone950; // Very dark gray with subtle blue

  @override
  Color get cardBackground => Kolors.stone900; // Matches modern dark surfaces

  @override
  Color get dividerColor => Kolors.gray800; // Clean, low-contrast lines

  @override
  Color get forground => Kolors.gray100; // Bright text

  @override
  Color get inputBackground => Kolors.gray900; // Matches card

  @override
  Color get outlineColor => Kolors.gray700; // Less intrusive borders

  @override
  Color get primaryColor => Kolors.indigo400; // Softer Indigo for elegance

  @override
  Color get secondaryButton => Kolors.gray800; // Button blends with card

  @override
  Color get secondaryContent => Kolors.gray400; // Subdued text/icons

  @override
  Color get shadowColor => Kolors.neutral100;
}
