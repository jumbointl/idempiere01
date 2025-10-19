
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/config/router/app_router_notifier.dart';
import 'package:monalisa_app_001/features/auth/auth.dart';
import 'package:monalisa_app_001/features/auth/presentation/providers/auth_provider.dart';
import 'package:monalisa_app_001/features/home/presentation/screens/home_screen.dart';
import 'package:monalisa_app_001/features/m_inout/presentation/screens/m_in_out_screen.dart';
import 'package:monalisa_app_001/features/products/common/scanner_screen.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/locator/search_locator_screen_from_scan.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/movement_error_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/movement_print_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/printer/printer_setup_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/edit_new/product_store_on_hand_screen_for_line.dart';
import '../../features/auth/presentation/screens/auth_data_screen.dart';
import '../../features/products/domain/idempiere/movement_and_lines.dart';
import '../../features/products/domain/sql/sql_data_movement_line.dart';
import '../../features/products/presentation/providers/locator_provider.dart';
import '../../features/products/presentation/providers/product_provider_common.dart';
import '../../features/products/presentation/providers/products_scan_notifier_for_line.dart';
import '../../features/products/presentation/providers/store_on_hand_provider.dart';
import '../../features/products/presentation/screens/locator/search_locator_screen.dart';
import '../../features/products/presentation/screens/movement/create/product_for_new_movement_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/new_movement_edit_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/movement_confirm_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/movement_lines_create_screen.dart';
import '../../features/products/presentation/screens/movement/edit/movements_screen.dart';
import '../../features/products/presentation/screens/movement/create/movements_create_screen.dart';
import '../../features/products/presentation/screens/movement/products_home_provider.dart';
import '../../features/products/presentation/screens/movement/provider/new_movement_provider.dart';
import '../../features/products/presentation/screens/search/product_search_screen.dart';
import '../../features/products/presentation/screens/store_on_hand/product_store_on_hand_screen.dart';
import '../../features/products/presentation/screens/store_on_hand/product_store_on_hand_screen2.dart';
import '../../features/products/presentation/screens/movement/create/unsorted_storage_on__hand_screen.dart';
import '../../features/products/presentation/screens/movement/edit_new/unsorted_storage_on__hand_screen_for_line.dart';
import '../../features/products/presentation/screens/update_upc/update_product_upc_screen3.dart';
import '../../features/products/presentation/widget/barcode_scanner_screen.dart';
import '../../features/shared/data/memory.dart';


class AppRouter {
  // app routes
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const String PAGE_UPDATE_PRODUCT_UPC = '/product/updateProductUPC';
  static const String PAGE_HOME = '/home';
  static const String PAGE_PRODUCT_SEARCH = '/product/search';
  static const String PAGE_PRODUCT_STORE_ON_HAND = '/storeOnHand';
  static const String PAGE_PRODUCT_STORE_ON_HAND_2 = '/storeOnHand2';
  static const String PAGE_PRODUCT_SEARCH_UPDATE_UPC = '/product/searchUpdateProductUPC';
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
  static const String NEW_PAGE_STORAGE_ON_HANGE = '/movement_create';

  static const String PAGE_MOVEMENTS_SEARCH = '/movement_search';

  static const String PAGE_SEARCH_LOCATOR_FROM = '/product/movement/createMovement/searchLocatorFrom';
  static const String PAGE_SEARCH_LOCATOR_TO = '/product/movement/createMovement/searchLocatorTo';
  static const String PAGE_SEARCH_LOCATOR_FROM_FOR_LINE = '/product/movement/createMovementLine/searchLocatorFrom';
  static const String PAGE_SEARCH_LOCATOR_TO_FOR_LINE = '/product/movement/createMovementLine/searchLocatorTo';
  static const String PAGE_CREATE_MOVEMENT_LINE = '/create_movement_line';
  static const String PAGE_MOVEMENTS_CONFIRM_SCREEN = '/movement_confirm_screen';
  static const String PAGE_CREATE_PUT_AWAY_MOVEMENT='/movement_create_put_away';
  static const String PAGE_SCAN_TOCATOR_TO='/scan_locator_to';
  static const String PAGE_BARCODE_SCANER='/barcode_scanner';
  static const String PAGE_PDF_MOVEMENT_AND_LINE='/pdf_movement_and_line';

