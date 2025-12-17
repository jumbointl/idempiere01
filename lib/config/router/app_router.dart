
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/config/router/app_router_notifier.dart';
import 'package:monalisa_app_001/features/auth/auth.dart';
import 'package:monalisa_app_001/features/auth/presentation/providers/auth_provider.dart';
import 'package:monalisa_app_001/features/home/presentation/screens/home_screen.dart';
import 'package:monalisa_app_001/features/m_inout/presentation/screens/m_in_out_screen.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_barcode_list_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/list/movement_list_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/movement_print_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/printer_setup_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/product_store_on_hand_screen_for_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/unsorted_storage_on__hand_read_only_screen.dart';
import '../../features/auth/presentation/screens/auth_data_screen.dart';
import '../../features/products/domain/idempiere/movement_and_lines.dart';
import '../../features/products/presentation/providers/common_provider.dart';
import '../../features/products/presentation/providers/locator_provider.dart';
import '../../features/products/presentation/providers/product_provider_common.dart';
import '../../features/products/presentation/screens/locator/search_locator_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/movement_cancel_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/movement_confirm_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/new_movement_edit_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/movement_lines_create_screen.dart';
import '../../features/products/presentation/screens/movement/create/movements_create_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/unsorted_storage_on__hand_select_locator_screen.dart';
import '../../features/products/presentation/screens/movement/pos/movement_pos_page.dart';
import '../../features/products/presentation/screens/movement/provider/products_home_provider.dart';
import '../../features/products/presentation/screens/movement/provider/new_movement_provider.dart';
import '../../features/products/presentation/screens/search/product_search_screen.dart';
import '../../features/products/presentation/screens/store_on_hand/product_store_on_hand_screen.dart';
import '../../features/products/presentation/screens/movement/create/unsorted_storage_on__hand_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/unsorted_storage_on__hand_screen_for_line.dart';
import '../../features/products/presentation/screens/search/update_product_upc_screen.dart';
import '../../features/shared/data/memory.dart';
import '../../features/shared/data/messages.dart';


class AppRouter {
  // app routes
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const String PAGE_UPDATE_PRODUCT_UPC = '/product/updateProductUPC';
  static const String PAGE_HOME = '/home';
  static const String PAGE_PRODUCT_SEARCH = '/product/search';
  static const String PAGE_PRODUCT_STORE_ON_HAND = '/storeOnHand';
  static const String PAGE_LOGIN = '/login';
  static const String PAGE_AUTH_DATA = '/authData';
  static const String PAGE_SPLASH = '/splash';
  static const String PAGE_M_IN_OUT = '/mInOut';
  static const String PAGE_M_IN_OUT_SHIPMENT = '/mInOut/shipment';
  static const String PAGE_M_IN_OUT_RETURN = '/mInOut/return';
  static const String PAGE_M_IN_OUT_TRANSFER = '/mInOut/transfer';
  static const String PAGE_M_IN_OUT_PICKING = '/mInOut/picking';
  static const String PAGE_M_IN_OUT_INVENTORY = '/mInOut/inventory';
  static const String PAGE_UNSORTED_STORAGE_ON_HAND = '/product/unsortedStorageOnHand';

  static const String PAGE_MOVEMENTS_EDIT = '/movement_search';
  static const String PAGE_MOVEMENTS_LIST = '/movement_list';

  static const String PAGE_SEARCH_LOCATOR_FROM = '/product/movement/createMovement/searchLocatorFrom';
  static const String PAGE_SEARCH_LOCATOR_TO = '/product/movement/createMovement/searchLocatorTo';
  static const String PAGE_SEARCH_LOCATOR_FROM_FOR_LINE = '/product/movement/createMovementLine/searchLocatorFrom';
  static const String PAGE_SEARCH_LOCATOR_TO_FOR_LINE = '/product/movement/createMovementLine/searchLocatorTo';
  static const String PAGE_CREATE_MOVEMENT_LINE = '/create_movement_line';
  static const String PAGE_MOVEMENTS_CONFIRM_SCREEN = '/movement_confirm_screen';
  static const String PAGE_CREATE_PUT_AWAY_MOVEMENT='/movement_create_put_away';
  static const String PAGE_PDF_MOVEMENT_AND_LINE='/pdf_movement_and_line';

