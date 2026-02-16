import 'package:monalisa_app_001/features/auth/domain/entities/role.dart';


class RolesApp {
  static final Map<String, bool> _roles = {

    // SHIPMENT
    'APP_SHIPMENT': false,
    'APP_SHIPMENT_QTY': false,
    'APP_SHIPMENT_MANUAL': false,
    'APP_SHIPMENT_LOWQTY': false,
    'APP_SHIPMENT_PREPARE': false,
    'APP_SHIPMENT_COMPLETE': false,
    'APP_SHIPMENT_QCOMPLETE': true,

    // RECEIPT
    'APP_RECEIPT': false,
    'APP_RECEIPT_QTY': false,
    'APP_RECEIPT_MANUAL': false,
    'APP_RECEIPT_PREPARE': false,
    'APP_RECEIPT_COMPLETE': false,
    'APP_RECEIPT_QCOMPLETE': false,

    // SHIPMENT CONFIRM
    'APP_SHIPMENTCONFIRM': false,
    'APP_SHIPMENTCONFIRM_QTY': false,
    'APP_SHIPMENTCONFIRM_MANUAL': false,
    'APP_SHIPMENTCONFIRM_COMPLETE': false,
    'APP_SHIPMENTCONFIRM_QCOMPLETE': true,
    'APP_SHIPMENTCONFIRM_CREATE': true,

    // RECEIPT CONFIRM
    'APP_RECEIPTCONFIRM': false,
    'APP_RECEIPTCONFIRM_QTY': false,
    'APP_RECEIPTCONFIRM_MANUAL': false,
    'APP_RECEIPTCONFIRM_COMPLETE': false,
    'APP_RECEIPTCONFIRM_QCOMPLETE': false,

    // PICK CONFIRM
    'APP_PICKCONFIRM': false,
    'APP_PICKCONFIRM_QTY': false,
    'APP_PICKCONFIRM_MANUAL': false,
    'APP_PICKCONFIRM_COMPLETE': false,
    'APP_PICKCONFIRM_QCOMPLETE': true,

    // QA CONFIRM
    'APP_QACONFIRM': false,
    'APP_QACONFIRM_QTY': false,
    'APP_QACONFIRM_MANUAL': false,
    'APP_QACONFIRM_COMPLETE': false,
    'APP_QACONFIRM_QCOMPLETE': false,

    // MOVEMENT
    'APP_MOVEMENT': false,
    'APP_MOVEMENT_COMPLETE': false,
    'APP_MOVEMENT_QCOMPLETE': false,

    // MOVEMENT CONFIRM
    'APP_MOVEMENTCONFIRM': false,
    'APP_MOVEMENTCONFIRM_COMPLETE': false,
    'APP_MOVEMENTCONFIRM_QCOMPLETE': false,

    // INVENTORY
    'APP_INVENTORY': false,
    'APP_INVENTORY_QTY': false,
    'APP_INVENTORY_COMPLETE': false,
    'APP_INVENTORY_QCOMPLETE': false,
    //STOCK
    'APP_STOCK': false,
    //PRODUCTUPC
    'APP_PRODUCTUPC_UPDATE': false,
  };



  // SHIPMENT
  static bool get appShipment => _roles['APP_SHIPMENT'] ?? false;
  static bool get appShipmentQty => _roles['APP_SHIPMENT_QTY'] ?? false;
  static bool get appShipmentManual => _roles['APP_SHIPMENT_MANUAL'] ?? false;
  static bool get appShipmentLowQty => _roles['APP_SHIPMENT_LOWQTY'] ?? false;
  static bool get appShipmentOverQty => _roles['APP_SHIPMENT_OVERQTY'] ?? false;
  static bool get appShipmentPrepare => _roles['APP_SHIPMENT_PREPARE'] ?? false;
  static bool get appShipmentComplete => _roles['APP_SHIPMENT_COMPLETE'] ?? false;
  static bool get appShipmentQuickComplete => _roles['APP_SHIPMENT_QCOMPLETE'] ?? true ; //false;
  static bool get appShipmentCreate => true; // _roles['APP_SHIPMENT_CREATE'] ?? false;


  // RECEIPT
  static bool get appReceipt => _roles['APP_RECEIPT'] ?? false;
  static bool get appReceiptQty => _roles['APP_RECEIPT_QTY'] ?? false;
  static bool get appReceiptManual => _roles['APP_RECEIPT_MANUAL'] ?? false;
  static bool get appReceiptPrepare => _roles['APP_RECEIPT_PREPARE'] ?? false;
  static bool get appReceiptComplete => _roles['APP_RECEIPT_COMPLETE'] ?? false;
  static bool get appReceiptQuickComplete => _roles['APP_RECEIPT_QCOMPLETE'] ?? false;


