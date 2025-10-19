import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_sql_query_condition.dart';
import 'package:monalisa_app_001/features/products/domain/sql_data.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../idempiere/idempiere_document_status.dart';
import '../idempiere/idempiere_document_type.dart';
import '../idempiere/idempiere_organization.dart';
import '../idempiere/idempiere_price_list.dart';
import '../idempiere/idempiere_tenant.dart';
import '../idempiere/idempiere_user.dart';
import '../idempiere/idempiere_warehouse.dart';

class SqlDataMovement extends IdempiereMovement implements SqlData {
  int? locatorFromId;

  SqlDataMovement(
      {
        super.uid,
        super.aDClientID,
        super.aDOrgID,
        super.isActive,
        super.created,
        super.createdBy,
        super.updatedBy,
        super.updated,
        super.documentNo,
        super.description,
        super.movementDate,
        super.processed,
        super.processing,
        super.isInTransit,
        super.docStatus,
        super.cDocTypeID,
        super.approvalAmt,
        super.isApproved,
        super.processedOn,
        super.mPriceListID,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName = 'm_movement',
        super.image,
        super.category,
        super.chargeAmt,
        super.freightAmt,
        super.mWarehouseID,
        super.mWarehouseToID,
        super.mOLIFsMessage,
        super.mOLIFiscalDocumentNo,
        super.mOLIFsPaused,
        this.locatorFromId
      });



  @override
  Map<String, dynamic>  getInsertJson() {

      description = Memory.getDescriptionFromApp();
      movementDate = DateTime.now().toIso8601String().split('T').first ;
      isActive = true;

      final Map<String, dynamic> data =  <String, dynamic>{};

      if (aDOrgID != null) {
        data['AD_Org_ID'] = aDOrgID!.toJsonForIdempiereSqlUse();
      }
      data['IsActive'] = isActive;


      if (mWarehouseID != null) {
        data['M_Warehouse_ID'] = mWarehouseID!.toJsonForIdempiereSqlUse();
      }
      if (mWarehouseToID != null) {
        data['M_WarehouseTo_ID'] = mWarehouseToID!.toJsonForIdempiereSqlUse();
      }
      data['Description'] = description ?? Memory.getDescriptionFromApp();
      data['MovementDate'] = movementDate ?? DateTime.now().toIso8601String().split('T').first ;
      data['model-name'] = modelName;


      /*
      data['id'] = id;
      data['uid'] = uid;
      if (aDClientID != null) {
        data['AD_Client_ID'] = aDClientID!.toJsonForIdempiereSqlUse();
      }

      if (updatedBy != null) {
        data['UpdatedBy'] = updatedBy!.toJsonForIdempiereSqlUse();
      }
      if (createdBy != null) {
        data['CreatedBy'] = createdBy!.toJsonForIdempiereSqlUse();
      }
      data['Updated'] = updated;
      data['DocumentNo'] = documentNo;
      data['Processed'] = processed;
      data['Processing'] = processing;
      data['IsInTransit'] = isInTransit;
      if (docStatus != null) {
        data['DocStatus'] = docStatus!.toJsonForIdempiereSqlUse();
      }
      if (cDocTypeID != null) {
        data['C_DocType_ID'] = cDocTypeID!.toJsonForIdempiereSqlUse();
      }
      data['Created'] = created;
      data['ApprovalAmt'] = approvalAmt;
      data['IsApproved'] = isApproved;
      data['ProcessedOn'] = processedOn;
      if (mPriceListID != null) {
        data['M_PriceList_ID'] = mPriceListID!.toJsonForIdempiereSqlUse();
      }

      data['propertyLabel'] = propertyLabel;
      data['identifier'] = identifier;
      data['image'] = image;
      data['category'] = category;
      data['name'] = name;
      data['active'] = active;

      if (mOLIFsPaused != null) {
        data['MOLI_FsPaused'] = mOLIFsPaused!.toJsonForIdempiereSqlUse();
      }
      data['MOLI_FsMessage'] = mOLIFsMessage;
      data['MOLI_FiscalDocumentNo'] = mOLIFiscalDocumentNo;
      data['ChargeAmt'] = chargeAmt;
      data['FreightAmt'] = freightAmt;*/

      print(data);
      return data;
  }


  @override
  Map<String, dynamic>  getSelectFilter(IdempiereSqlQueryCondition filter) {
    // TODO: implement getSelectJson
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic>  getUpdateJson() {
    // TODO: implement getUpdateJson
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
  void setIdempiereDocumentStatus(int id) {
    // TODO: implement setIdempiereDocumentStatus
  }

  @override
  void setIdempiereDocumentType(int id) {
    // TODO: implement setIdempiereDocumentType
  }


  @override
  void setIdempiereMovementCDocTypeID(int cDocTypeID) {
    // TODO: implement setIdempiereMovementCDocTypeID
  }

  @override
  void setIdempiereMovementMPriceListID(int mPriceListID) {
    // TODO: implement setIdempiereMovementMPriceListID
  }

  @override
  void setIdempiereMovementStatus(int id) {
    // TODO: implement setIdempiereMovementStatus
  }

  @override
  void setIdempiereMovementType(int id) {
    // TODO: implement setIdempiereMovementType
  }

  @override
  void setIdempiereOrganization(int id) {
    aDOrgID = IdempiereOrganization(id: id);
  }

  @override
  void setIdempierePriceList(int id) {
    // TODO: implement setIdempierePriceList
  }

  @override
  void setIdempiereTenant(int id) {
    aDClientID = IdempiereTenant(id: id);
  }

  @override
  void setIdempiereUpdateBy(int id) {
    // TODO: implement setIdempiereUpdateBy
  }

  @override
  void setIdempiereWarehouse(int id) {
    mWarehouseID = IdempiereWarehouse(id: id);
  }

  @override
  void setIdempiereWarehouseTo(int id) {
    mWarehouseToID = IdempiereWarehouse(id: id);
  }

  SqlDataMovement.fromJson(Map<String, dynamic> json) {
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
  }







}