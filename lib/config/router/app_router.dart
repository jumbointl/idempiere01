import 'package:flutter_addons/flutter_addons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/config/router/app_router_notifier.dart';
import 'package:monalisa_app_001/features/auth/auth.dart';
import 'package:monalisa_app_001/features/auth/presentation/providers/auth_provider.dart';
import 'package:monalisa_app_001/features/home/presentation/screens/home_screen.dart';
import 'package:monalisa_app_001/features/m_inout/presentation/screens/m_in_out_screen.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import '../../features/auth/presentation/screens/auth_data_screen.dart';
import '../../features/products/presentation/providers/products_scan_notifier.dart';
import '../../features/products/presentation/screens/locator/search_locator_screen.dart';
import '../../features/products/presentation/screens/movement/movements_screen.dart';
import '../../features/products/presentation/screens/search/product_search_screen.dart';
import '../../features/products/presentation/screens/store_on_hand/product_store_on_hand_screen.dart';
import '../../features/products/presentation/screens/store_on_hand/product_store_on_hand_screen2.dart';
import '../../features/products/presentation/screens/store_on_hand/select_locator_screen.dart';
import '../../features/products/presentation/screens/store_on_hand/unsorted_storage_on__hand_screen.dart';
import '../../features/products/presentation/screens/update_upc/update_product_upc_screen3.dart';
import '../../features/products/presentation/screens/update_upc/update_product_upc_screen4.dart';
import '../../src/core/routes/route_export.dart';


class AppRouter {
  // app routes
  static const String PAGE_UPDATE_PRODUCT_UPC = '/product/updateProductUPC';
  static const String PAGE_HOME = '/home';
  static const String PAGE_PRODUCT_SEARCH = '/product/search';
  static const String PAGE_PRODUCT_STORE_ON_HAND = '/product/storeOnHand';
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
  static const String PAGE_MOVEMENTS_HOME = '/movement';
  //static const String PAGE_SELECT_LOCATOR = '/movement/selectLocator';
  static const String PAGE_CREATE_MOVEMENT_LINE = '/product/unsortedStorageOnHand/createMovementLine';
  static const String PAGE_MOVEMENTS_SEARCH = '/movement_search/:movementId';
  static String PAGE_MOVEMENTS_SEARCH_WITH_PARAMS(String movementId) {
   return PAGE_MOVEMENTS_SEARCH.replaceAll(':movementId', movementId);
  }
  static const String PAGE_SEARCH_LOCATOR_FROM = '/product/movement/createMovement/searchLocatorFrom';
  static const String PAGE_SEARCH_LOCATOR_TO = '/product/movement/createMovement/searchLocatorTo';
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
        path: AppRouter.PAGE_PRODUCT_STORE_ON_HAND,
        builder: (context, state){
            if( RolesApp.hasStockPrivilege()){

              return ProductStoreOnHandScreen();

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
      /*GoRoute(
        path: AppRouter.PAGE_SELECT_LOCATOR,
        builder: (context, state) => RolesApp.hasStockPrivilege() ?
        MovementCreateScreen(storage: MemoryProducts.storage,
          notifier:state.extra as ProductsScanNotifier, width: MemoryProducts.width,)
            : const HomeScreen(),
      ),*/
      GoRoute(
        path: AppRouter.PAGE_MOVEMENTS_SEARCH,
        builder: (context,GoRouterState state) {
          String movementId = state.pathParameters['movementId'] ?? MovementsScreen.WAIT_FOR_SCAN_MOVEMENT;

              if(RolesApp.hasStockPrivilege()) {
                  if(movementId==':movementId'){
                    movementId = MovementsScreen.WAIT_FOR_SCAN_MOVEMENT;
                  }
                  //print('movementId: $movementId');

                  return MovementsScreen(movementId: movementId)  ;
              } else {
                return const HomeScreen();
              }
         }
      ),
      GoRoute(
        path: AppRouter.PAGE_CREATE_MOVEMENT_LINE,
        builder: (context, state) {
              if(RolesApp.hasStockPrivilege()) {
                return SelectLocatorScreen(index: MemoryProducts.index, storage: MemoryProducts.storage,
                  notifier:state.extra as ProductsScanNotifier, width: MemoryProducts.width);
              } else { return const HomeScreen();}
        }
      ),
      GoRoute(
        path: AppRouter.PAGE_MOVEMENTS_HOME,
        builder: (context, state) {
          if(RolesApp.hasStockPrivilege() ){
            return ResponsiveScope(
              enableDebugLogging: false,
              screenLock: AppOrientationLock.portraitUp,
              errorScreen: ErrorScreen.blueCrash,
              designFrame: Frame(width: 390, height: 844),
              scaleMode: ScaleMode.design,
              layoutBuilder: (layout) {
              return ProductStoreOnHandScreen();
              //return MovementsHomePage();
              },
            );} else {
            return const HomeScreen();
          }
        }
      ),
      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_FROM,
        builder: (context, state) => RolesApp.hasStockPrivilege() ?
        SearchLocatorScreen(searchLocatorFrom: true,) : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_SEARCH_LOCATOR_TO,
        builder: (context, state) => RolesApp.hasStockPrivilege() ?
        SearchLocatorScreen( searchLocatorFrom: false,) : const HomeScreen(),
      ),

      GoRoute(
        path: AppRouter.PAGE_PRODUCT_SEARCH,
        builder: (context, state) => RolesApp.hasStockPrivilege() ? ProductSearchScreen() : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_PRODUCT_SEARCH_UPDATE_UPC,
        builder: (context, state) => RolesApp.hasStockPrivilege() ? UpdateProductUpcScreen4() : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_UNSORTED_STORAGE_ON_HAND,
        builder: (context, state) {
          {
            if(!RolesApp.hasStockPrivilege()){
              return const HomeScreen();
            }
            return UnsortedStorageOnHandScreen(notifier: state.extra as ProductsScanNotifier,index:MemoryProducts.index, storage: MemoryProducts.storage,width: MemoryProducts.width,);
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