  // SHIPMENT CONFIRM
  static bool get appShipmentconfirm => _roles['APP_SHIPMENTCONFIRM'] ?? false;
  static bool get appShipmentconfirmQty => _roles['APP_SHIPMENTCONFIRM_QTY'] ?? false;
  static bool get appShipmentconfirmManual => _roles['APP_SHIPMENTCONFIRM_MANUAL'] ?? false;
  static bool get appShipmentconfirmComplete => _roles['APP_SHIPMENTCONFIRM_COMPLETE'] ?? false;
  static bool get appShipmentconfirmQuickComplete => _roles['APP_SHIPMENTCONFIRM_QCOMPLETE'] ?? false;

  // RECEIPT CONFIRM
  static bool get appReceiptconfirm => _roles['APP_RECEIPTCONFIRM'] ?? false;
  static bool get appReceiptconfirmQty => _roles['APP_RECEIPTCONFIRM_QTY'] ?? false;
  static bool get appReceiptconfirmManual => _roles['APP_RECEIPTCONFIRM_MANUAL'] ?? false;
  static bool get appReceiptconfirmComplete => _roles['APP_RECEIPTCONFIRM_COMPLETE'] ?? false;
  static bool get appReceiptconfirmQuickComplete => _roles['APP_RECEIPTCONFIRM_QCOMPLETE'] ?? false;

  // PICK CONFIRM
  static bool get appPickconfirm => _roles['APP_PICKCONFIRM'] ?? false;
  static bool get appPickconfirmQty => _roles['APP_PICKCONFIRM_QTY'] ?? false;
  static bool get appPickconfirmManual => _roles['APP_PICKCONFIRM_MANUAL'] ?? false;
  static bool get appPickconfirmComplete => _roles['APP_PICKCONFIRM_COMPLETE'] ?? false;
  static bool get appPickconfirmQuickComplete => _roles['APP_PICKCONFIRM_QCOMPLETE'] ?? false;

  // QA CONFIRM
  static bool get appQaconfirm => _roles['APP_QACONFIRM'] ?? false;
  static bool get appQaconfirmQty => _roles['APP_QACONFIRM_QTY'] ?? false;
  static bool get appQaconfirmManual => _roles['APP_QACONFIRM_MANUAL'] ?? false;
  static bool get appQaconfirmComplete => _roles['APP_QACONFIRM_COMPLETE'] ?? false;
  static bool get appQaconfirmQuickComplete => _roles['APP_QACONFIRM_QCOMPLETE'] ?? false;

  // MOVEMENT
  static bool get appMovement => _roles['APP_MOVEMENT'] ?? false;
  static bool get appMovementComplete => _roles['APP_MOVEMENT_COMPLETE'] ?? false;
  static bool get appMovementQuickComplete => _roles['APP_MOVEMENT_QCOMPLETE'] ?? false;

  // MOVEMENT CONFIRM
  static bool get appMovementconfirm => _roles['APP_MOVEMENTCONFIRM'] ?? false;
  static bool get appMovementconfirmCreate => _roles['APP_MOVEMENTCONFIRM_CREATE'] ?? false;
  static bool get appMovementconfirmComplete => _roles['APP_MOVEMENTCONFIRM_COMPLETE'] ?? false;
  static bool get appMovementconfirmQuickComplete => _roles['APP_MOVEMENTCONFIRM_QCOMPLETE'] ?? false;

  // INVENTORY
  static bool get appInventory => _roles['APP_INVENTORY'] ?? false;
  static bool get appInventoryQty => _roles['APP_INVENTORY_QTY'] ?? false;
  static bool get appInventoryComplete => _roles['APP_INVENTORY_COMPLETE'] ?? false;
  static bool get appInventoryQuickComplete => _roles['APP_INVENTORY_QCOMPLETE'] ?? false;
  //STOCK
  static bool get appStock => _roles['APP_STOCK'] ?? false;
  //PRODUCTUPC
  static bool get appProductUPCUpdate => _roles['APP_PRODUCTUPC_UPDATE'] ?? false;


  static void set(List<Role> roles) {
    for (var role in roles) {
      _roles[role.name.toUpperCase()] = true;
    }
  }

  static String getString() {
    return 'RolesApp{${_roles.entries.map((e) => '${e.key}: ${e.value}').join(', ')}}';
  }
  static bool get hasStockPrivilege {
    return appStock;
  }
  static bool get canSearchProductStock {
    return RolesApp.appStock ;
  }

  static bool get canEditMovement {
    bool b = appMovementComplete || appMovementconfirmComplete;
    if(b) return true ;
    return  false ;
  }

  static bool get canSearchMovement {
    bool b =(appMovementComplete || appMovementconfirmComplete);
    if(b) return b;
    return appMovement;
  }

  static bool get showProductSearchScreen {
    if(appMovementComplete || appMovementconfirmComplete){
      return false ;
    }
    return canSearchProductStock ;
  }






}
