import 'package:monalisa_app_001/features/auth/domain/entities/role.dart';

import 'environment.dart';

class RolesApp {
  static final Map<String, bool> _roles = {

    // SHIPMENT
    'APP_SHIPMENT': false,
    'APP_SHIPMENT_QTY': false,
    'APP_SHIPMENT_MANUAL': false,
    'APP_SHIPMENT_LOWQTY': false,
    'APP_SHIPMENT_PREPARE': false,
    'APP_SHIPMENT_COMPLETE': false,

    // RECEIPT
    'APP_RECEIPT': false,
    'APP_RECEIPT_QTY': false,
    'APP_RECEIPT_MANUAL': false,
    'APP_RECEIPT_PREPARE': false,
    'APP_RECEIPT_COMPLETE': false,

    // SHIPMENT CONFIRM
    'APP_SHIPMENTCONFIRM': false,
    'APP_SHIPMENTCONFIRM_QTY': false,
    'APP_SHIPMENTCONFIRM_MANUAL': false,
    'APP_SHIPMENTCONFIRM_COMPLETE': false,

    // RECEIPT CONFIRM
    'APP_RECEIPTCONFIRM': false,
    'APP_RECEIPTCONFIRM_QTY': false,
    'APP_RECEIPTCONFIRM_MANUAL': false,
    'APP_RECEIPTCONFIRM_COMPLETE': false,

    // PICK CONFIRM
    'APP_PICKCONFIRM': false,
    'APP_PICKCONFIRM_QTY': false,
    'APP_PICKCONFIRM_MANUAL': false,
    'APP_PICKCONFIRM_COMPLETE': false,

    // QA CONFIRM
    'APP_QACONFIRM': false,
    'APP_QACONFIRM_QTY': false,
    'APP_QACONFIRM_MANUAL': false,
    'APP_QACONFIRM_COMPLETE': false,

    // MOVEMENT
    'APP_MOVEMENT': false,
    'APP_MOVEMENT_COMPLETE': false,

    // MOVEMENT CONFIRM
    'APP_MOVEMENTCONFIRM': false,
    'APP_MOVEMENTCONFIRM_COMPLETE': false,

    // INVENTORY
    'APP_INVENTORY': false,
    'APP_INVENTORY_QTY': false,
    'APP_INVENTORY_COMPLETE': false,
    //STOCK
    'APP_STOCK': false,
  };

  // SHIPMENT
  static bool get appShipment => _roles['APP_SHIPMENT']!;
  static bool get appShipmentQty => _roles['APP_SHIPMENT_QTY']!;
  static bool get appShipmentManual => _roles['APP_SHIPMENT_MANUAL']!;
  static bool get appShipmentLowqty => _roles['APP_SHIPMENT_LOWQTY']!;
  static bool get appShipmentPrepare => _roles['APP_SHIPMENT_PREPARE']!;
  static bool get appShipmentComplete => _roles['APP_SHIPMENT_COMPLETE']!;

  // RECEIPT
  static bool get appReceipt => _roles['APP_RECEIPT']!;
  static bool get appReceiptQty => _roles['APP_RECEIPT_QTY']!;
  static bool get appReceiptManual => _roles['APP_RECEIPT_MANUAL']!;
  static bool get appReceiptPrepare => _roles['APP_RECEIPT_PREPARE']!;
  static bool get appReceiptComplete => _roles['APP_RECEIPT_COMPLETE']!;

  // SHIPMENT CONFIRM
  static bool get appShipmentconfirm => _roles['APP_SHIPMENTCONFIRM']!;
  static bool get appShipmentconfirmQty => _roles['APP_SHIPMENTCONFIRM_QTY']!;
  static bool get appShipmentconfirmManual => _roles['APP_SHIPMENTCONFIRM_MANUAL']!;
  static bool get appShipmentconfirmComplete => _roles['APP_SHIPMENTCONFIRM_COMPLETE']!;

  // RECEIPT CONFIRM
  static bool get appReceiptconfirm => _roles['APP_RECEIPTCONFIRM']!;
  static bool get appReceiptconfirmQty => _roles['APP_RECEIPTCONFIRM_QTY']!;
  static bool get appReceiptconfirmManual => _roles['APP_RECEIPTCONFIRM_MANUAL']!;
  static bool get appReceiptconfirmComplete => _roles['APP_RECEIPTCONFIRM_COMPLETE']!;

  // PICK CONFIRM
  static bool get appPickconfirm => _roles['APP_PICKCONFIRM']!;
  static bool get appPickconfirmQty => _roles['APP_PICKCONFIRM_QTY']!;
  static bool get appPickconfirmManual => _roles['APP_PICKCONFIRM_MANUAL']!;
  static bool get appPickconfirmComplete => _roles['APP_PICKCONFIRM_COMPLETE']!;

  // QA CONFIRM
  static bool get appQaconfirm => _roles['APP_QACONFIRM']!;
  static bool get appQaconfirmQty => _roles['APP_QACONFIRM_QTY']!;
  static bool get appQaconfirmManual => _roles['APP_QACONFIRM_MANUAL']!;
  static bool get appQaconfirmComplete => _roles['APP_QACONFIRM_COMPLETE']!;

  // MOVEMENT
  static bool get appMovement => _roles['APP_MOVEMENT']!;
  static bool get appMovementComplete => _roles['APP_MOVEMENT_COMPLETE']!;

  // MOVEMENT CONFIRM
  static bool get appMovementconfirm => _roles['APP_MOVEMENTCONFIRM']!;
  static bool get appMovementconfirmComplete => _roles['APP_MOVEMENTCONFIRM_COMPLETE']!;

  // INVENTORY
  static bool get appInventory => _roles['APP_INVENTORY']!;
  static bool get appInventoryQty => _roles['APP_INVENTORY_QTY']!;
  static bool get appInventoryComplete => _roles['APP_INVENTORY_COMPLETE']!;
  //STOCK
  static bool get appStock => _roles['APP_STOCK']!;

  static void set(List<Role> roles) {
    for (var role in roles) {
      _roles[role.name.toUpperCase()] = true;
    }
  }

  static String getString() {
    return 'RolesApp{${_roles.entries.map((e) => '${e.key}: ${e.value}').join(', ')}}';
  }
  static bool hasStockPrivilege() {
    if(Environment.apiUrl.contains('idempiere-api')){
      return true;
    }
    return  RolesApp.appStock ;
  }

}
