import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

import 'package:monalisa_app_001/src/core/constants/app_constants.dart';

class PrimaryButton extends StatelessWidget {
  final bool expand;
  final String label;
  final String? icon;
  final IconData? dataIcon;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final Color? iconColor;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    this.expand = true,
    required this.label,
    this.icon,
    this.dataIcon,
    this.color,
    this.textColor,
    this.borderColor,
    this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            color ?? context.primaryColor,
          ),
          foregroundColor: WidgetStateProperty.all(context.forground),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          ),
          side: borderColor != null
              ? WidgetStateProperty.all(
                  BorderSide(
                    color: borderColor ?? context.primaryColor.darken(.45),
                    width: 1,
                  ),
                )
              : null,
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadius.r),
            ),
          ),
          elevation: WidgetStateProperty.all(0.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dataIcon != null) ...[
              Icon(dataIcon, color: iconColor),
              SizedBox(width: 10.w),
            ],
            if (icon != null) ...[
              Image.asset(icon!, height: 20.h),
              SizedBox(width: 10.w),
            ],
            Text(
              label,
              style: context.bodyMedium.copyWith(
                color: textColor ?? context.titleInverse,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
