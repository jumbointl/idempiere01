import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/products/presentation/screens/store_on_hand/product_store_on_hand_screen.dart';
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
  if (RolesApp.appShipmentconfirm)
    MenuItem(
      title: 'InOut Conf Generate',
      subTitle: '',
      link: AppRouter.PAGE_M_IN_OUT_LIST_SCREEN,
      icon: Symbols.event_list,
    ),
  if (RolesApp.canUpdateProductUPC)
  MenuItem(
    title: Messages.SEARCH_PRODUCT,
    subTitle: '',
    link: AppRouter.PAGE_PRODUCT_SEARCH,
    icon: Icons.search,
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
  if (RolesApp.canEditMovement || RolesApp.canSearchMovement)
    MenuItem(
      title: Messages.TITLE_MOVEMENT_LIST,
      subTitle: '',
      link: '${AppRouter.PAGE_MOVEMENTS_LIST}/-1',
      icon: Icons.list
      ,
    ),
  if (RolesApp.canEditMovement)
    MenuItem(
      title: Messages.MOVEMENT_EDIT,
      subTitle: '',
      link: '${AppRouter.PAGE_MOVEMENTS_EDIT}/-1/-1',
      icon: Icons.move_up
      ,
    ),
];

final appHomeOptionCol3Items = <MenuItem>[
  if (RolesApp.cantConfirmMovement)
  const MenuItem(
    title: 'Move Complete',
    subTitle: '',
    link: '/mInOut/move',
    icon: Icons.swap_horiz,

  ),
  if (RolesApp.canConfirmMovementWithConfirm)
  const MenuItem(
    title: 'Move Confirm',
    subTitle: '',
    link: '/mInOut/moveconfirm',
    icon: Icons.swap_horiz,
  ),
  if (RolesApp.canCreateMovementInSameWarehouse)
    MenuItem(
      title: ' PutAway',
      subTitle: '',
      link: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/-1/movementInSameWarehouse',
      icon: Icons.arrow_forward,
    ),
  if (RolesApp.canCreateMovementInSameOrganization)
  MenuItem(
    title: 'Replenish',
    subTitle: '',
    link: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/-1',
    icon: Icons.arrow_forward,
  ),
  if (RolesApp.showProductSearchScreen)
    MenuItem(
      title: Messages.STORE_ON_HAND,
      subTitle: '',
      link: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/${ProductStoreOnHandScreen.READ_STOCK_ONLY}',
      icon: Icons.inventory,
    ),
  if (RolesApp.canCreateDeliveryNote)
  MenuItem(
    title: 'Delivery Note Fiscal',
    subTitle: '',
    link: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/${ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE}',
    icon: Icons.arrow_forward,
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
