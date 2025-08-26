import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/src/core/routes/router.dart';
import 'package:monalisa_app_001/src/providers/providers.dart';

/// **Main App Widget with Theming & Routing**
///  Flutter Version 3.32
///
class SwiftPayApp extends ConsumerWidget {
  const SwiftPayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    // final mode = ref.watch(settingsProvider).themeMode;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'monalisa_app_001',
      // Theme configuration
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.themeMode,
      // Routing
      initialRoute: AppRouter.initRoute,

      onGenerateRoute: AppRouter.generateRoute,

      //observers for status bar and contextless naigation
      // navigatorKey:GlobalNavigator.navigatorKey, // Register the global navigator key
      // navigatorObservers: [StatusBarObserver()], // Attach the observer
    );
  }
}
