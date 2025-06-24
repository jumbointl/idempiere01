import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SideMenu extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const SideMenu({super.key, required this.scaffoldKey});

  @override
  SideMenuState createState() => SideMenuState();
}

class SideMenuState extends ConsumerState<SideMenu> {
  int navDrawerIndex = 0;
  String _selectedItem = 'Inicio';

  @override
  Widget build(BuildContext context) {
    final hasNotch = MediaQuery.of(context).viewPadding.top > 35;
    final authDataState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return NavigationDrawer(
      elevation: 1,
      selectedIndex: navDrawerIndex,
      backgroundColor: themeBackgroundColor,
      onDestinationSelected: (value) {
        setState(() {
          navDrawerIndex = value;
        });
        final menuItem = appMenuItems[value];
        context.push(menuItem.link);
        widget.scaffoldKey.currentState?.closeDrawer();
      },
      children: [
        Padding(
          padding: EdgeInsets.only(top: hasNotch ? 30 : 20),
          child: SizedBox(
            width: double.infinity,
            child: Image.asset(
              'assets/images/logo-monalisa.jpg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Divider(),
        ),
        ...appMenuItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 10),
            child: ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              onTap: () {
                setState(() {
                  _selectedItem = item.title;
                });
                if (item.link == '/authData') {
                  ref.read(authProvider.notifier).loadAuthData();
                } else if (item.link == '/logout') {
                  ref.read(authProvider.notifier).logout();
                } else {
                  context.push(item.link);
                }
                widget.scaffoldKey.currentState?.closeDrawer();
              },
              selected: _selectedItem == item.title,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Divider(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(25, 0, 25, 20),
          child: RichText(
            text: TextSpan(
              text: '',
              style: TextStyle(
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: authDataState.authInfo ?? '',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: size.height - 400,
          alignment: Alignment.bottomCenter,
          child: Text(
            'Versión: 1.0.4',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
