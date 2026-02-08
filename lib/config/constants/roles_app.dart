import 'package:monalisa_app_001/features/auth/domain/entities/role.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';


class RolesApp {
  //To do set to false in production
  static bool isTestMode = Memory.isTestMode ;
  static final Map<String, bool> _roles = {

    // SHIPMENT
    'APP_SHIPMENT': false,
    'APP_SHIPMENT_QTY': false,
    'APP_SHIPMENT_MANUAL': false,
    'APP_SHIPMENT_LOWQTY': false,
    'APP_SHIPMENT_PREPARE': false,
    'APP_SHIPMENT_COMPLETE': false,
    'APP_SHIPMENT_QCOMPLETE': isTestMode,

    // RECEIPT
    'APP_RECEIPT': false,
    'APP_RECEIPT_QTY': false,
    'APP_RECEIPT_MANUAL': false,
    'APP_RECEIPT_PREPARE': false,
    'APP_RECEIPT_COMPLETE': false,
    'APP_RECEIPT_QCOMPLETE': isTestMode,

    // SHIPMENT CONFIRM
    'APP_SHIPMENTCONFIRM': false,
    'APP_SHIPMENTCONFIRM_QTY': false,
    'APP_SHIPMENTCONFIRM_MANUAL': false,
    'APP_SHIPMENTCONFIRM_COMPLETE': false,
    'APP_SHIPMENTCONFIRM_QCOMPLETE': isTestMode,

    // RECEIPT CONFIRM
    'APP_RECEIPTCONFIRM': false,
    'APP_RECEIPTCONFIRM_QTY': false,
    'APP_RECEIPTCONFIRM_MANUAL': false,
    'APP_RECEIPTCONFIRM_COMPLETE': false,
    'APP_RECEIPTCONFIRM_QCOMPLETE': isTestMode,

    // PICK CONFIRM
    'APP_PICKCONFIRM': false,
    'APP_PICKCONFIRM_QTY': false,
    'APP_PICKCONFIRM_MANUAL': false,
    'APP_PICKCONFIRM_COMPLETE': false,
    'APP_PICKCONFIRM_QCOMPLETE': isTestMode,

    // QA CONFIRM
    'APP_QACONFIRM': false,
    'APP_QACONFIRM_QTY': false,
    'APP_QACONFIRM_MANUAL': false,
    'APP_QACONFIRM_COMPLETE': false,
    'APP_QACONFIRM_QCOMPLETE': isTestMode,

    // MOVEMENT
    'APP_MOVEMENT': false,
    'APP_MOVEMENT_COMPLETE': false,
    'APP_MOVEMENT_QCOMPLETE': isTestMode,

    // MOVEMENT CONFIRM
    'APP_MOVEMENTCONFIRM': false,
    'APP_MOVEMENTCONFIRM_COMPLETE': false,
    'APP_MOVEMENTCONFIRM_QCOMPLETE': isTestMode,

    // INVENTORY
    'APP_INVENTORY': false,
    'APP_INVENTORY_QTY': false,
    'APP_INVENTORY_COMPLETE': false,
    'APP_INVENTORY_QCOMPLETE': isTestMode,
    //STOCK
    'APP_STOCK': false,
    //PRODUCTUPC
    'APP_PRODUCTUPC_UPDATE': false,
  };



  // SHIPMENT
  static bool get appShipment => _roles['APP_SHIPMENT']!;
  static bool get appShipmentQty => _roles['APP_SHIPMENT_QTY']!;
  static bool get appShipmentManual => _roles['APP_SHIPMENT_MANUAL']!;
  static bool get appShipmentLowQty => _roles['APP_SHIPMENT_LOWQTY']!;
  static bool get appShipmentPrepare => _roles['APP_SHIPMENT_PREPARE']!;
  static bool get appShipmentComplete => _roles['APP_SHIPMENT_COMPLETE']!;
  static bool get appShipmentQuickComplete => _roles['APP_SHIPMENT_QCOMPLETE']!;

  // RECEIPT
  static bool get appReceipt => _roles['APP_RECEIPT']!;
  static bool get appReceiptQty => _roles['APP_RECEIPT_QTY']!;
  static bool get appReceiptManual => _roles['APP_RECEIPT_MANUAL']!;
  static bool get appReceiptPrepare => _roles['APP_RECEIPT_PREPARE']!;
  static bool get appReceiptComplete => _roles['APP_RECEIPT_COMPLETE']!;
  static bool get appReceiptQuickComplete => _roles['APP_RECEIPT_QCOMPLETE']!;

