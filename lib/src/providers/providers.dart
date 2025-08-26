import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/src/core/themes/app_theme.dart';

// Provider for managing theme
final themeProvider = ChangeNotifierProvider<Themer>((ref) {
  return Themer();
});

// Provider for managing the current selected tab
final currentIndexProvider = StateProvider<int>((ref) => 0);

//Provider fro managing introscreen
