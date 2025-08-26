import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:monalisa_app_001/src/components/navigation_bar.dart';
import 'package:monalisa_app_001/src/core/routes/route_export.dart';
import 'package:monalisa_app_001/src/pages/my_cards/cards_view.dart';
import 'package:monalisa_app_001/src/pages/dashboard/dashboard.dart';
import 'package:monalisa_app_001/src/pages/profile_page/profile_view.dart';
import 'package:monalisa_app_001/src/pages/statistics_page/statistic_view.dart';
import 'package:monalisa_app_001/src/providers/providers.dart';

class HomePage extends ConsumerWidget {
  static const String route = '/home';
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentIndexProvider);

    final List<Widget> screens = [
      const Dashboard(),
      const StatisticView(),
      const CardsView(),
      const ProfileView(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Handle QR Navigation Separately
            context.pushName(QrScannerScreen.route);
          } else {
            // Update selected tab
            ref.read(currentIndexProvider.notifier).state = index > 2
                ? index - 1
                : index;
          }
        },
        navItems: [
          NavItemData(icon: TablerIcons.home, title: 'Home'),
          NavItemData(icon: TablerIcons.chart_dots, title: 'Statistics'),
          NavItemData(icon: TablerIcons.qrcode, title: ''),
          NavItemData(icon: TablerIcons.wallet, title: 'Cards'),
          NavItemData(icon: TablerIcons.user, title: 'Profile'),
        ],
      ),
    );
  }
}
