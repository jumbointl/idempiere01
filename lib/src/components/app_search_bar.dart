import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:monalisa_app_001/src/core/resource/app_resources.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Color backgroundColor;
  final String svgIconPath;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    required this.svgIconPath,
    this.backgroundColor = const Color(0xFFF1F3F4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            AssetSvgs.search,
            height: 28.h,
            width: 28.w,
            colorFilter: ColorFilter.mode(
              context.primaryColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: context.bodyMedium,
              cursorColor: context.primaryColor,
              textInputAction: TextInputAction.search,

              onChanged: onChanged,
              decoration: InputDecoration(
                fillColor: context.inputBackground,
                hintText: hintText,
                border: InputBorder.none,
                isDense: true,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
