import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_inventory.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_inventory_line.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_organization.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_tenant.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_user.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_inventory_line.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_users_data.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import 'idempiere_conversion_type.dart';
import 'idempiere_currency.dart';
import 'idempiere_document_status.dart';
import 'idempiere_document_type.dart';
import 'object_with_name_and_id.dart';

class InventoryAndLines extends IdempiereInventory {
  SqlUsersData? user;
  List<IdempiereInventoryLine>? inventoryLines;
  SqlDataInventoryLine? inventoryLineToCreate;
  String? nextProductIdUPC;

  String? filterMovementDateStartAt;

  String? filterMovementDateEndAt;

  IdempiereDocumentStatus? filterDocumentStatus;


  bool get hasInventory => id != null && id! > 0;
  bool get hasInventoryLines => inventoryLines != null && inventoryLines!.isNotEmpty;

  bool get canCompleteInventory => hasInventory && docStatus?.id == 'DR';
  bool get canCancelInventory => hasInventory && docStatus?.id == 'DR';

  IdempiereInventoryLine? get lastInventoryLine =>
      inventoryLines != null && inventoryLines!.isNotEmpty ? inventoryLines!.last : null;

  IdempiereLocator? get locatorForInventoryLineCreate => inventoryLineToCreate?.mLocatorID;

  double get qtyCountForInventoryLineCreate => inventoryLineToCreate?.qtyCount ?? 0;

  bool get allCreated => hasInventory && hasInventoryLines;
  bool get onlyInventoryCreated => hasInventory && !hasInventoryLines;
  bool get nothingCreated => !hasInventory && !hasInventoryLines;

  InventoryAndLines({
    this.user,
    this.inventoryLines,
    this.inventoryLineToCreate,
    this.nextProductIdUPC,
    this.filterMovementDateStartAt,
    this.filterMovementDateEndAt,
    this.filterDocumentStatus,
    super.id,
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
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  }) {
    if (user != null) {
      setUser(user!);
    }
  }

  InventoryAndLines.fromJson(Map<String, dynamic> json) {
    user = Memory.sqlUsersData;

    id = json['id'];
    uid = json['uid'];

    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;

    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;

    isActive = getBoolFromJson(json['IsActive']);
    created = json['Created'];

    createdBy = json['CreatedBy'] != null
        ? IdempiereUser.fromJson(json['CreatedBy'])
        : null;

    updated = json['Updated'];

    updatedBy = json['UpdatedBy'] != null
        ? IdempiereUser.fromJson(json['UpdatedBy'])
        : null;

    documentNo = json['DocumentNo'];
    description = json['Description'];
    movementDate = json['MovementDate'];
    processed = getBoolFromJson(json['Processed']);
    processing = getBoolFromJson(json['Processing']);

    mWarehouseID = json['M_Warehouse_ID'] != null
        ? IdempiereWarehouse.fromJson(json['M_Warehouse_ID'])
        : null;

    approvalAmt = json['ApprovalAmt'];

    docStatus = json['DocStatus'] != null
        ? IdempiereDocumentStatus.fromJson(json['DocStatus'])
        : null;

    isApproved = getBoolFromJson(json['IsApproved']);

    cDocTypeID = json['C_DocType_ID'] != null
        ? IdempiereDocumentType.fromJson(json['C_DocType_ID'])
        : null;

    processedOn = json['ProcessedOn'] != null
        ? double.tryParse(json['ProcessedOn'].toString())
        : null;

    costingMethod = json['CostingMethod'] != null
        ? IdempiereDocumentStatus.fromJson(json['CostingMethod'])
        : null;

    cCurrencyID = json['C_Currency_ID'] != null
        ? IdempiereCurrency.fromJson(json['C_Currency_ID'])
        : null;

    cConversionTypeID = json['C_ConversionType_ID'] != null
        ? IdempiereConversionType.fromJson(json['C_ConversionType_ID'])
        : null;

    modelName = json['model-name'];
    active = getBoolFromJson(json['active']);
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null
        ? ObjectWithNameAndId.fromJson(json['category'])
        : null;
    name = json['name'];

    inventoryLines = json['inventory_lines'] != null
        ? IdempiereInventoryLine.fromJsonList(json['inventory_lines'])
        : null;

    inventoryLineToCreate = json['inventory_line_to_create'] != null
        ? SqlDataInventoryLine.fromJson(json['inventory_line_to_create'])
        : null;

    nextProductIdUPC = json['next_product_id_upc'];
    filterMovementDateStartAt = json['filter_movement_date_start_at'];
    filterMovementDateEndAt = json['filter_movement_date_end_at'];
    filterDocumentStatus = json['filter_document_status'] != null
        ? IdempiereDocumentStatus.fromJson(json['filter_document_status'])
        : null;

  }

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();
    data['inventory_lines'] = inventoryLines?.map((e) => e.toJson()).toList();

