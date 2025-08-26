// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';

class GlobalPageLayout extends StatelessWidget {
  final Widget header;
  final Widget footer;
  final double contentHeight;
  final EdgeInsets headerPadding;
  final EdgeInsets footerPadding;

  const GlobalPageLayout({
    super.key,
    required this.header,
    required this.footer,
    this.contentHeight = .58,
    this.headerPadding = EdgeInsets.zero,
    this.footerPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = context.getHeight;

    return Stack(
      children: [
        /// Background with decoration
        Container(
          height: screenHeight,
          decoration: BoxDecoration(
            color: context.primaryColor,
            image: DecorationImage(
              image: Svg(AssetSvgs.splashBGDark),
              fit: BoxFit.cover,
            ),
          ),
        ),

        /// Header at the top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: headerPadding,
            child: SizedBox(
              height: screenHeight * (1 - contentHeight),
              child: header,
            ),
          ),
        ),

        /// Footer at the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: footerPadding,
            child: SizedBox(
              height: screenHeight * contentHeight,
              child: footer,
            ),
          ),
        ),
      ],
    );
  }
}
