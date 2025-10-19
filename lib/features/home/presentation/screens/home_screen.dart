import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';
import 'package:monalisa_app_001/features/shared/shared.dart';

import '../../../shared/presentation/widgets/side_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MemoryProducts.width =  MediaQuery.of(context).size.width;
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      appBar: AppBar(
        title: const Text('Opciones'),
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
