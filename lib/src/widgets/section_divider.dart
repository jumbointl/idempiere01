import 'package:flutter/cupertino.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Icon(
          TablerIcons.dots,
          color: context.outline.withValues(alpha: 0.5),
          size: 18,
        ),
      ),
    );
  }
}
