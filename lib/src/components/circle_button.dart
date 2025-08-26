import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';

class CircleIconButton extends StatelessWidget {
  final IconData? icon;
  final String? iconPath;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final double elevation;
  final double padding;
  final double iconSize;
  final bool blur;

  const CircleIconButton({
    super.key,
    this.icon,
    this.iconPath,
    this.onPressed,
    this.size = 38.0,
    this.backgroundColor,
    this.iconColor,
    this.elevation = 0.0,
    this.padding = 4.0,
    this.iconSize = 24.0,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = iconPath != null
        ? SvgPicture.asset(
            iconPath!,
            height: iconSize,
            width: iconSize,
            colorFilter: iconColor != null
                ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                : null,
          )
        : Icon(
            icon,
            size: iconSize,
            color: iconColor ?? Theme.of(context).iconTheme.color,
          );

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? context.cardBackground,
          ),
          child: blur
              ? ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          color: (backgroundColor ?? Colors.white).withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: iconWidget,
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: iconWidget,
                  ),
                ),
        ),
      ),
    );
  }
}
