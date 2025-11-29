import 'package:flutter/material.dart';

import '../../features/shared/data/messages.dart';
import '../constants/roles_app.dart';
import '../router/app_router.dart';

class MenuItem {
  final String title;
  final String subTitle;
  final String link;
  final IconData icon;

  const MenuItem(
      {required this.title,
      required this.subTitle,
      required this.link,
      required this.icon});
}

const appMenuItems = <MenuItem>[
  MenuItem(
      title: 'Cambiar Rol',
      subTitle: '',
      link: '/authData',
      icon: Icons.assignment_ind_rounded),
  MenuItem(
      title: 'Cerrar Sesión',
      subTitle: '',
      link: '/logout',
      icon: Icons.logout_outlined),
];

var appHomeOptionCol1Items = <MenuItem>[
  if (RolesApp.appShipment)
    const MenuItem(
      title: 'Shipment',
      subTitle: '',
      link: '/mInOut/shipment',
      icon: Icons.upload,
    ),
  if (RolesApp.appShipmentconfirm)
    const MenuItem(
      title: 'Shipment Confirm',
      subTitle: '',
      link: '/mInOut/shipmentconfirm',
      icon: Icons.upload,
    ),
  if (RolesApp.appShipmentconfirm)
    const MenuItem(
      title: 'Pick Confirm',
      subTitle: '',
      link: '/mInOut/pickconfirm',
      icon: Icons.upload,
    ),
];

var appHomeOptionCol2Items = <MenuItem>[
  if (RolesApp.appReceipt)
    const MenuItem(
      title: 'Receipt',
      subTitle: '',
      link: '/mInOut/receipt',
      icon: Icons.download,
    ),
  if (RolesApp.appReceiptconfirm)
    const MenuItem(
      title: 'Receipt Confirm',
      subTitle: '',
      link: '/mInOut/receiptconfirm',
      icon: Icons.download,
    ),
  if (RolesApp.appReceiptconfirm)
    const MenuItem(
      title: 'QA Confirm',
      subTitle: '',
      link: '/mInOut/qaconfirm',
      icon: Icons.download,
    ),
];

final appHomeOptionCol3Items = <MenuItem>[
  const MenuItem(
    title: 'Inventory Move',
    subTitle: '',
    link: '/mInOut/move',
    icon: Icons.swap_horiz,

  ),
  const MenuItem(
    title: 'Move Confirm',
    subTitle: '',
    link: '/mInOut/moveconfirm',
    icon: Icons.swap_horiz,
  ),
  MenuItem(
    title: Messages.MOVEMENT_LIST_DR,
    subTitle: '',
    link: AppRouter.PAGE_MOVEMENTS_LIST,
    icon: Icons.list
    ,
  ),
  MenuItem(
    title: Messages.MOVEMENT_CREATE,
    subTitle: '',
    link: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/-1',
    icon: Icons.inventory,
  ),

  MenuItem(
    title: Messages.MOVEMENT_EDIT,
    subTitle: '',
    link: '${AppRouter.PAGE_MOVEMENTS_SEARCH}/:movementId',
    icon: Icons.move_up
    ,
  ),
  /*MenuItem(
    title: Messages.ADD_UPC,
    subTitle: '',
    link: AppRouter.PAGE_PRODUCT_SEARCH_UPDATE_UPC,
    icon: Icons.search,
  ),

   */
  MenuItem(
    title: Messages.SEARCH_PRODUCT,
    subTitle: '',
    link: AppRouter.PAGE_PRODUCT_SEARCH,
    icon: Icons.search,
  ),
];

const appTemplateMenuItems = <MenuItem>[
  MenuItem(
      title: 'Botones',
      subTitle: 'Varios Botones en Flutter',
      link: '/templateButtons',
      icon: Icons.smart_button_outlined),
  MenuItem(
      title: 'Tarjetas',
      subTitle: 'Un contenedor estilizado',
      link: '/templateCards',
      icon: Icons.credit_card),
];
