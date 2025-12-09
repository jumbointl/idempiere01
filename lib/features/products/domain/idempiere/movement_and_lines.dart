
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_business_partner.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement_line.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/store_on_hand/memory_products.dart';

import '../../../shared/data/memory.dart';
import '../sql/sql_users_data.dart';
import 'idempiere_business_partner_location.dart';
import 'idempiere_document_status.dart';
import 'idempiere_document_type.dart';
import 'idempiere_movement_confirm.dart';
import 'idempiere_movement_line.dart';
import 'idempiere_organization.dart';
import 'idempiere_price_list.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

class MovementAndLines extends IdempiereMovement {
  SqlUsersData? user;
  List<IdempiereMovementLine>? movementLines;
  SqlDataMovementLine? movementLineToCreate;
  List<IdempiereMovementConfirm>? movementConfirms;
  bool get hasMovement => id != null && id!>0;
  bool get hasMovementLines => movementLines != null && movementLines!.isNotEmpty;
  bool get hasMovementConfirms => movementConfirms != null && movementConfirms!.isNotEmpty;
  IdempiereWarehouse? get warehouseFrom => mWarehouseID;
  IdempiereWarehouse? get warehouseTo => mWarehouseToID;
  bool get hasWarehouseFrom => warehouseFrom != null && warehouseFrom!.id != null && warehouseFrom!.id!>0;
  bool get hasWarehouseTo => warehouseTo != null && warehouseTo!.id != null && warehouseTo!.id!>0;
  IdempiereMovementLine? get lastMovementLine => movementLines!=null &&  movementLines!.isNotEmpty ? movementLines?.last : null;
  IdempiereLocator? get lastLocatorFrom => lastMovementLine?.mLocatorID;
  IdempiereLocator? get lastLocatorTo => lastMovementLine?.mLocatorToID;
  bool get hasLastLocatorFrom => lastLocatorFrom != null && lastLocatorFrom!.id != null && lastLocatorFrom!.id!>0;
  bool get hasLastLocatorTo => lastLocatorTo != null && lastLocatorTo!.id != null && lastLocatorTo!.id!>0;
  double get movementQuantityForMovementLineCreate => movementLineToCreate?.movementQty ?? 0;
  IdempiereLocator? get locatorFromForMovementLineCreate => movementLineToCreate?.mLocatorID;
  IdempiereLocator? get locatorToForMovementLineCreate => movementLineToCreate?.mLocatorToID;
  String? nextProductIdUPC;



