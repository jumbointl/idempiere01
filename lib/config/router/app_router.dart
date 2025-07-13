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
import '../../features/auth/presentation/screens/auth_data_screen.dart';
import '../../features/products/presentation/screens/search/product_search_screen.dart';
import '../../features/products/presentation/screens/store_on_hand/product_store_on_hand_screen.dart';
import '../../features/products/presentation/screens/update_upc/update_product_upc_screen3.dart';
import '../../features/products/presentation/screens/update_upc/update_product_upc_screen4.dart';


class AppRouter {
  // app routes
  static const String PAGE_UPDATE_PRODUCT_UPC = '/product/updateProductUPC';
  static const String PAGE_HOME = '/home';
  static const String PAGE_PRODUCT_SEARCH = '/product/search';
  static const String PAGE_PRODUCT_STORE_ON_HAND = '/product/storeOnHand';
  static const String PAGE_PRODUCT_SEARCH_UPDATE_UPC = '/product/searchUpdateProductUPC';
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
        builder: (context, state) => RolesApp.hasStockPrivilege() ? ProductStoreOnHandScreen() : const HomeScreen(),
      ),
      ///* MInOut Routes
      /*GoRoute(
        path: '/products/scan',
        builder: (context, state) => RolesApp.hasStockPrivilege()? ProductScreen() : const HomeScreen(),
      ),*/
      GoRoute(
        path: AppRouter.PAGE_PRODUCT_SEARCH,
        builder: (context, state) => RolesApp.hasStockPrivilege() ? ProductSearchScreen() : const HomeScreen(),
      ),
      GoRoute(
        path: AppRouter.PAGE_PRODUCT_SEARCH_UPDATE_UPC,
        builder: (context, state) => RolesApp.hasStockPrivilege() ? UpdateProductUpcScreen4() : const HomeScreen(),
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
            transitionDuration: Duration(milliseconds: 500),
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