  static const String PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE = '/store_on_hand_for_line';
  static const String PAGE_UNSORTED_STORAGE_ON_HAND_FOR_LINE = '/unsorted_store_on_hand_for_line';

  static String PAGE_MOVEMENT_PRINTER_SETUP='/movement_printer_set_up';
  static String PAGE_MOVEMENT_PRINT_POS='/movement_print_pos';
  static String PAGE_UNSORTED_STORAGE_ON_HAND_FOR_LINE_SELECT_LOCATOR = '/unsorted_store_on_hand_select_locator';


  static String PAGE_MOVEMENT_QR_LIST='/movement_qr_list';

  static String PAGE_UNSORTED_STORAGE_ON_HAND_READ_ONLY='/unsorted_store_on_hand_read_only';

  static String PAGE_MOVEMENT_REPAINT='/movement_repaint';

  static String PAGE_MOVEMENTS_CANCEL_SCREEN='/movement_cancel';



}

final int transitionTimeMilliseconds = 1000;

final goRouterProvider = Provider((ref) {

  final goRouterNotifier = ref.read(goRouterNotifierProvider);


  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: goRouterNotifier,
    routes: [
      ///* Primera pantalla
      GoRoute(
        path: '/splash',
        builder: (context, state) => const CheckAuthStatusScreen(),
      ),

      ///* Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      ///* Role Routes
      GoRoute(
        path: '/authData',
        builder: (context, state) => AuthDataScreen(),
      ),

      ///* Home Routes
      GoRoute(
          path: AppRouter.PAGE_HOME,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionDuration: Duration(milliseconds: transitionTimeMilliseconds ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                    opacity: animation, child: child);
              });
          }
      ),
      GoRoute(
          path: AppRouter.PAGE_MOVEMENTS_CONFIRM_SCREEN,
          builder: (context, state) {
            if(RolesApp.appMovementComplete) {

              MovementAndLines movementAndLines = state.extra as MovementAndLines;
              String argument = jsonEncode(movementAndLines.toJson());

              return MovementConfirmScreen(
                argument: argument,
                movementAndLines: state.extra as MovementAndLines,
              );
            } else { return const HomeScreen();}
          }
      ),
      GoRoute(
          path: AppRouter.PAGE_MOVEMENTS_CANCEL_SCREEN,
          builder: (context, state) {
            if(RolesApp.appMovementComplete) {

              MovementAndLines movementAndLines = state.extra as MovementAndLines;
              String argument = jsonEncode(movementAndLines.toJson());

              return MovementCancelScreen(
                argument: argument,
                movementAndLines: state.extra as MovementAndLines,
              );
            } else { return const HomeScreen();}
          }
      ),

      ///* MInOut Routes
      GoRoute(
        path: '/mInOut/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'shipment';
          final documentNo = '-1';
          return MInOutScreen(type: type, documentNo: documentNo);
        },
      ),
      GoRoute(
        path: '/mInOut/:type/:documentNo',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'shipment';
          final documentNo = state.pathParameters['documentNo'] ?? '-1';

          return MInOutScreen(type: type, documentNo: documentNo);
        },
      ),
      GoRoute(
        path: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/:productId',
        pageBuilder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '';
          final hasPrivilege = RolesApp.canCreateMovementInSameOrganization || RolesApp.canSearchProductStock;

          if (hasPrivilege) {
            // Use a FutureBuilder to show a loading indicator for 2 seconds
            return CustomTransitionPage(
              key: state.pageKey,
              child: FutureBuilder(
                future: Future.delayed(Duration(milliseconds: transitionTimeMilliseconds)),
                builder: (context, snapshot) {


                  if (snapshot.connectionState == ConnectionState.done) {
                    return ProductStoreOnHandScreen(productId: productId);
                  }


                  Future.microtask(() async {
                    ref.invalidate(actualWarehouseToProvider);
                    ref.read(homeScreenTitleProvider.notifier).state = Messages.NEW_MOVEMENT;
                    ref.read(productsHomeCurrentIndexProvider.notifier)
                        .update((state) => Memory.PAGE_INDEX_STORE_ON_HAND);
                    ref.read(actionScanProvider.notifier)
                        .update((state) => Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);
                    ref.read(isDialogShowedProvider.notifier).update((state) => false);
                  });
                  return const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              transitionDuration: Duration(microseconds: transitionTimeMilliseconds),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            );
          } else {
            return const NoTransitionPage(child: HomeScreen());
          }
        },
      ),

      GoRoute(
          path: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/:productUPC',
          builder: (context, state){
            if( RolesApp.canCreateMovementInSameOrganization ||
                RolesApp.canCreateDeliveryNote || RolesApp.canEditMovement){
              final productUPC = state.pathParameters['productUPC'] ?? '';
              Future.delayed(Duration.zero, () {
                ref.invalidate(allowedMovementDocumentTypeProvider);
                ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
                Memory.PAGE_INDEX_STORE_ON_HAND);
                ref.read(actionScanProvider.notifier).update((state) =>
                Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);
                ref.read(isDialogShowedProvider.notifier).update((state) => false);
                ref.read(isScanningProvider.notifier).update((state) => false);

              });
              MovementAndLines movementAndLines = state.extra as MovementAndLines;
              movementAndLines.nextProductIdUPC = productUPC;
              String argument = jsonEncode(movementAndLines.toJson());
              print('productUPC: $productUPC');
              return ProductStoreOnHandScreenForLine(
                  productId: productUPC,
                  movementAndLines: state.extra as MovementAndLines,
                  argument: argument);

            } else{
              return const HomeScreen();
            }
          }


      ),
      GoRoute(
          path: AppRouter.PAGE_PDF_MOVEMENT_AND_LINE,
          builder: (context, state){
            if( RolesApp.hasStockPrivilege){
              MovementAndLines movementAndLines = state.extra as MovementAndLines;
              var m = ref.read(movementAndLinesProvider.notifier);
              m.state = movementAndLines;
              String argument = jsonEncode(movementAndLines.toJson());
              print('argument: $argument');
              return MovementPrintScreen(
                  movementAndLines: movementAndLines,
                  argument: argument,);

            } else{
              return const HomeScreen();
            }
          }


      ),
      GoRoute(
          path: AppRouter.PAGE_MOVEMENT_PRINTER_SETUP,
          builder: (context, state){
            if( RolesApp.hasStockPrivilege){
              MovementAndLines movementAndLines = state.extra as MovementAndLines;
              var m = ref.read(movementAndLinesProvider.notifier);
              m.state = movementAndLines;
              String argument = jsonEncode(movementAndLines.toJson());
              return PrinterSetupScreen(
                movementAndLines: movementAndLines,
                argument: argument);

            } else{
              return const HomeScreen();
            }
          }


      ),
      GoRoute(
          path: AppRouter.PAGE_MOVEMENT_QR_LIST,
          builder: (context, state){
            if( RolesApp.hasStockPrivilege){
              MovementAndLines movementAndLines = state.extra as MovementAndLines;
              return MovementBarcodeListScreen(
                  argument: jsonEncode(movementAndLines.toJson()),
                  movementAndLines: movementAndLines,);

            } else{
              return const HomeScreen();
            }
          }


      ),
      GoRoute(
        path: AppRouter.PAGE_MOVEMENT_PRINT_POS,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MovementPosPage(
            ip: extra['ip'] as String,
            port: extra['port'] as int,
            data: extra['movementAndLines'] as MovementAndLines,
          );
        },
      ),
      GoRoute(
        path: '${AppRouter.PAGE_MOVEMENTS_LIST}/:movementDateFilter',
        pageBuilder: (context, state) {
          if (RolesApp.canSearchMovement || RolesApp.canEditMovement) {

            return CustomTransitionPage(
              key: state.pageKey,
              child: FutureBuilder(
                future: Future.delayed(Duration(milliseconds: transitionTimeMilliseconds)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    String movementDateFilter = state.pathParameters['movementDateFilter'] ??
                        MovementListScreen.COMMAND_DO_NOTHING;
                    return MovementListScreen(movementDateFilter: movementDateFilter);
                  }
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              transitionDuration:Duration(microseconds: transitionTimeMilliseconds),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            );
          } else {
            return const NoTransitionPage(child: HomeScreen());
          }
        },
      ),
      GoRoute(
        path: '${AppRouter.PAGE_MOVEMENT_REPAINT}/:movementId',
        pageBuilder: (context, state) {
          if (RolesApp.canEditMovement) {

            String movementId = state.pathParameters['movementId'] ??
                NewMovementEditScreen.WAIT_FOR_SCAN_MOVEMENT;
            String fromPage = '1';

            Future.delayed(Duration.zero, () {
              ref.invalidate(allowedMovementDocumentTypeProvider);
              MemoryProducts.movementAndLines.clearData();
              GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
              ref.read(homeScreenTitleProvider.notifier).state = Messages.MOVEMENT_SEARCH;
              ref.read(productsHomeCurrentIndexProvider.notifier).update(
                      (state) => Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);
              ref.read(actionScanProvider.notifier).update(
                      (state) => Memory.ACTION_FIND_MOVEMENT_BY_ID);
            });
            return CustomTransitionPage(
              key: state.pageKey,
              child: FutureBuilder(
                future: Future.delayed(Duration(milliseconds: transitionTimeMilliseconds)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return NewMovementEditScreen(
                        fromPage: fromPage,
                        movementId: movementId);
                  }
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              transitionDuration:Duration(microseconds: transitionTimeMilliseconds),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            );
          } else {
            return const NoTransitionPage(child: HomeScreen());
          }
        },
      ),
      GoRoute(
        path: '${AppRouter.PAGE_MOVEMENTS_EDIT}/:movementId',
        pageBuilder: (context, state) {
          if (RolesApp.canEditMovement) {

            String movementId = state.pathParameters['movementId'] ??
                NewMovementEditScreen.WAIT_FOR_SCAN_MOVEMENT;
            String fromPage = '-1';

            Future.delayed(Duration.zero, () {
              ref.invalidate(allowedMovementDocumentTypeProvider);
              MemoryProducts.movementAndLines.clearData();
              GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
              ref.read(homeScreenTitleProvider.notifier).state = Messages.MOVEMENT_SEARCH;
              ref.read(productsHomeCurrentIndexProvider.notifier).update(
                      (state) => Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);
              ref.read(actionScanProvider.notifier).update(
                      (state) => Memory.ACTION_FIND_MOVEMENT_BY_ID);
            });
            return CustomTransitionPage(
              key: state.pageKey,
              child: FutureBuilder(
                future: Future.delayed(Duration(milliseconds: transitionTimeMilliseconds)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return NewMovementEditScreen(
                        fromPage: fromPage,
                        movementId: movementId);
                  }
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              transitionDuration:Duration(microseconds: transitionTimeMilliseconds),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            );
          } else {
            return const NoTransitionPage(child: HomeScreen());
          }
        },
      ),
      GoRoute(
        path: '${AppRouter.PAGE_MOVEMENTS_EDIT}/:movementId/:fromPage',
        pageBuilder: (context, state) {
          if (RolesApp.canEditMovement) {

            String movementId = state.pathParameters['movementId'] ??
                NewMovementEditScreen.WAIT_FOR_SCAN_MOVEMENT;
            String fromPage = state.pathParameters['fromPage'] ??
                NewMovementEditScreen.FROM_PAGE_HOME;

            Future.delayed(Duration.zero, () {

              ref.invalidate(allowedMovementDocumentTypeProvider);
              MemoryProducts.movementAndLines.clearData();
              GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
              ref.read(homeScreenTitleProvider.notifier).state = Messages.MOVEMENT_SEARCH;
              ref.read(productsHomeCurrentIndexProvider.notifier).update(
                      (state) => Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);
              ref.read(actionScanProvider.notifier).update(
                      (state) => Memory.ACTION_FIND_MOVEMENT_BY_ID);
            });
            return CustomTransitionPage(
              key: state.pageKey,
              child: FutureBuilder(
                future: Future.delayed(Duration(milliseconds: transitionTimeMilliseconds)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return NewMovementEditScreen(
                        fromPage: fromPage,
                        movementId: movementId);
                  }
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              transitionDuration:Duration(microseconds: transitionTimeMilliseconds),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            );
          } else {
            return const NoTransitionPage(child: HomeScreen());
          }
        },
      ),

      GoRoute(
        path: '${AppRouter.PAGE_CREATE_MOVEMENT_LINE}/:argument',

        builder: (context, state) {
              if(RolesApp.canCreateMovementInSameOrganization || RolesApp.canCreateDeliveryNote) {
                MovementAndLines movementAndLines = state.extra as MovementAndLines;
                //print(movementAndLines.toJson());
                String argument = jsonEncode(movementAndLines.toJson());
                print(argument);
                return MovementLinesCreateScreen(
                    argument: argument,
                    movementAndLines: state.extra as MovementAndLines,
                    width: MemoryProducts.width,
                    );
              } else { return const HomeScreen();}
        }
      ),

      GoRoute(
          path: AppRouter.PAGE_CREATE_PUT_AWAY_MOVEMENT,
          builder: (context, state) {
            if(RolesApp.canCreateMovementInSameOrganization || RolesApp.canCreateDeliveryNote) {
              return MovementsCreateScreen(
                putAwayMovement: state.extra as PutAwayMovement,
              );
            } else { return const HomeScreen();}
          }
      ),

      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_FROM,
        builder: (context, state) => RolesApp.hasStockPrivilege ?
        SearchLocatorScreen(searchLocatorFrom: true,forCreateLine: false) : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_TO,
        builder: (context, state) => RolesApp.hasStockPrivilege ?
        SearchLocatorScreen( searchLocatorFrom: false,forCreateLine: false) : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_FROM_FOR_LINE,
        builder: (context, state) => RolesApp.hasStockPrivilege ?
        SearchLocatorScreen(searchLocatorFrom: true,forCreateLine: true) : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_TO_FOR_LINE,
        builder: (context, state) => RolesApp.hasStockPrivilege ?
        SearchLocatorScreen( searchLocatorFrom: false,forCreateLine: true) : const HomeScreen(),
      ),

      GoRoute(
        path: AppRouter.PAGE_PRODUCT_SEARCH,
        builder: (context, state){
          Future.delayed(Duration.zero, () {
            ref.read(actionScanProvider.notifier).state =
                Memory.ACTION_FIND_BY_UPC_SKU;
          });
          return RolesApp.hasStockPrivilege ? ProductSearchScreen() : const HomeScreen();
        }
      ),
      GoRoute(
        path: '${AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND}/:productUPC',
        builder: (context, state) {
          {
            if(!RolesApp.canCreateMovementInSameOrganization
                && !RolesApp.canCreateDeliveryNote && !RolesApp.canSearchProductStock){
              return const HomeScreen();
            }
            final productUPC = state.pathParameters['productUPC'] ?? '';
            Future.delayed(Duration.zero, () {
              ref.read(isDialogShowedProvider.notifier).update((state) => false);
              ref.read(actionScanProvider.notifier).state =
                  Memory.ACTION_GET_LOCATOR_TO_VALUE;
              ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
              Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND);
              ref.invalidate(selectedLocatorToProvider);
            });
            print('actionScanProvider: ${ ref.read(actionScanProvider.notifier).state}');

            return UnsortedStorageOnHandScreen(
              productUPC: productUPC,
              index:MemoryProducts.index,
              storage: MemoryProducts.storage,
              width: MemoryProducts.width,);
          }
        },
      ),
      GoRoute(
        path: '${AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND_READ_ONLY}/:productUPC',
        builder: (context, state) {
          {
            if(!RolesApp.canSearchProductStock){
              return const HomeScreen();
            }
            final productUPC = state.pathParameters['productUPC'] ?? '';

            return UnsortedStorageOnHandReadOnlyScreen(
              productUPC: productUPC,
              index:MemoryProducts.index,
              storage: MemoryProducts.storage,
              width: MemoryProducts.width,);
          }
        },
      ),
      GoRoute(
        path: '${AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND_FOR_LINE_SELECT_LOCATOR}/:argument',
        builder: (context, state) {
          {
            if(!RolesApp.canCreateMovementInSameOrganization && !RolesApp.canCreateDeliveryNote){
              return const HomeScreen();
            }
            //final argument = state.pathParameters['argument'] ?? '';
            MovementAndLines movementAndLines = state.extra as MovementAndLines;
            String argument = jsonEncode(movementAndLines.toJson());
            String upc = MemoryProducts.storage.mProductID?.uPC ?? '-1';
            MemoryProducts.movementAndLines = movementAndLines;
            Future.delayed(Duration.zero, () {
              ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
              Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND);
              ref.read(actionScanProvider.notifier).update((state) =>
              Memory.ACTION_GET_LOCATOR_TO_VALUE);
            });
            return UnsortedStorageOnHandSelectLocatorScreen(
              argument: argument,
              movementAndLines: movementAndLines,
              index:MemoryProducts.index,
              storage: MemoryProducts.storage,
              productUPC: upc,
              width: MemoryProducts.width,);
          }
        },
      ),
      GoRoute(
        path: '${AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND_FOR_LINE}/:argument',
        builder: (context, state) {
          {
            if(!RolesApp.canCreateMovementInSameOrganization && !RolesApp.canCreateDeliveryNote){
              return const HomeScreen();
            }
            //final argument = state.pathParameters['argument'] ?? '';
            MovementAndLines movementAndLines = state.extra as MovementAndLines;
            String argument = jsonEncode(movementAndLines.toJson());

            Future.delayed(Duration.zero, () {
              ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
              Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND);
              ref.read(actionScanProvider.notifier).update((state) =>
                  Memory.ACTION_GET_LOCATOR_TO_VALUE);
            });
            String upc = MemoryProducts.storage.mProductID?.uPC ?? '-1';
            return UnsortedStorageOnHandScreenForLine(
              argument: argument,
              movementAndLines: movementAndLines,
              index:MemoryProducts.index,
              storage: MemoryProducts.storage,
              width: MemoryProducts.width,);
          }
        },
      ),
      GoRoute(
        path: AppRouter.PAGE_UPDATE_PRODUCT_UPC,
        pageBuilder: (context, state) {
          FocusManager.instance.primaryFocus?.unfocus();

          return CustomTransitionPage(
            key: state.pageKey,
            child: RolesApp.canUpdateProductUPC
                ? UpdateProductUpcScreen()
                : const HomeScreen(),
            transitionDuration: Duration(milliseconds: transitionTimeMilliseconds),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // Change the opacity of the screen using a Curve based on the animation's
              // value
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOutCirc)
                    .animate(animation),
                child: child,
              );
            },
          );
        },
      ),

    ],
    redirect: (context, state) {
      final isGoingTo = state.uri.toString();
      final authStatus = goRouterNotifier.authStatus;

      if (isGoingTo == '/splash' && authStatus == AuthStatus.checking) {
        return null;
      }

      if (authStatus == AuthStatus.notAuthenticated) {
        if (isGoingTo == '/login') return null;
        return '/login';
      }

      if (authStatus == AuthStatus.login) {
        return '/authData';
      }

      if (authStatus == AuthStatus.authenticated) {
        if (isGoingTo == '/login' || isGoingTo == '/splash' || isGoingTo == '/authData') {
          return '/home';
        }
      }

      return null;
    },
  );

});

// Clipper personalizado
class CircleRevealClipper extends CustomClipper<Path> {
  final double revealPercent;
  CircleRevealClipper(this.revealPercent);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * revealPercent;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant CircleRevealClipper oldClipper) =>
      oldClipper.revealPercent != revealPercent;
}




// provider que controla el estado de carga
final loadingProvider =
StateNotifierProvider<LoadingController, bool>((ref) => LoadingController());

class LoadingController extends StateNotifier<bool> {
  LoadingController() : super(false);

  /// Muestra el loader por [milliseconds] y luego lo oculta automáticamente.
  Future<void> showFor({int milliseconds = 1000}) async {
    if (state) return; // ya activo
    state = true;
    await Future.delayed(Duration(milliseconds: milliseconds));
    state = false;
  }

  /// Control manual (opcional)
  void start() => state = true;
  void stop() => state = false;
}