    if (inventoryLineToCreate != null) {
      data['inventory_line_to_create'] = inventoryLineToCreate!.getInsertJson();
    }

    data['next_product_id_upc'] = nextProductIdUPC;
    data['filter_movement_date_start_at'] = filterMovementDateStartAt;
    data['filter_movement_date_end_at'] = filterMovementDateEndAt;
    data['filter_document_status'] = filterDocumentStatus?.toJson();



    return data;
  }

  void setUser(SqlUsersData user) {
    this.user = user;
    inventoryLines ??= [];
    inventoryLineToCreate ??= SqlDataInventoryLine();
    user.copyToSqlData(inventoryLineToCreate!);
  }

  void setInventoryLineToCreate(SqlDataInventoryLine line) {
    inventoryLineToCreate = line;
    if (user != null) {
      user!.copyToSqlData(line);
    }
  }

  String? get inventoryLineInsertUrl => inventoryLineToCreate?.getInsertUrl();

  Map<String, dynamic>? get inventoryLineInsertJson => inventoryLineToCreate?.getInsertJson();


  bool canCreateInventoryLine() {
    if (!hasInventory) return false;
    if (inventoryLineToCreate == null) return false;
    if (inventoryLineToCreate!.mLocatorID?.id == null ||
        inventoryLineToCreate!.mLocatorID!.id! <= 0) {
      return false;
    }
    if (inventoryLineToCreate!.mProductID?.id == null ||
        inventoryLineToCreate!.mProductID!.id! <= 0) {
      return false;
    }
    if ((inventoryLineToCreate!.qtyCount ?? 0) < 0) return false;
    return true;
  }

  void cloneInventory(IdempiereInventory inventory) {
    id = inventory.id;
    uid = inventory.uid;
    aDClientID = inventory.aDClientID;
    aDOrgID = inventory.aDOrgID;
    isActive = inventory.isActive;
    created = inventory.created;
    createdBy = inventory.createdBy;
    updated = inventory.updated;
    updatedBy = inventory.updatedBy;
    documentNo = inventory.documentNo;
    description = inventory.description;
    movementDate = inventory.movementDate;
    processed = inventory.processed;
    processing = inventory.processing;
    mWarehouseID = inventory.mWarehouseID;
    approvalAmt = inventory.approvalAmt;
    docStatus = inventory.docStatus;
    isApproved = inventory.isApproved;
    cDocTypeID = inventory.cDocTypeID;
    processedOn = inventory.processedOn;
    costingMethod = inventory.costingMethod;
    cCurrencyID = inventory.cCurrencyID;
    cConversionTypeID = inventory.cConversionTypeID;
    name = inventory.name;
    active = inventory.active;
    propertyLabel = inventory.propertyLabel;
    identifier = inventory.identifier;
    image = inventory.image;
    category = inventory.category;
  }

  void cloneInventoryAndLines(InventoryAndLines other) {
    cloneInventory(other);
    user = other.user;
    inventoryLines = other.inventoryLines;
    inventoryLineToCreate = other.inventoryLineToCreate;
    nextProductIdUPC = other.nextProductIdUPC;
  }

  void clearData() {
    cloneInventory(IdempiereInventory());
    inventoryLines = null;
    inventoryLineToCreate = null;
    nextProductIdUPC = null;
  }
}