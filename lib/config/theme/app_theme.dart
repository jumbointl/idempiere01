import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// const themeColorPrimary = Color.fromRGBO(25, 35, 70, 1);
const themeColorPrimary = Color.fromRGBO(31, 44, 80, 1);
const themeColorPrimaryLight = Color.fromRGBO(140, 150, 255, 1);
const themeColorPrimaryLight2 = Color.fromRGBO(173, 180, 246, 1.0);

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

      ///* General
      // useMaterial3: true,
      colorSchemeSeed: themeColorPrimary,

      ///* Texts
      textTheme: TextTheme(
          titleLarge: GoogleFonts.roboto()
              .copyWith(fontSize: 35, fontWeight: FontWeight.bold),
          titleMedium: GoogleFonts.roboto()
              .copyWith(fontSize: 25, fontWeight: FontWeight.bold),
          titleSmall: GoogleFonts.roboto().copyWith(fontSize: themeFontSizeNormal)),

      ///* Scaffold Background Color
      scaffoldBackgroundColor: themeBackgroundColor,

      ///* Buttons
      filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(themeColorPrimary),
              textStyle: WidgetStatePropertyAll(
                  GoogleFonts.roboto().copyWith(fontWeight: FontWeight.w700)))),

      ///* AppBar
      appBarTheme: AppBarTheme(
        color: themeBackgroundColor,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto().copyWith(
            fontSize: themeFontSizeTitle, fontWeight: FontWeight.bold, color: themeColorPrimary),
      ));
}
