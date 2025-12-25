// =======================
// app_theme.dart
// =======================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// const themeColorPrimary = Color.fromRGBO(25, 35, 70, 1);
const themeColorPrimary = Color.fromRGBO(31, 44, 80, 1);
const themeColorPrimaryLight = Color.fromRGBO(140, 150, 255, 1);
const themeColorPrimaryLight2 = Color.fromRGBO(173, 180, 246, 1.0);
Color themeColorPrimaryGreen800 = Colors.green[800]!;
Color themeColorPrimaryBlue800 = Colors.blue[800]!;
const themeColorPrimaryDark = Color.fromRGBO(13, 13, 16, 1.0);

const themeBackgroundColor = Colors.white;
const themeBackgroundColorLight = Color.fromRGBO(245, 245, 245, 1);

const themeColorSuccessful = Color.fromRGBO(70, 170, 70, 1);
const themeColorSuccessfulLight = Color.fromRGBO(140, 220, 140, 1);
const themeColorWarning = Color.fromRGBO(255, 200, 50, 1);
const themeColorWarningLight = Color.fromRGBO(255, 255, 140, 1);
const themeColorError = Color.fromRGBO(255, 50, 50, 1);
const themeColorErrorLight = Color.fromRGBO(255, 178, 178, 1);
const themeColorGray = Color.fromRGBO(100, 100, 100, 1);
const themeColorGrayLight = Color.fromRGBO(200, 200, 180, 1);

const double themeFontSizeLarge = 16;
const double themeFontSizeNormal = 14;
const double themeFontSizeSmall = 12;
const double themeFontSizeTitle = 22;

const double themeBorderRadius = 20;

class AppTheme {
  ThemeData getTheme() {
    // Base M3 color scheme from your seed
    final scheme = ColorScheme.fromSeed(
      seedColor: themeColorPrimary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,

      // M3
      colorScheme: scheme,
      scaffoldBackgroundColor: themeBackgroundColor,

      // Texts
      textTheme: TextTheme(
        titleLarge: GoogleFonts.roboto().copyWith(
          fontSize: 35,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
        titleMedium: GoogleFonts.roboto().copyWith(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
        titleSmall: GoogleFonts.roboto().copyWith(
          fontSize: themeFontSizeNormal,
          color: scheme.onSurface,
        ),
        bodyMedium: GoogleFonts.roboto().copyWith(
          fontSize: themeFontSizeNormal,
          color: scheme.onSurface,
        ),
        bodySmall: GoogleFonts.roboto().copyWith(
          fontSize: themeFontSizeSmall,
          color: scheme.onSurfaceVariant,
        ),
      ),

      // AppBar (M3)
      appBarTheme: AppBarTheme(
        backgroundColor: themeBackgroundColor,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto().copyWith(
          fontSize: themeFontSizeTitle,
          fontWeight: FontWeight.bold,
          color: themeColorPrimary,
        ),
      ),

      // FilledButton (M3)
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.primary),
          foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.roboto().copyWith(fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(themeBorderRadius),
            ),
          ),
        ),
      ),

      // OutlinedButton (nice with your design)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(Colors.purple),
          textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 16)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),

      // TextButton (affects DateRangePicker Save/Cancel in M3)
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(Colors.purple),
          textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 16)),
        ),
      ),

      // Date picker theme (M3) -> fixes Save button + selected date text
      datePickerTheme: DatePickerThemeData(
        headerHeadlineStyle: const TextStyle(fontSize: 16, color: Colors.purple),
        headerHelpStyle: const TextStyle(fontSize: 16, color: Colors.purple),

        // Day number text size
        dayStyle: const TextStyle(fontSize: 16),

        // Selected day circle colors
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.purple;
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return null;
        }),

        // Range selection highlight
        rangeSelectionBackgroundColor: Colors.purple.withOpacity(0.15),
        rangeSelectionOverlayColor:
        WidgetStatePropertyAll(Colors.purple.withOpacity(0.10)),

        // Buttons Save/Cancel (some M3 builds use these)
        confirmButtonStyle: const ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(Colors.purple),
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 16)),
        ),
        cancelButtonStyle: const ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(Colors.purple),
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}



/*
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// const themeColorPrimary = Color.fromRGBO(25, 35, 70, 1);
const themeColorPrimary = Color.fromRGBO(31, 44, 80, 1);
const themeColorPrimaryLight = Color.fromRGBO(140, 150, 255, 1);
const themeColorPrimaryLight2 = Color.fromRGBO(173, 180, 246, 1.0);
Color themeColorPrimaryGreen800 =  Colors.green[800]!;
Color themeColorPrimaryBlue800 =  Colors.blue[800]!;
const themeColorPrimaryDark = Color.fromRGBO(13, 13, 16, 1.0);

const themeBackgroundColor = Colors.white;
const themeBackgroundColorLight = Color.fromRGBO(245, 245, 245, 1);

const themeColorSuccessful = Color.fromRGBO(70, 170, 70, 1);
const themeColorSuccessfulLight = Color.fromRGBO(140, 220, 140, 1);
const themeColorWarning = Color.fromRGBO(255, 200, 50, 1);
const themeColorWarningLight = Color.fromRGBO(255, 255, 140, 1);
const themeColorError = Color.fromRGBO(255, 50, 50, 1);
const themeColorErrorLight = Color.fromRGBO(255, 178, 178, 1);
const themeColorGray = Color.fromRGBO(100, 100, 100, 1);
const themeColorGrayLight = Color.fromRGBO(200, 200, 180, 1);

const double themeFontSizeLarge = 16;
const double themeFontSizeNormal = 14;
const double themeFontSizeSmall = 12;
const double themeFontSizeTitle = 22;

const double themeBorderRadius = 20;

class AppTheme {
  ThemeData getTheme() => ThemeData(

      /// General
      // useMaterial3: true,
      colorSchemeSeed: themeColorPrimary,

      /// Texts
      textTheme: TextTheme(
          titleLarge: GoogleFonts.roboto()
              .copyWith(fontSize: 35, fontWeight: FontWeight.bold),
          titleMedium: GoogleFonts.roboto()
              .copyWith(fontSize: 25, fontWeight: FontWeight.bold),
          titleSmall: GoogleFonts.roboto().copyWith(fontSize: themeFontSizeNormal)),

      /// Scaffold Background Color
      scaffoldBackgroundColor: themeBackgroundColor,

      /// Buttons
      filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(themeColorPrimary),
              textStyle: WidgetStatePropertyAll(
                  GoogleFonts.roboto().copyWith(fontWeight: FontWeight.w700)))),

      /// AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: themeBackgroundColor,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto().copyWith(
            fontSize: themeFontSizeTitle, fontWeight: FontWeight.bold, color: themeColorPrimary),
      ));
}
*/