  String get documentNumber => documentNo ?? '';
  bool get hasNextProductIdUPC => nextProductIdUPC != null && nextProductIdUPC!='-1';
  MovementAndLines({
    super.id,
    super.docStatus,
    super.mWarehouseID,
    super.mWarehouseToID,
    super.movementDate,
    super.description,
    super.documentNo,
    super.chargeAmt,
    super.freightAmt,
    super.mOLIFsMessage,
    super.mOLIFiscalDocumentNo,
    super.mOLIFsPaused,
    super.name,
    super.modelName,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.image,
    super.category,
    super.uid,
    super.aDClientID,
    super.aDOrgID,
    super.isActive,
    super.created,
    super.createdBy,
    super.updatedBy,
    super.updated,
    super.processed,
    super.processing,
    super.isInTransit,
    super.cDocTypeID,
    super.approvalAmt,
    super.isApproved,
    super.processedOn,
    super.mPriceListID,
    this.movementConfirms,
    super.cBPartnerID,
    super.cBPartnerLocationID,
    this.user,
    this.movementLines,
    this.movementLineToCreate,
    this.nextProductIdUPC,
  }){
    if(user!=null) setUser(user!);
  }
  MovementAndLines.fromJson(Map<String, dynamic> json) {


    user = Memory.sqlUsersData;

    id = json['id'];
    uid = json['uid'];
    aDClientID = json['AD_Client_ID'] != null
        ?  IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ?  IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    isActive = json['IsActive'];
    created = json['Created'];
    createdBy = json['CreatedBy'] != null
        ?  IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    updated = json['Updated'];
    documentNo = json['DocumentNo'];
    description = json['Description'];
    movementDate = json['MovementDate'];
    processed = json['Processed'];
    processing = json['Processing'];
    isInTransit = json['IsInTransit'];
    docStatus = json['DocStatus'] != null
        ?  IdempiereDocumentStatus.fromJson(json['DocStatus'])
        : null;
    cDocTypeID = json['C_DocType_ID'] != null
        ?  IdempiereDocumentType.fromJson(json['C_DocType_ID'])
        : null;
    approvalAmt = json['ApprovalAmt'];
    isApproved = json['IsApproved'];
    processedOn = json['ProcessedOn']!=null ? double.tryParse(json['ProcessedOn'].toString()) : null;
    mPriceListID = json['M_PriceList_ID'] != null
        ?  IdempierePriceList.fromJson(json['M_PriceList_ID'])
        : null;
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'];
    name = json['name'];

    chargeAmt = json['ChargeAmt']!= null ? double.parse(json['ChargeAmt'].toString()) : null;
    freightAmt = json['FreightAmt']!= null ? double.parse(json['FreightAmt'].toString()) : null;
    mOLIFsMessage = json['MOLI_FsMessage'];
    mOLIFiscalDocumentNo = json['MOLI_FiscalDocumentNo'];
    mWarehouseID = json['M_Warehouse_ID'] != null
        ? IdempiereWarehouse.fromJson(json['M_Warehouse_ID'])
        : null;
    mWarehouseToID = json['M_WarehouseTo_ID'] != null
        ? IdempiereWarehouse.fromJson(json['M_WarehouseTo_ID'])
        : null;
    mOLIFsPaused = json['MOLI_FsPaused'] != null
        ? IdempiereDocumentStatus.fromJson(json['MOLI_FsPaused'])
        : null;
    movementLines = json['movement_lines'] != null
        ? IdempiereMovementLine.fromJsonList(json['movement_lines'])
        : null;
    nextProductIdUPC = json['next_product_id_upc'];
    movementLineToCreate = json['movement_line_to_create'] != null ?
        SqlDataMovementLine.fromJson(json['movement_line_to_create']) : null;
    movementConfirms = json['movement_confirms'] != null
        ? IdempiereMovementConfirm.fromJsonList(json['movement_confirms']) : null;
    cBPartnerID = json['C_BPartner_ID'] != null ?
    IdempiereBusinessPartner.fromJson(json['C_BPartner_ID']) : null;
    cBPartnerLocationID = json['C_BPartner_Location_ID'] != null ?
    IdempiereBusinessPartnerLocation.fromJson(json['C_BPartner_Location_ID']) : null;
  }
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }
    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }
    data['IsActive'] = isActive;
    data['Created'] = created;
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    data['Updated'] = updated;
    data['DocumentNo'] = documentNo;
    data['Description'] = description;
    data['MovementDate'] = movementDate;
    data['Processed'] = processed;
    data['Processing'] = processing;
    data['IsInTransit'] = isInTransit;
    if (docStatus != null) {
      data['DocStatus'] = docStatus!.toJson();
    }
    if (cDocTypeID != null) {
      data['C_DocType_ID'] = cDocTypeID!.toJson();
    }
    data['ApprovalAmt'] = approvalAmt;
    data['IsApproved'] = isApproved;
    data['ProcessedOn'] = processedOn;
    if (mPriceListID != null) {
      data['M_PriceList_ID'] = mPriceListID!.toJson();
    }
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category;
    data['name'] = name;

    if (mWarehouseID != null) {
      data['M_Warehouse_ID'] = mWarehouseID!.toJson();
    }
    if (mWarehouseToID != null) {
      data['M_WarehouseTo_ID'] = mWarehouseToID!.toJson();
    }
    if (mOLIFsPaused != null) {
      data['MOLI_FsPaused'] = mOLIFsPaused!.toJson();
    }
    data['MOLI_FsMessage'] = mOLIFsMessage;
    data['MOLI_FiscalDocumentNo'] = mOLIFiscalDocumentNo;
    data['ChargeAmt'] = chargeAmt;
    data['FreightAmt'] = freightAmt;
    data['movement_lines'] =  movementLines?.map((x) => x.toJson()).toList();
    data['next_product_id_upc'] = nextProductIdUPC;
    //data['movement_line_to_create'] = movementLineToCreate?.toJson();
    if (movementLineToCreate != null) {
      data['movement_line_to_create'] = movementLineToCreate?.getInsertJson();

    }

    data['movement_confirms']= movementConfirms?.map((x) => x.toJson()).toList();
    data['C_BPartner_ID'] = cBPartnerID?.toJson();
    data['C_BPartner_Location_ID'] = cBPartnerLocationID?.toJson();

    return data;
  }
  bool canCreateMovementLine() {
    if(!hasMovement) return false;
    if(!hasLastLocatorFrom) return false;
    if(!hasLastLocatorTo) return false;
    if(movementQuantityForMovementLineCreate<=0) return false;
    return true;
  }
  bool? get isMaterialMovement {
    if(warehouseFrom == null || warehouseFrom!.id ==null ) return null ;
    if(warehouseTo == null || warehouseTo!.id ==null) return null ;
    return warehouseFrom!.id == warehouseTo!.id;
  }
  bool  get canCompleteMovement {
    if(!hasMovement) return false;
    if(!hasMovementLines) return false;
    if(docStatus != null && docStatus!.id
        == Memory.IDEMPIERE_DOC_TYPE_DRAFT) {
      return true;
    }
    return false;
  }
  void setUser(SqlUsersData user){
    this.user = user;
    movementLines ??= [];
    movementLineToCreate ??= SqlDataMovementLine();
    user.copyToSqlData(movementLineToCreate!);

  }
  void setMovementLineToCreate(SqlDataMovementLine movementLineToCreate){
    this.movementLineToCreate = movementLineToCreate;
    if(user!=null) user!.copyToSqlData(movementLineToCreate);
  }
  String? get movementLineInsertUrl => movementLineToCreate?.getInsertUrl();
  Map<String, dynamic>? get movementLineInsertJson => movementLineToCreate?.getInsertJson();
  bool get isOnInitialState => id == null || id! <= 0;
  bool get querySuccess => id != null && id!>0
      && movementLines!=null && movementLines!=null;

  void cloneMovement(IdempiereMovement movement) {
    id = movement.id;
    docStatus= movement.docStatus;
    mWarehouseID= movement.mWarehouseID;
    mWarehouseToID= movement.mWarehouseToID;
    movementDate=  movement.movementDate;
    description= movement.description;
    documentNo= movement.documentNo;
    chargeAmt= movement.chargeAmt;
    freightAmt= movement.freightAmt;
    mOLIFsMessage= movement.mOLIFsMessage;
    mOLIFiscalDocumentNo= movement.mOLIFiscalDocumentNo;
    mOLIFsPaused= movement.mOLIFsPaused;
    name= movement.name;
    modelName= movement.modelName;
    active= movement.active;
    propertyLabel= movement.propertyLabel;
    identifier= movement.identifier;
    image= movement.image;
    category= movement.category;
    uid= movement.uid;
    aDClientID= movement.aDClientID;
    aDOrgID= movement.aDOrgID;
    isActive= movement.isActive;
    created= movement.created;
    createdBy= movement.createdBy;
    updatedBy= movement.updatedBy;
    updated= movement.updated;
    processed= movement.processed;
    processing= movement.processing;
    isInTransit= movement.isInTransit;
    cDocTypeID= movement.cDocTypeID;
    approvalAmt= movement.approvalAmt;
    isApproved= movement.isApproved;
    processedOn= movement.processedOn;
    mPriceListID= movement.mPriceListID;
    cBPartnerID= movement.cBPartnerID;
    cBPartnerLocationID= movement.cBPartnerLocationID;

  }
  void cloneMovementAndLines(MovementAndLines movementAndLines) {
    id = movementAndLines.id;
    docStatus= movementAndLines.docStatus;
    mWarehouseID= movementAndLines.mWarehouseID;
    mWarehouseToID= movementAndLines.mWarehouseToID;
    movementDate=  movementAndLines.movementDate;
    description= movementAndLines.description;
    documentNo= movementAndLines.documentNo;
    chargeAmt= movementAndLines.chargeAmt;
    freightAmt= movementAndLines.freightAmt;
    mOLIFsMessage= movementAndLines.mOLIFsMessage;
    mOLIFiscalDocumentNo= movementAndLines.mOLIFiscalDocumentNo;
    mOLIFsPaused= movementAndLines.mOLIFsPaused;
    name= movementAndLines.name;
    modelName= movementAndLines.modelName;
    active= movementAndLines.active;
    propertyLabel= movementAndLines.propertyLabel;
    identifier= movementAndLines.identifier;
    image= movementAndLines.image;
    category= movementAndLines.category;
    uid= movementAndLines.uid;
    aDClientID= movementAndLines.aDClientID;
    aDOrgID= movementAndLines.aDOrgID;
    isActive= movementAndLines.isActive;
    created= movementAndLines.created;
    createdBy= movementAndLines.createdBy;
    updatedBy= movementAndLines.updatedBy;
    updated= movementAndLines.updated;
    processed= movementAndLines.processed;
    processing= movementAndLines.processing;
    isInTransit= movementAndLines.isInTransit;
    cDocTypeID= movementAndLines.cDocTypeID;
    approvalAmt= movementAndLines.approvalAmt;
    isApproved= movementAndLines.isApproved;
    processedOn= movementAndLines.processedOn;
    mPriceListID= movementAndLines.mPriceListID;
    movementLines = movementAndLines.movementLines;
    movementLineToCreate = movementAndLines.movementLineToCreate;
    nextProductIdUPC = movementAndLines.nextProductIdUPC;
    user = movementAndLines.user;
    movementConfirms = movementAndLines.movementConfirms;
    cBPartnerID= movementAndLines.cBPartnerID;
    cBPartnerLocationID= movementAndLines.cBPartnerLocationID;

  }
  set movementQuantityForMovementLineToCreate(double value) {
    if(movementLineToCreate != null){
      movementLineToCreate!.movementQty = value;
    } else {
      movementLineToCreate = SqlDataMovementLine(movementQty: value);
      if(user!=null) user!.copyToSqlData(movementLineToCreate!);
    }
  }
  void setLocatorFromForMovementLineToCreate(IdempiereLocator locator) {
    if (movementLineToCreate != null) {
      movementLineToCreate!.mLocatorID = locator;
    } else {
      movementLineToCreate = SqlDataMovementLine(mLocatorID: locator);
      if (user != null) user!.copyToSqlData(movementLineToCreate!);
    }
  }
  void setLocatorToForMovementLineToCreate(IdempiereLocator locator){
    if (movementLineToCreate != null) {
      movementLineToCreate!.mLocatorToID = locator;
    } else {
      movementLineToCreate = SqlDataMovementLine(mLocatorToID: locator);
      if (user != null) user!.copyToSqlData(movementLineToCreate!);
    }
  }

  void clearData() {
    IdempiereMovement movement = IdempiereMovement();
    cloneMovement(movement);
    movementLines = null;
    movementLineToCreate = null;
  }

  bool get allCreated => id != null && id!>0 && movementLines != null && movementLines!.isNotEmpty;
  bool get nothingCreated => id == null || id!<=0 && movementLines == null && movementLines!.isEmpty;
  bool get onlyMovementCreated => id!=null && id!>0 && (movementLines == null || movementLines!.isEmpty);

  String get movementIcon => 'assets/images/monalisa_logo_movement.jpg';

  String get documentMovementTitle => cDocTypeID?.identifier ?? '';

  String get documentStatus =>  MemoryProducts.getDocumentStatusById(docStatus?.id ?? '');

  String? get documentMovementOrganizationName => cBPartnerID?.identifier ?? aDOrgID?.identifier;
  String? get documentMovementOrganizationAddress => cBPartnerLocationID?.identifier;

  bool get canChangeLocatorForEachLine {
    if(cDocTypeID == null || cDocTypeID?.id==null) return true;
    int doc = cDocTypeID!.id!;
    if(doc == Memory.IDEMPIERE_DOC_TYPE_MATERIAL_MOVEMENT){
      return true ;
    }
        return false;

  }



}