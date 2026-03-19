import 'package:monalisa_app_001/features/products/domain/sql/sql_data_inventory.dart';

import '../../../shared/data/memory.dart';
import '../sql/sql_data_inventory_line.dart';
import '../sql/sql_users_data.dart';
import 'idempiere_warehouse.dart';

class PutAwayInventory {
  static const int ERROR_LOCATOR_FROM = -1;
  static const int ERROR_QUANTITY = -3;
  static const int ERROR_PRODUCT = -4;
  static const int ERROR_USER = -5;
  static const int ERROR_WAREHOUSE_FROM = -6;
  static const int ERROR_INVENTORY = -8;
  static const int ERROR_INVENTORY_LINE = -9;
  static const int ERROR_START_CREATE = -10;
  static const int ERROR_ORG_WAREHOUSE_FROM = -13;
  static const int ERROR_DOCUMENT_TYPE = -15;
  static const int ERROR_INVENTORY_NULL = -16;
  static const int SUCCESS = 0;

  SqlDataInventoryLine? inventoryLineToCreate;
  SqlDataInventory? inventoryToCreate;
  SqlUsersData? user;
  bool? startCreate;

  bool get hasInventory => inventoryToCreate != null;
  bool get hasInventoryLineToCreate => inventoryLineToCreate != null;

  IdempiereWarehouse? get warehouseFrom =>
      inventoryToCreate?.mWarehouseID ??
          inventoryLineToCreate?.mLocatorID?.mWarehouseID;

  bool get hasWarehouseFrom =>
      warehouseFrom != null &&
          warehouseFrom!.id != null &&
          warehouseFrom!.id! > 0;

  IdempiereWarehouse? get allowedWareHouseFrom => warehouseFrom;

  PutAwayInventory({
    this.inventoryLineToCreate,
    this.inventoryToCreate,
    this.user,
    this.startCreate = false,
  });

  int canCreatePutAwayInventory() {
    if (inventoryToCreate == null) return ERROR_INVENTORY_NULL;

    createInventoryDocumentType();

    if (startCreate == true) return ERROR_START_CREATE;
    if (!hasInventory) return ERROR_INVENTORY;
    if (inventoryToCreate!.id != null && inventoryToCreate!.id! > 0) {
      return ERROR_INVENTORY;
    }

    if (!hasInventoryLineToCreate) return ERROR_INVENTORY_LINE;
    if (inventoryLineToCreate!.id != null && inventoryLineToCreate!.id! > 0) {
      return ERROR_INVENTORY_LINE;
    }

    if (!hasWarehouseFrom) return ERROR_WAREHOUSE_FROM;

    if (warehouseFrom == null) {
      return ERROR_ORG_WAREHOUSE_FROM;
    }

    if (inventoryToCreate!.cDocTypeID == null ||
        inventoryToCreate!.cDocTypeID!.id == null ||
        inventoryToCreate!.cDocTypeID!.id! <= 0) {
      return ERROR_DOCUMENT_TYPE;
    }

    if (inventoryLineToCreate!.mProductID == null) return ERROR_PRODUCT;
    if (inventoryLineToCreate!.mLocatorID == null) return ERROR_LOCATOR_FROM;
    if (inventoryLineToCreate!.qtyCount == null ||
        inventoryLineToCreate!.qtyCount! <= 0) {
      return ERROR_QUANTITY;
    }



    return SUCCESS;
  }

  void setUser(SqlUsersData user) {
    this.user = user;

    inventoryLineToCreate = SqlDataInventoryLine();
    user.copyToSqlData(inventoryLineToCreate!);

    inventoryToCreate = SqlDataInventory();
    user.copyToSqlData(inventoryToCreate!);
  }

  Map<String, dynamic>? get inventoryLineInsertJson =>
      inventoryLineToCreate?.getInsertJson();

  Map<String, dynamic>? get inventoryInsertJson =>
      inventoryToCreate?.getInsertJson();

  String? get inventoryInsertUrl => inventoryToCreate?.getInsertUrl();

  String? get inventoryLineInsertUrl => inventoryLineToCreate?.getInsertUrl();

  bool get inventoryCreated =>
      inventoryToCreate != null &&
          inventoryToCreate!.id != null &&
          inventoryToCreate!.id! > 0;

  bool get inventoryLineCreated =>
      inventoryLineToCreate != null &&
          inventoryLineToCreate!.id != null &&
          inventoryLineToCreate!.id! > 0;

  bool get allCreated => inventoryLineCreated && inventoryCreated;

  bool get nothingCreated =>
      !inventoryLineCreated && inventoryCreated && startCreate == true;

  bool get onlyInventoryCreated =>
      !inventoryLineCreated && !inventoryCreated && startCreate == true;

  void createInventoryDocumentType() {
    if (inventoryToCreate == null) return;


    inventoryToCreate!.cDocTypeID = Memory.physicalInventory;
  }

  Map<String, dynamic>? getInsertJson({required String description}) {
    return inventoryLineToCreate?.getInsertJson(description: description);
  }
}