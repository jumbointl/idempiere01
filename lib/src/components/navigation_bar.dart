import 'package:flutter/material.dart';
import 'package:flutter_addons/flutter_addons.dart';

class NavItemData {
  final IconData icon;
  final String title;

  NavItemData({required this.icon, required this.title});
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItemData> navItems;


  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.navItems,
  });

  @override
  Widget build(BuildContext context) {
    int getVisualIndex(int index) {
      if (index > 2) return index - 1;
      if (index == 2) return -1; // QR item, never active
      return index;
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 72.h,
          decoration: BoxDecoration(
            color: context.background,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
            // borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              if (index == 2) {
                return SizedBox(width: 60.w);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTap(index),
                      splashColor: context.primaryColor.withValues(alpha: 0.3),
                      highlightColor: context.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      child: Padding(
                        padding: 8.p,
                        child: Icon(
                          navItems[index].icon,
                          color: getVisualIndex(index) == currentIndex
                              ? Colors.purple //context.primaryColor
                              : context.secondaryContent,
                          size: 28.sp,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    navItems[index].title,
                    style: context.bodySmall.copyWith(
                      color: getVisualIndex(index) == currentIndex
                          ? Colors.purple //context.primaryColor
                          : Colors.grey,

                      fontSize: 10.sp,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        Positioned(
          bottom: 10.h,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onTap(2),
              splashColor: context.primaryColor.withValues(alpha: 0.3),
              highlightColor: context.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: 12.p, // Adjusted padding for the central button
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: .55),
                      blurRadius: 12,
                      offset: Offset(2.w, 2.h),
                    ),
                  ],
                ),
                child: Icon(navItems[2].icon, color: Colors.white, size: 28.sp),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
