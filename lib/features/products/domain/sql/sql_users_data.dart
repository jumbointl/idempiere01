import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_tenant.dart';

import '../idempiere/idempiere_organization.dart';
import '../idempiere/idempiere_user.dart';
import '../idempiere/idempiere_warehouse.dart';
import '../sql_data.dart';

class SqlUsersData {
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  IdempiereUser? createdBy;
  IdempiereWarehouse? mWarehouseID;
  SqlUsersData({
    this.aDClientID,
    this.aDOrgID,
    this.createdBy,
    this.mWarehouseID,
  });

  void setIdempiereClient(int id) {
    aDClientID = IdempiereTenant(id: id);
  }
  void setIdempiereCreateBy(int id) {
    createdBy = IdempiereUser(id: id);
  }
  void setIdempiereOrganization(int id) {
    aDOrgID = IdempiereOrganization(id: id);
  }
  void setIdempiereWarehouse(int id) {
    mWarehouseID = IdempiereWarehouse(id: id);
  }
  void copyToSqlData(SqlData data) {
    if(aDOrgID!=null && aDOrgID!.id!=null) data.setIdempiereOrganization(aDOrgID!.id!);
    if(mWarehouseID!=null && mWarehouseID!.id!=null) data.setIdempiereWarehouse(mWarehouseID!.id!);
    if(createdBy!=null && createdBy!.id!=null) data.setIdempiereCreateBy(createdBy!.id!);
    if(aDClientID!=null && aDClientID!.id!=null) data.setIdempiereClient(aDClientID!.id!);
  }


}