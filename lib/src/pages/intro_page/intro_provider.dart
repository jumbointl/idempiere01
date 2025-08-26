import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

final introProvider = ChangeNotifierProvider<IntroViewModel>((ref) {
  return IntroViewModel();
});

class IntroViewModel extends ChangeNotifier {
  final PageController pageController = PageController();
  int currentPage = 0;

  static const int introLength = 3;

  void setPage(int index) {
    currentPage = index;
    notifyListeners();
  }

  bool get isLastPage => currentPage == introLength - 1;

  Future<void> completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
  }

  Future<bool> isIntroAlreadySeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('intro_seen') ?? false;
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
