import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

enum KeyShape { circle, rectangle }

class PinKeyboard extends StatelessWidget {
  final double keyFontSize;
  final bool swapPosition;
  final KeyShape keyShape;
  final Color backgroundColor;
  final void Function(String) onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onDonePressed;

  const PinKeyboard({
    super.key,
    required this.keyFontSize,
    required this.swapPosition,
    required this.keyShape,
    required this.backgroundColor,
    required this.onDigitPressed,
    required this.onDeletePressed,
    required this.onDonePressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ...List.generate(9, (index) => '${index + 1}'),
      '.',
      '0',
      '<',
    ];

    return GridView.builder(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      itemCount: buttons.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final value = buttons[index];

        Widget child;
        if (value == '<') {
          child = Icon(
            TablerIcons.backspace,
            size: keyFontSize,
            color: Kolors.red,
          );
        } else if (value == '.') {
          child = Icon(
            TablerIcons.circle_check,
            size: keyFontSize,
            color: context.primaryColor,
          );
        } else {
          child = Text(value, style: TextStyle(fontSize: keyFontSize));
        }

        return GestureDetector(
          onTap: () {
            if (value == '<') {
              onDeletePressed();
            } else if (value == '.') {
              onDonePressed();
            } else {
              onDigitPressed(value);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBackground,
              borderRadius: keyShape == KeyShape.rectangle
                  ? BorderRadius.circular(8.r)
                  : BorderRadius.circular(999.r),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}
