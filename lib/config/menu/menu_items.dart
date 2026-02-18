import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/m_inout/presentation/providers/m_in_out_providers.dart';
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
    MenuItem(
      title: 'Shipment',
      subTitle: '',
      link: '/mInOut/${MInOutType.shipment.name}',
      icon: Icons.upload,
    ),
  if (RolesApp.appShipmentPrepare)
    MenuItem(
      title: 'Shipment Prepare',
      subTitle: '',
      link: '/mInOut/${MInOutType.shipmentPrepare.name}',
      icon: Icons.upload,
    ),
  if (RolesApp.appShipmentconfirm)
    MenuItem(
      title: 'Shipment Confirm',
      subTitle: '',
      link: '/mInOut/${MInOutType.shipmentConfirm.name}',
      icon: Icons.upload,
    ),
  if (RolesApp.appPickconfirm)
    MenuItem(
      title: 'Pick Confirm',
      subTitle: '',
      link: '/mInOut/${MInOutType.pickConfirm.name}',
      icon: Icons.upload,
    ),
  if (RolesApp.appShipmentCreate)
    MenuItem(
      title: 'Shipment Create',
      subTitle: '',
      link: AppRouter.PAGE_SALES_ORDER_LIST_SCREEN,
      icon: Symbols.event_list,
    ),
  if (RolesApp.appProductUPCUpdate)
  MenuItem(
    title: Messages.SEARCH_PRODUCT,
    subTitle: '',
    link: AppRouter.PAGE_PRODUCT_SEARCH,
    icon: Icons.search,
  ),
  MenuItem(
    title: 'Locator List',
    subTitle: '',
    link: AppRouter.PAGE_SEARCH_LOCATOR_LIST,
    icon: Icons.search,
  ),
  MenuItem(
    title: 'ZPL Template',
    subTitle: '',
    link: AppRouter.PAGE_CREATE_ZPL_TEMPLATE,
    icon: Icons.file_copy,
  ),
];

var appHomeOptionCol2Items = <MenuItem>[
  if (RolesApp.appReceipt)
    MenuItem(
      title: 'Receipt',
      subTitle: '',
      link: '/mInOut/${MInOutType.receipt.name}',
      icon: Icons.download,
    ),
  if (RolesApp.appReceiptconfirm)
    MenuItem(
      title: 'Receipt Confirm',
      subTitle: '',
      link: '/mInOut/${MInOutType.receiptConfirm.name}',
      icon: Icons.download,
    ),
  if (RolesApp.appQaconfirm)
    MenuItem(
      title: 'QA Confirm',
      subTitle: '',
      link: '/mInOut/${MInOutType.qaConfirm.name}',
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
  MenuItem(
    title: 'TEST',
    subTitle: '',
    link: '/test',
    icon: Icons.question_answer
    ,
  ),

];

final appHomeOptionCol3Items = <MenuItem>[
  if (RolesApp.appMovementComplete)
  MenuItem(
    title: 'Move Complete',
    subTitle: '',
    link: '/mInOut/${MInOutType.move.name}',
    icon: Icons.swap_horiz,

  ),
  if (RolesApp.appMovementconfirmComplete)
  MenuItem(
    title: 'Move Confirm',
    subTitle: '',
    link: '/mInOut/${MInOutType.moveConfirm.name}',
    icon: Icons.swap_horiz,
  ),
  if (RolesApp.appMovementComplete)
    MenuItem(
      title: ' PutAway',
      subTitle: '',
      link: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/${ProductStoreOnHandScreen.MOVEMENT_IN_SAME_WAREHOUSE}',
      icon: Icons.arrow_forward,
    ),
  if (RolesApp.appMovementconfirmComplete)
  MenuItem(
    title: 'Replenish',
    subTitle: '',
    link: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/-1',
    icon: Icons.arrow_forward,
  ),

  if (RolesApp.appMovementconfirmComplete)
  MenuItem(
    title: 'Delivery Note Fiscal',
    subTitle: '',
    link: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/${ProductStoreOnHandScreen.MOVEMENT_DELIVERY_NOTE}',
    icon: Icons.arrow_forward,
  ),

  if (RolesApp.appMovementComplete)
    MenuItem(
      title: Messages.STORE_ON_HAND,
      subTitle: '',
      link: '${AppRouter.PAGE_PRODUCT_STORE_ON_HAND}/${ProductStoreOnHandScreen.READ_STOCK_ONLY}',
      icon: Icons.inventory,
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