  static const String PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE = '/store_on_hand_for_line';
  static const String PAGE_UNSORTED_STORAGE_ON_HAND_FOR_LINE = '/unsorted_store_on_hand_for_line';

  static String PAGE_MOVEMENT_PRINTER_SETUP='/movement_printer_set_up';


}


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
        builder: (context, state) => const HomeScreen(),
      ),

      ///* MInOut Routes
      GoRoute(
        path: '/mInOut/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'shipment';
          return MInOutScreen(type: type);
        },
      ),
      GoRoute(
        path: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/:productId',

        // This allow in app call like
        // context.push(AppRouter.PAGE_PRODUCT_STORE_ON_HAND+'/100001)
        // (to pass movementId) when navigate within the app ';
        builder: (context, state){
            if( RolesApp.hasStockPrivilege()){
              Future.delayed(Duration(milliseconds: 10), () {
                ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
                Memory.PAGE_INDEX_STORE_ON_HAND);
                ref.read(actionScanProvider.notifier).update((state) =>
                Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);
                ref.read(isDialogShowedProvider.notifier).update((state) => false);
              });

              final productId = state.pathParameters['productId'] ?? '';

              return ProductStoreOnHandScreen(productId: productId);

            } else{
              return const HomeScreen();
            }
        }


      ),
      GoRoute(
          path: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND_FOR_LINE}/:productUPC',
          builder: (context, state){
            if( RolesApp.hasStockPrivilege()){
              final productUPC = state.pathParameters['productUPC'] ?? '';
              Future.delayed(Duration(milliseconds: 10), () {
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
            if( RolesApp.hasStockPrivilege()){
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
            if( RolesApp.hasStockPrivilege()){
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
          path: AppRouter.PAGE_PRODUCT_STORE_ON_HAND_2,
          builder: (context, state){
            if( RolesApp.hasStockPrivilege()){

              return ProductStoreOnHandScreen2();

            } else{
              return const HomeScreen();
            }
          }

      ),
      GoRoute(
          path: AppRouter.PAGE_BARCODE_SCANER,
          builder: (context, state){
            if( RolesApp.hasStockPrivilege()){

              return BarcodeScannerScreen();

            } else{
              return const HomeScreen();
            }
          }

      ),

      GoRoute(
        path: '${AppRouter.PAGE_MOVEMENTS_SEARCH}/:movementId',

        builder: (context,GoRouterState state) {


              if(RolesApp.hasStockPrivilege()) {
                String movementId = state.pathParameters['movementId'] ?? MovementsScreen.WAIT_FOR_SCAN_MOVEMENT;
                  if(movementId==':movementId'){
                    movementId = MovementsScreen.WAIT_FOR_SCAN_MOVEMENT;
                  }

                  MemoryProducts.movementAndLines.clearData();
                GetStorage().remove(Memory.KEY_MOVEMENT_AND_LINES);
                  Future.delayed(Duration(milliseconds: 50), () {
                    ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
                    Memory.PAGE_INDEX_MOVEMENTE_EDIT_SCREEN);
                    ref.read(actionScanProvider.notifier).update((state) =>
                    Memory.ACTION_FIND_MOVEMENT_BY_ID);

                  });

                  return NewMovementEditScreen(movementId: movementId,)  ;
              } else {
                return const HomeScreen();
              }
         }
      ),

      GoRoute(
        path: '${AppRouter.PAGE_CREATE_MOVEMENT_LINE}/:argument',

        builder: (context, state) {
              if(RolesApp.hasStockPrivilege()) {
                MovementAndLines movementAndLines = state.extra as MovementAndLines;
                String argument = jsonEncode(movementAndLines.toJson());

                return MovementLinesCreateScreen(
                    argument: argument,
                    movementAndLines: state.extra as MovementAndLines,
                    width: MemoryProducts.width,
                    );
              } else { return const HomeScreen();}
        }
      ),
      GoRoute(
          path: '${AppRouter.PAGE_SCAN_TOCATOR_TO}/:value',
          builder: (context, state) {
            if(RolesApp.hasStockPrivilege()) {
              String value = state.pathParameters['value'] ?? MovementsScreen.WAIT_FOR_SCAN_MOVEMENT;
              return SearchLocatorScreenFromScan(stringToFind: value,);
            } else { return const HomeScreen();}
          }
      ),
      GoRoute(
          path: AppRouter.PAGE_MOVEMENTS_CONFIRM_SCREEN,
          builder: (context, state) {
            if(RolesApp.hasStockPrivilege()) {

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
          path: AppRouter.PAGE_CREATE_PUT_AWAY_MOVEMENT,
          builder: (context, state) {
            if(RolesApp.hasStockPrivilege()) {
              return MovementsCreateScreen(
                putAwayMovement: state.extra as PutAwayMovement,
              );
            } else { return const HomeScreen();}
          }
      ),
      GoRoute(
        path: '${AppRouter.NEW_PAGE_STORAGE_ON_HANGE}/:productUPC',
        builder: (context, state) {
          if(RolesApp.hasStockPrivilege() ){

            String productUPC = state.pathParameters['productUPC'] ?? '-1';
                Future.delayed(Duration(milliseconds: 50), () {
              ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
              Memory.PAGE_INDEX_STORE_ON_HAND);
              ref.read(actionScanProvider.notifier).update((state) =>
              Memory.ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND);
              ref.read(isDialogShowedProvider.notifier).update((state) => false);
            });
            return ProductForNewMovementScreen(productUPC: productUPC
              );
            } else {
            return const HomeScreen();
          }
        }
      ),
      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_FROM,
        builder: (context, state) => RolesApp.hasStockPrivilege() ?
        SearchLocatorScreen(searchLocatorFrom: true,forCreateLine: false) : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_TO,
        builder: (context, state) => RolesApp.hasStockPrivilege() ?
        SearchLocatorScreen( searchLocatorFrom: false,forCreateLine: false) : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_FROM_FOR_LINE,
        builder: (context, state) => RolesApp.hasStockPrivilege() ?
        SearchLocatorScreen(searchLocatorFrom: true,forCreateLine: true) : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_TO_FOR_LINE,
        builder: (context, state) => RolesApp.hasStockPrivilege() ?
        SearchLocatorScreen( searchLocatorFrom: false,forCreateLine: true) : const HomeScreen(),
      ),

      GoRoute(
        path: AppRouter.PAGE_PRODUCT_SEARCH,
        builder: (context, state) => RolesApp.hasStockPrivilege() ? ProductSearchScreen() : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_PRODUCT_SEARCH_UPDATE_UPC,
        builder: (context, state) => RolesApp.hasStockPrivilege() ?
        ScannerScreen()
        //UpdateProductUpcScreen()
            : const HomeScreen(),
      ),
      GoRoute(
        path: '${AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND}/:productUPC',
        builder: (context, state) {
          {
            if(!RolesApp.hasStockPrivilege()){
              return const HomeScreen();
            }
            final productUPC = state.pathParameters['productUPC'] ?? '';
            Future.delayed(Duration(milliseconds: 50), () {
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
        path: '${AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND_FOR_LINE}/:argument',
        builder: (context, state) {
          {
            if(!RolesApp.hasStockPrivilege()){
              return const HomeScreen();
            }
            //final argument = state.pathParameters['argument'] ?? '';
            MovementAndLines movementAndLines = state.extra as MovementAndLines;
            String argument = jsonEncode(movementAndLines.toJson());
            Future.delayed(Duration(milliseconds: 50), () {
              ref.read(productsHomeCurrentIndexProvider.notifier).update((state) =>
              Memory.PAGE_INDEX_UNSORTED_STORAGE_ON_HAND);
              ref.read(actionScanProvider.notifier).update((state) =>
                  Memory.ACTION_GET_LOCATOR_TO_VALUE);
            });

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
            child: RolesApp.hasStockPrivilege()
                ? UpdateProductUpcScreen3()
                : const HomeScreen(),
            transitionDuration: Duration(seconds: 1),
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






