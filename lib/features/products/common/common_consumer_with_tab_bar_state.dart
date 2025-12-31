import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_theme.dart';
import 'common_consumer_state.dart';

// English: Base state for screens that share TabBar + AppBar + PopScope behavior.
abstract class CommonConsumerWithTabBarState<T extends ConsumerStatefulWidget>
    extends CommonConsumerState<T> {
  // English: Must provide tab count and tabs.
  int get tabLength;
  List<Widget> buildTabs();

  // English: Must provide tab views (raw children).
  List<Widget> buildTabViews();

  // English: Optional right-side actions (scan, keyboard, etc.)
  List<Widget> buildAppBarActions() => const [];

  // English: Default back behavior (can be overridden)
  void onBackPressed() => goHome();

  // -------------------------
  // Tab layout standardization
  // -------------------------

  // English: Default padding applied to every tab child (override per screen).
  EdgeInsets get tabPadding => EdgeInsets.zero;

  // English: Enable SafeArea wrapping for all tabs (override if needed).
  bool get tabSafeArea => false;

  // English: Wrap each tab child with padding/safearea/etc.
  Widget wrapTabChild(Widget child, int index) {
    Widget current = child;

    if (tabPadding != EdgeInsets.zero) {
      current = Padding(padding: tabPadding, child: current);
    }

    if (tabSafeArea) {
      current = SafeArea(child: current);
    }

    return current;
  }

  // English: Applies wrapper to all tab views.
  List<Widget> buildWrappedTabViews() {
    final views = buildTabViews();
    return List<Widget>.generate(
      views.length,
          (i) => wrapTabChild(views[i], i),
    );
    // Note: Ensure views.length == tabLength in your implementations.
  }

  // -------------------------
  // AppBar builder
  // -------------------------

  PreferredSizeWidget buildTabAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
      ),
      title: Row(
        children: [
          TabBar(
            tabs: buildTabs(),
            isScrollable: true,
            indicatorWeight: 4,
            indicatorColor: themeColorPrimary,
            dividerColor: themeColorPrimary,
            tabAlignment: TabAlignment.start,
            labelStyle: TextStyle(
              fontSize: themeFontSizeLarge,
              fontWeight: FontWeight.bold,
              color: themeColorPrimary,
            ),
            unselectedLabelStyle: TextStyle(fontSize: themeFontSizeLarge),
          ),
          const Spacer(),
          ...buildAppBarActions(),
        ],
      ),
    );
  }

  // -------------------------
  // Scaffold builder
  // -------------------------

  // English: Provides a scaffold with DefaultTabController + AppBar + PopScope
  Widget buildTabScaffold() {
    return DefaultTabController(
      length: tabLength,
      child: Scaffold(
        appBar: buildTabAppBar(),
        body: PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) onBackPressed();
          },
          child: TabBarView(children: buildWrappedTabViews()),
        ),
      ),
    );
  }
}
