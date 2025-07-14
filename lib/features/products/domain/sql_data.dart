
import 'idempiere/idempiere_sql_query_condition.dart';

abstract class SqlData{
  Map<String, dynamic>  getInsertJson();
  Map<String, dynamic>  getDeleteJson();
  Map<String, dynamic>  getUpdateJson();

  Map<String, dynamic>  getSelectFilter(IdempiereSqlQueryCondition filter);

  void setIdempiereClient(int id);
  void setIdempiereOrganization(int id);
  void setIdempiereCreateBy(int id);
  void setIdempiereUpdateBy(int id);
  void setIdempiereTenant(int id);
  void setIdempiereDocumentType(int id);
  void setIdempiereDocumentStatus(int id);
  void setIdempierePriceList(int id);
  void setIdempiereMovementStatus(int id);
  void setIdempiereMovementType(int id);
  void setIdempiereMovementCDocTypeID(int cDocTypeID);
  void setIdempiereMovementMPriceListID(int mPriceListID);
  void setIdempiereWarehouse(int id);
  void setIdempiereWarehouseTo(int id);



}