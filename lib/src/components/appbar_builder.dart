import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/components/circle_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double height;
  final bool centerTitle;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title = '',
    this.height = kToolbarHeight,
    this.centerTitle = false,
    this.onBackPressed,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleWidget = Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Row(
        children: [
          if (showBackButton)
            CircleIconButton(
              icon: TablerIcons.arrow_left,
              onPressed:
                  onBackPressed ?? () => Navigator.of(context).maybePop(),
              //tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else
            const SizedBox(width: kToolbarHeight - 12),

          if (centerTitle)
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: titleWidget,
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: titleWidget,
              ),
            ),

          if (actions != null)
            Row(mainAxisSize: MainAxisSize.min, children: actions!)
          else
            const SizedBox(),
        ],
      ),
    );
  }
}
