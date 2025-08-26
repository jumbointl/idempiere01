// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper for [Scaffold] that applies a [SafeArea]
/// and custom system UI overlay styling for the status bar.
class SaferGurd extends StatelessWidget {
  final Widget child;
  final Color? statusBarColor;
  final Brightness? statusBarIconBrightness;

  const SaferGurd({
    super.key,
    required this.child,
    this.statusBarColor,
    this.statusBarIconBrightness,
  });

  @override
  Widget build(BuildContext context) {
    final Brightness effectiveIconBrightness =
        statusBarIconBrightness ??
        (Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark);

    final Color effectiveStatusBarColor = statusBarColor ?? Colors.transparent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: effectiveStatusBarColor,
        statusBarIconBrightness: effectiveIconBrightness,
        statusBarBrightness: effectiveIconBrightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: SafeArea(top: true, bottom: false, child: child),
    );
  }
}