  // SHIPMENT CONFIRM
  static bool get appShipmentconfirm => _roles['APP_SHIPMENTCONFIRM']!;
  static bool get appShipmentconfirmQty => _roles['APP_SHIPMENTCONFIRM_QTY']!;
  static bool get appShipmentconfirmManual => _roles['APP_SHIPMENTCONFIRM_MANUAL']!;
  static bool get appShipmentconfirmComplete => _roles['APP_SHIPMENTCONFIRM_COMPLETE']!;
  static bool get appShipmentconfirmQuickComplete => _roles['APP_SHIPMENTCONFIRM_QCOMPLETE']!;

  // RECEIPT CONFIRM
  static bool get appReceiptconfirm => _roles['APP_RECEIPTCONFIRM']!;
  static bool get appReceiptconfirmQty => _roles['APP_RECEIPTCONFIRM_QTY']!;
  static bool get appReceiptconfirmManual => _roles['APP_RECEIPTCONFIRM_MANUAL']!;
  static bool get appReceiptconfirmComplete => _roles['APP_RECEIPTCONFIRM_COMPLETE']!;
  static bool get appReceiptconfirmQuickComplete => _roles['APP_RECEIPTCONFIRM_QCOMPLETE']!;

  // PICK CONFIRM
  static bool get appPickconfirm => _roles['APP_PICKCONFIRM']!;
  static bool get appPickconfirmQty => _roles['APP_PICKCONFIRM_QTY']!;
  static bool get appPickconfirmManual => _roles['APP_PICKCONFIRM_MANUAL']!;
  static bool get appPickconfirmComplete => _roles['APP_PICKCONFIRM_COMPLETE']!;
  static bool get appPickconfirmQuickComplete => _roles['APP_PICKCONFIRM_QCOMPLETE']!;

  // QA CONFIRM
  static bool get appQaconfirm => _roles['APP_QACONFIRM']!;
  static bool get appQaconfirmQty => _roles['APP_QACONFIRM_QTY']!;
  static bool get appQaconfirmManual => _roles['APP_QACONFIRM_MANUAL']!;
  static bool get appQaconfirmComplete => _roles['APP_QACONFIRM_COMPLETE']!;
  static bool get appQaconfirmQuickComplete => _roles['APP_QACONFIRM_QCOMPLETE']!;

  // MOVEMENT
  static bool get appMovement => _roles['APP_MOVEMENT']!;
  static bool get appMovementComplete => _roles['APP_MOVEMENT_COMPLETE']!;
  static bool get appMovementQuickComplete => _roles['APP_MOVEMENT_QCOMPLETE']!;

  // MOVEMENT CONFIRM
  static bool get appMovementconfirm => _roles['APP_MOVEMENTCONFIRM']!;
  static bool get appMovementconfirmCreate => _roles['APP_MOVEMENTCONFIRM_CREATE'] ?? false;
  static bool get appMovementconfirmComplete => _roles['APP_MOVEMENTCONFIRM_COMPLETE']!;
  static bool get appMovementconfirmQuickComplete => _roles['APP_MOVEMENTCONFIRM_QCOMPLETE']!;

  // INVENTORY
  static bool get appInventory => _roles['APP_INVENTORY']!;
  static bool get appInventoryQty => _roles['APP_INVENTORY_QTY']!;
  static bool get appInventoryComplete => _roles['APP_INVENTORY_COMPLETE']!;
  static bool get appInventoryQuickComplete => _roles['APP_INVENTORY_QCOMPLETE']!;
  //STOCK
  static bool get appStock => _roles['APP_STOCK']!;
  //PRODUCTUPC
  static bool get appProductUPCUpdate => _roles['APP_PRODUCTUPC_UPDATE']!;


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
  static bool get canUpdateProductUPC {
    return  RolesApp.appProductUPCUpdate ;
  }
  static bool get canCreateMovementInSameOrganization {
        return  appMovementComplete;
  }
  static bool get canCreateDeliveryNote {
    return  appMovementComplete;
  }
  static bool get canEditMovement {
    bool b = canCreateMovementInSameOrganization || canCreateDeliveryNote
     || canCreateMovementInSameWarehouse;
    if(b) return true ;
    //editar cantidad
    //agregar linea
    return  false ;
  }
  static bool get cantConfirmMovement {
    return  RolesApp.appMovementComplete;

  }
  static bool get canConfirmMovementWithConfirm {

    return  RolesApp.appMovementconfirmComplete ;

  }

  static bool get canSearchMovement {
    bool b =(appMovementComplete || appMovementconfirmComplete);
    if(b) return b;
    return RolesApp.appMovement;
  }

  static bool get showProductSearchScreen {
    if(canCreateMovementInSameOrganization){
      return false ;
    }
    return canSearchProductStock ;
  }

  static bool get canCreateMovementInSameWarehouse {
    return  appMovementComplete;
  }

  static bool get canCreatePickConfirm {
    //return  appMovementconfirmCreate ;
    return true ;

  }
  static bool get canCreateConfirm =>true;
}
