import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/shared/shared.dart';

import '../../../auth/presentation/screens/exit_app.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/presentation/widgets/side_menu.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // lee el valor (state) para mostrarlo en el bottom bar
    final functionText = ref.watch(homeScreenTitleProvider);
    // si SideMenu necesita controlar el Scaffold, dale la key al Scaffold también
    final scaffoldKey = GlobalKey<ScaffoldState>();
    DateTime? lastPressed;
    // ancho útil en memoria (si usas esto en otros lados)
    MemoryProducts.width = MediaQuery.of(context).size.width;

    return Scaffold(
      key: scaffoldKey,
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      appBar: AppBar(
        title: Text(functionText),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              exitApp(context, ref);
            },
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop,result){
          if (didPop) {
            return;
          }
          exitApp(context,ref);


        },
        child: const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: _HomeColumns(),
          ),
        ),
      ),
    );
  }


}

class _HomeColumns extends StatelessWidget {
  const _HomeColumns();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: ListView.builder(
            itemCount: appHomeOptionCol1Items.length,
            itemBuilder: (context, index) {
              final menuHomeOption = appHomeOptionCol1Items[index];
              return HomeOption(
                title: menuHomeOption.title,
                icon: menuHomeOption.icon,
                onTap: () => context.push(menuHomeOption.link),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: ListView.builder(
            itemCount: appHomeOptionCol2Items.length,
            itemBuilder: (context, index) {

              final menuHomeOption = appHomeOptionCol2Items[index];
              return HomeOption(
                title: menuHomeOption.title,
                icon: menuHomeOption.icon,
                onTap: () => context.push(menuHomeOption.link),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: ListView.builder(
            itemCount: appHomeOptionCol3Items.length,
            itemBuilder: (context, index) {
              final menuHomeOption = appHomeOptionCol3Items[index];
              return HomeOption(
                title: menuHomeOption.title,
                icon: menuHomeOption.icon,
                onTap: () => context.push(menuHomeOption.link),
              );
            },
          ),
        ),
      ],
    );
  }
}

final homeScreenTitleProvider = StateProvider.autoDispose<String>((ref) => 'Opciones ${Memory.VERSIONS}');



/*
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final function = ref.watch(actualFunctionProvider.notifier);
    MemoryProducts.width =  MediaQuery.of(context).size.width;
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      appBar: AppBar(
        title: Text('Opciones ${Memory.VERSIONS}'),
      ),
      bottomNavigationBar: BottomAppBar(
         child: Text(function.state),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: ListView.builder(
                  itemCount: appHomeOptionCol1Items.length,
                  itemBuilder: (context, index) {
                    final menuHomeOption = appHomeOptionCol1Items[index];
                    return HomeOption(
                      title: menuHomeOption.title,
                      icon: menuHomeOption.icon,
                      onTap: () {
                        context.push(menuHomeOption.link);
                      },
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: ListView.builder(
                  itemCount: appHomeOptionCol2Items.length,
                  itemBuilder: (context, index) {
                    final menuHomeOption = appHomeOptionCol2Items[index];
                    return HomeOption(
                      title: menuHomeOption.title,
                      icon: menuHomeOption.icon,
                      onTap: () {
                        context.push(menuHomeOption.link);
                      },
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: ListView.builder(
                  itemCount: appHomeOptionCol3Items.length,
                  itemBuilder: (context, index) {
                    final menuHomeOption = appHomeOptionCol3Items[index];
                    return HomeOption(
                      title: menuHomeOption.title,
                      icon: menuHomeOption.icon,
                      onTap: () {
                        context.push(menuHomeOption.link);
                      },
                    );
                  },
                ),
              ),
              // SizedBox(width: 8),
              // Expanded(
              //   child: ListView.builder(
              //     itemCount: appHomeOptionCol3Items.length,
              //     itemBuilder: (context, index) {
              //       final menuHomeOption = appHomeOptionCol3Items[index];
              //       return HomeOption(
              //         title: menuHomeOption.title,
              //         icon: menuHomeOption.icon,
              //         onTap: () {
              //           context.push(menuHomeOption.link);
              //         },
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }


}
final actualFunctionProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});*/
