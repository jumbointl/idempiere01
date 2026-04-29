
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:riverpod_printer_ui/riverpod_printer_ui.dart';

import 'features/printer/storage/get_storage_label_profile_repository.dart';
import 'features/printer/storage/get_storage_printer_repository.dart';
import 'features/products/common/bluetooth_permission.dart';
import 'features/shared/data/memory.dart';

void main() async {
  await Environment.initEnvironment();
  await GetStorage.init();
  await requestMediaPermissionsForOcr();
  await ensureBluetoothPermissions();

  final GetStorage box = GetStorage();

  runApp(
    ProviderScope(
      overrides: [
        printerRepositoryProvider.overrideWithValue(
          GetStoragePrinterRepository(box),
        ),
        labelProfileRepositoryProvider.overrideWithValue(
          GetStorageLabelProfileRepository(box),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hydrateRiverpodPrinterUi(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = ref.watch(goRouterProvider);
    Memory.setImageSize(context);
    return MaterialApp.router(
      routerConfig: appRouter,
      theme: AppTheme().getTheme(),
      debugShowCheckedModeBanner: false,
    );
  }
}
