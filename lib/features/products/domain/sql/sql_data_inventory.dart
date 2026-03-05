import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_type.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_inventory.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_organization.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_sql_query_condition.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_tenant.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_user.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';
import 'package:monalisa_app_001/features/products/domain/sql_data.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

class SqlDataInventory extends IdempiereInventory implements SqlData {
  SqlDataInventory({
    super.uid,
    super.aDClientID,
    super.aDOrgID,
    super.isActive,
    super.created,
    super.createdBy,
    super.updated,
    super.updatedBy,
    super.documentNo,
    super.description,
    super.movementDate,
    super.processed,
    super.processing,
    super.mWarehouseID,
    super.approvalAmt,
    super.docStatus,
    super.isApproved,
    super.cDocTypeID,
    super.processedOn,
    super.costingMethod,
    super.cCurrencyID,
    super.cConversionTypeID,
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName = 'm_inventory',
    super.image,
    super.category,
  });

  @override
  Map<String, dynamic> getInsertJson({String? description}) {
    description ??= Memory.getDescriptionFromApp();
    movementDate = DateTime.now().toIso8601String().split('T').first;
    isActive = true;

    final Map<String, dynamic> data = <String, dynamic>{};

    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJsonForIdempiereSqlUse();
    }

    data['IsActive'] = isActive;

    if (mWarehouseID != null) {
      data['M_Warehouse_ID'] = mWarehouseID!.toJsonForIdempiereSqlUse();
    }

    data['Description'] = description;
    data['MovementDate'] = movementDate;
    data['model-name'] = modelName;

    if (cDocTypeID != null) {
      data['C_DocType_ID'] = cDocTypeID!.toJsonForIdempiereSqlUse();
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
  void setIdempiereDocumentType(int id) {
    cDocTypeID = IdempiereDocumentType(id: id);
  }

  @override
  void setIdempiereMovementCDocTypeID(int cDocTypeID) {
    this.cDocTypeID = IdempiereDocumentType(id: cDocTypeID);
  }

  @override
  void setIdempiereMovementMPriceListID(int mPriceListID) {}

  @override
  void setIdempiereMovementStatus(int id) {
  }

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
  void setIdempiereWarehouse(int id) {
    mWarehouseID = IdempiereWarehouse(id: id);
  }

  @override
  void setIdempiereWarehouseTo(int id) {}

  SqlDataInventory.fromJson(super.json)
      : super.fromJson();
}