import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/shared/shared.dart';
import 'package:upgrader/upgrader.dart';

import '../../../auth/presentation/screens/exit_app.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/presentation/widgets/side_menu.dart';

final upgradeAlertSeedProvider = StateProvider<int>((ref) => 0);
final homeSectionIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final sectionIndex = ref.watch(homeSectionIndexProvider);
    final upgradeSeed = ref.watch(upgradeAlertSeedProvider);

    MemoryProducts.width = MediaQuery.of(context).size.width;

    final upgrader = Upgrader(
      debugLogging: true,
      durationUntilAlertAgain: const Duration(days: 1),
    );

    final functionText = Memory.production
        ? '${Memory.APP_NAME} ${upgrader.versionInfo?.installedVersion ?? 0}'
        :Memory.APP_NAME_WITH_VERSION;
    final sections = _buildHomeSections();

    return UpgradeAlert(
      key: ValueKey(upgradeSeed),
      upgrader: upgrader,
      child: Scaffold(
        key: scaffoldKey,
        drawer: SideMenu(scaffoldKey: scaffoldKey),
        appBar: AppBar(
          title: Text(
            functionText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Memory.production ? IconButton(
              icon: const Icon(Icons.system_update_alt),
              tooltip: 'Check update',
              onPressed: () async {
                await Upgrader.clearSavedSettings();
                ref.read(upgradeAlertSeedProvider.notifier).state++;
              },
            ) : IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Link',
              onPressed: () async {
                String message = Memory.APP_PLAY_STORE_LINK;
                showSuccessMessage(context, ref, message);
              },
            ) ,
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                exitApp(context, ref);
              },
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(

          selectedIndex: sectionIndex,
          onDestinationSelected: (index) {
            ref.read(homeSectionIndexProvider.notifier).state = index;
          },
          destinations: const [
            NavigationDestination(

              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Ship',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz),
              label: 'Move',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build),
              label: 'Util',
            ),
          ],
        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            exitApp(context, ref);
          },
          child: SafeArea(
            child: IndexedStack(
              index: sectionIndex,
              children: sections
                  .map((section) => _HomeSectionPage(section: section))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSectionData {
  final String title;
  final List<MenuItem> col1;
  final List<MenuItem> col2;
  final List<MenuItem> col3;

  const _HomeSectionData({
    required this.title,
    required this.col1,
    required this.col2,
    required this.col3,
  });
}

List<_HomeSectionData> _buildHomeSections() {
  final shipCol1 = <MenuItem>[
    ...appHomeOptionCol1Items.where(
          (e) =>
      e.title == 'Shipment' ||
          e.title == 'Shipment Prepare' ||
          e.title == 'Shipment Confirm',
    ),
  ];

  final shipCol2 = <MenuItem>[
    ...appHomeOptionCol1Items.where((e) => e.title == 'Pick Confirm'),
    ...appHomeOptionCol1Items.where((e) => e.title == 'Shipment Create'),

  ];

  final shipCol3 = <MenuItem>[
    ...appHomeOptionCol2Items.where((e) => e.title == 'Receipt'),
    ...appHomeOptionCol2Items.where((e) => e.title == 'Multiple Receipt'),
    ...appHomeOptionCol2Items.where((e) => e.title == 'Receipt Confirm'),
    ...appHomeOptionCol2Items.where((e) => e.title == 'QA Confirm'),
    ...appHomeOptionCol2Items.where((e) => e.title == 'M In/Out by Type'),
  ];

  final moveCol1 = <MenuItem>[

    ...appHomeOptionCol3Items.where(
            (e) =>

            e.title.trim() == 'PutAway' ||
            e.title.trim() == 'Replenish' ||
            e.title.trim() == 'Delivery Note Fiscal'

    ),
  ];

  final moveCol2 = <MenuItem>[
    ...appHomeOptionCol3Items.where(
          (e) =>
      e.title == 'Move Complete' ||
          e.title == 'Move Confirm'
    ),
    ...appHomeOptionCol2Items.where(
            (e) =>
        e.title == Messages.TITLE_MOVEMENT_LIST ||
            e.title == Messages.MOVEMENT_EDIT

    ),
  ];

  final moveCol3 = <MenuItem>[
    ...appHomeOptionCol3Items.where(
          (e) =>
          e.title == 'Inventory List' ||
          e.title == 'Inventory' ||
          e.title == 'Inventory Edit',
    ),
  ];

  final utilCol1 = <MenuItem>[
    ...appHomeOptionCol1Items.where(
          (e) =>
      e.title == Messages.SEARCH_PRODUCT || e.title == 'Locator List',
    ),
    ...appHomeOptionCol1Items.where(
          (e) =>
      e.title == 'Example',
    ),
  ];

  final utilCol2 = <MenuItem>[
    ...appHomeOptionCol1Items.where((e) => e.title == 'ZPL Template'),
    ...appHomeOptionCol2Items.where((e) => e.title == 'NIIMBOT config'),
  ];

  final utilCol3 = <MenuItem>[
    ...appHomeOptionCol2Items.where((e) => e.title == 'Printer config'),
    ...appHomeOptionCol3Items.where((e) => e.title == Messages.STORE_ON_HAND),
  ];

  return [
    _HomeSectionData(
      title: 'Ship',
      col1: shipCol1,
      col2: shipCol2,
      col3: shipCol3,
    ),
    _HomeSectionData(
      title: 'Move',
      col1: moveCol1,
      col2: moveCol2,
      col3: moveCol3,
    ),
    _HomeSectionData(
      title: 'Util',
      col1: utilCol1,
      col2: utilCol2,
      col3: utilCol3,
    ),
  ];
}

class _HomeSectionPage extends StatelessWidget {
  final _HomeSectionData section;

  const _HomeSectionPage({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          _SectionHeader(title: section.title),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 10.0;
                final totalSpacing = spacing * 2;
                final columnWidth = (constraints.maxWidth - totalSpacing) / 3;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeMenuColumn(
                      width: columnWidth,
                      items: section.col1,
                    ),
                    SizedBox(width: spacing),
                    _HomeMenuColumn(
                      width: columnWidth,
                      items: section.col2,
                    ),
                    SizedBox(width: spacing),
                    _HomeMenuColumn(
                      width: columnWidth,
                      items: section.col3,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _HomeMenuColumn extends StatelessWidget {
  final double width;
  final List<MenuItem> items;

  const _HomeMenuColumn({
    required this.width,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SizedBox(
        width: width,
        child: const _EmptyColumnCard(),
      );
    }

    return SizedBox(
      width: width,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final menuHomeOption = items[index];
          return HomeOption(
            title: menuHomeOption.title,
            icon: menuHomeOption.icon,
            onTap: () => context.push(menuHomeOption.link),
          );
        },
      ),
    );
  }
}

class _EmptyColumnCard extends StatelessWidget {
  const _EmptyColumnCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        'Sin opciones',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}