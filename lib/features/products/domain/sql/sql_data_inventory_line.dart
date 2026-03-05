import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_inventory.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_inventory_line.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_organization.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_sql_query_condition.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_tenant.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_user.dart';
import 'package:monalisa_app_001/features/products/domain/sql_data.dart';

class SqlDataInventoryLine extends IdempiereInventoryLine implements SqlData {
  SqlDataInventoryLine({
    super.uid,
    super.aDClientID,
    super.aDOrgID,
    super.isActive,
    super.created,
    super.createdBy,
    super.updated,
    super.updatedBy,
    super.mInventoryID,
    super.mLocatorID,
    super.mProductID,
    super.qtyBook,
    super.qtyCount,
    super.line,
    super.mAttributeSetInstanceID,
    super.cChargeID,
    super.inventoryType,
    super.processed,
    super.qtyInternalUse,
    super.value,
    super.uPC,
    super.qtyCsv,
    super.currentCostPrice,
    super.newCostPrice,
    super.productName,
    super.moliInventoryLineID,
    super.moliMovementQty,
    super.sKU,
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName = 'm_inventoryline',
    super.image,
    super.category,
  });

  @override
  Map<String, dynamic> getInsertJson({String? description}) {
    final Map<String, dynamic> data = <String, dynamic>{};

    isActive = true;

    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJsonForIdempiereSqlUse();
    }

    data['IsActive'] = isActive;

    if (mInventoryID != null) {
      data['M_Inventory_ID'] = mInventoryID!.toJsonForIdempiereSqlUse();
    }

    if (mLocatorID != null) {
      data['M_Locator_ID'] = mLocatorID!.toJsonForIdempiereSqlUse();
    }

    if (mProductID != null) {
      data['M_Product_ID'] = mProductID!.toJsonForIdempiereSqlUse();
    }

    data['QtyBook'] = qtyBook ?? 0;
    data['QtyCount'] = qtyCount ?? 0;
    data['Line'] = line ?? 10;

    if (mAttributeSetInstanceID != null) {
      data['M_AttributeSetInstance_ID'] =
          mAttributeSetInstanceID!.toJsonForIdempiereSqlUse();
    }

    data['model-name'] = modelName;

    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJsonForIdempiereSqlUse();
    }

    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJsonForIdempiereSqlUse();
    }

    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJsonForIdempiereSqlUse();
    }

    return data;
  }

  @override
  Map<String, dynamic> getSelectFilter(IdempiereSqlQueryCondition filter) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> getUpdateJson() {
    throw UnimplementedError();
  }

  @override
  void setIdempiereClient(int id) {
    aDClientID = IdempiereTenant(id: id);
  }

  @override
  void setIdempiereCreateBy(int id) {
    createdBy = IdempiereUser(id: id);
  }

  @override
  void setIdempiereDocumentStatus(String id) {}

  @override
  void setIdempiereDocumentType(int id) {}

  @override
  void setIdempiereMovementCDocTypeID(int cDocTypeID) {}

  @override
  void setIdempiereMovementMPriceListID(int mPriceListID) {}

  @override
  void setIdempiereMovementStatus(int id) {}

  @override
  void setIdempiereMovementType(int id) {}

  @override
  void setIdempiereOrganization(int id) {
    aDOrgID = IdempiereOrganization(id: id);
  }

  @override
  void setIdempierePriceList(int id) {}

  @override
  void setIdempiereTenant(int id) {
    aDClientID = IdempiereTenant(id: id);
  }

  @override
  void setIdempiereUpdateBy(int id) {
    updatedBy = IdempiereUser(id: id);
  }

  @override
  void setIdempiereWarehouse(int id) {}

  @override
  void setIdempiereWarehouseTo(int id) {}

  void setIdempiereInventory(int id) {
    mInventoryID = IdempiereInventory(id: id);
  }

  void setIdempiereLocator(int id) {
    mLocatorID = IdempiereLocator(id: id);
  }

  void setIdempiereProduct(int id) {
    mProductID = IdempiereProduct(id: id);
  }

  SqlDataInventoryLine.fromJson(super.json)
      : super.fromJson();
  Map<String, dynamic> getUpdateQtyCountJson() {
    String aux ='0.0';
    if(qtyCount == null || qtyCount == 0){
      aux = '0.0';
    }else{
      aux = qtyCount.toString();
    }

    return {"QtyCount": aux};
  }


}