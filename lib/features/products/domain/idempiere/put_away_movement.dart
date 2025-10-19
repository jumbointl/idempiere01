import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement.dart';

import '../sql/sql_data_movement_line.dart';
import '../sql/sql_users_data.dart';
import 'idempiere_warehouse.dart';

class PutAwayMovement {
    static const int ERROR_LOCATOR_FROM = -1;
    static const int ERROR_LOCATOR_TO = -2;
    static const int ERROR_QUANTITY = -3;
    static const int ERROR_PRODUCT = -4;
    static const int ERROR_USER = -5;
    static const int ERROR_WAREHOUSE_FROM = -6;
    static const int ERROR_WAREHOUSE_TO = -7;
    static const int ERROR_MOVEMENT = -8;
    static const int ERROR_MOVEMENT_LINE = -9;
    static const int ERROR_START_CREATE = -10;
    static const int ERROR_SAME_WAREHOUSE = -11;
    static const int ERROR_SAME_LOCATOR = -12;
    static const int SUCCESS = 0;




    SqlDataMovementLine? movementLineToCreate;
    SqlDataMovement?  movementToCreate;
    SqlUsersData? user;
    bool? startCreate;
    bool get hasMovement => movementToCreate != null;
    bool get hasMovementLineToCreate => movementLineToCreate != null;
    IdempiereWarehouse? get warehouseFrom => movementToCreate?.mWarehouseID ?? movementLineToCreate?.mLocatorID?.mWarehouseID;
    IdempiereWarehouse? get warehouseTo => movementToCreate?.mWarehouseToID ?? movementLineToCreate?.mLocatorToID?.mWarehouseID ;
    bool get hasWarehouseFrom => warehouseFrom != null && warehouseFrom!.id != null && warehouseFrom!.id!>0;
    bool get hasWarehouseTo => warehouseTo != null && warehouseTo!.id != null && warehouseTo!.id!>0;
    IdempiereWarehouse? get allowedWareHouseFrom => warehouseFrom;
    PutAwayMovement({
       this.movementLineToCreate,
       this.movementToCreate,
       this.user,
       this.startCreate = false,

    });


    int  canCreatePutAwayMovement() {
    if(startCreate==true) return ERROR_START_CREATE;
    if(!hasMovement) return ERROR_MOVEMENT;
    if(movementToCreate!.id != null && movementToCreate!.id!>0) return ERROR_MOVEMENT;
    if(!hasMovementLineToCreate) return ERROR_MOVEMENT_LINE;
    if(movementLineToCreate!.id !=null && movementLineToCreate!.id!>0) return ERROR_MOVEMENT_LINE;
    if(!hasWarehouseFrom) return ERROR_WAREHOUSE_FROM;
    if(!hasWarehouseTo) return ERROR_WAREHOUSE_TO;
    if(warehouseFrom!.id == warehouseTo!.id) return ERROR_SAME_WAREHOUSE;
    if(movementLineToCreate!.mProductID == null) return ERROR_PRODUCT;
    if(movementLineToCreate!.mLocatorID == null) return ERROR_LOCATOR_FROM;
    if(movementLineToCreate!.mLocatorToID == null) return ERROR_LOCATOR_TO;
    if(movementLineToCreate!.mLocatorID!.id == movementLineToCreate!.mLocatorToID!.id) return ERROR_SAME_LOCATOR;
    if(movementLineToCreate!.movementQty == null || movementLineToCreate!.movementQty !<=0) return ERROR_QUANTITY;


    return SUCCESS;
  }
  void setUser(SqlUsersData user){
      this.user = user;
      movementLineToCreate = SqlDataMovementLine();
      user.copyToSqlData(movementLineToCreate!);
      movementToCreate = SqlDataMovement();
      user.copyToSqlData(movementToCreate!);

  }
  Map<String, dynamic>? get movementLineInsertJson => movementLineToCreate?.getInsertJson();
  Map<String, dynamic>? get movementInsertJson => movementToCreate?.getInsertJson();
  String? get movementInsertUrl => movementToCreate?.getInsertUrl();
  String? get movementLineInsertUrl => movementLineToCreate?.getInsertUrl();
  bool get movementCreated => movementToCreate!=null && movementToCreate!.id != null && movementToCreate!.id!>0;
  bool get movementLineCreated => movementLineToCreate!=null && movementLineToCreate!.id != null && movementLineToCreate!.id!>0;
  bool get allCreated => movementLineCreated && movementCreated;
  bool get nothingCreated => !movementLineCreated && movementCreated && startCreate == true ;
  bool get onlyMovementCreated => !movementLineCreated && !movementCreated && startCreate == true ;

}
