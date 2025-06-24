import 'package:flutter/material.dart';

import '../../../../config/config.dart';

class HomeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const HomeOption({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(themeBorderRadius)),
        child: Container(
          width: 90,
          height: 90,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(themeBorderRadius),
            color: themeColorPrimary,
            // color: themeColorPrimaryLight,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: Colors.white),
              // Icon(icon, size: 34, color: themeColorPrimary),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: themeFontSizeSmall, color: Colors.white, fontWeight: FontWeight.w500),
                // style: TextStyle(fontSize: themeFontSizeSmall, color: themeColorPrimary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
