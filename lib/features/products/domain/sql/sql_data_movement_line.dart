import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_sql_query_condition.dart';
import 'package:monalisa_app_001/features/products/domain/sql_data.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../idempiere/idempiere_attribute_set_instance.dart';
import '../idempiere/idempiere_locator.dart';
import '../idempiere/idempiere_movement_line.dart';
import '../idempiere/idempiere_organization.dart';
import '../idempiere/idempiere_product.dart';
import '../idempiere/idempiere_tenant.dart';
import '../idempiere/idempiere_user.dart';

class SqlDataMovementLine extends IdempiereMovementLine implements SqlData {

  SqlDataMovementLine(
      {
        super.uid,
        super.aDClientID,
        super.aDOrgID,
        super.isActive,
        super.created,
        super.createdBy,
        super.updated,
        super.updatedBy,
        super.mMovementID,
        super.mLocatorID,
        super.mLocatorToID,
        super.mProductID,
        super.movementQty,
        super.description,
        super.line,
        super.mAttributeSetInstanceID,
        super.confirmedQty,
        super.targetQty,
        super.scrappedQty,
        super.processed,
        super.value,
        super.priceEntered,
        super.priceList,
        super.priceActual,
        super.productName,
        super.lineNetAmt,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName='m_movementline',
        super.image,
        super.category,
        super.sKU,
        super.uPC,
      });


  @override
  Map<String, dynamic>  getInsertJson() {

      description = Memory.getDescriptionFromApp();
      isActive = true;

      final Map<String, dynamic> data =  <String, dynamic>{};

      if (aDOrgID != null) {
        data['AD_Org_ID'] = aDOrgID!.toJsonForIdempiereSqlUse();
      }
      data['IsActive'] = isActive;
      if (mMovementID != null) {
        data['M_Movement_ID'] = mMovementID!.toJsonForIdempiereSqlUse();
      }
      if (mLocatorID != null) {
        data['M_Locator_ID'] = mLocatorID!.toJsonForIdempiereSqlUse();
      }
      if (mLocatorToID != null) {
        data['M_LocatorTo_ID'] = mLocatorToID!.toJsonForIdempiereSqlUse();
      }
      if (mProductID != null) {
        data['M_Product_ID'] = mProductID!.toJsonForIdempiereSqlUse();
      }
      data['MovementQty'] = movementQty;
      data['Description'] = description;
      data['Line'] = line;
      if (mAttributeSetInstanceID != null) {
        data['M_AttributeSetInstance_ID'] =
            mAttributeSetInstanceID!.toJsonForIdempiereSqlUse();
      }
      data['model-name'] = modelName;



      /*data['id'] = id;
      data['uid'] = uid;
      if (aDClientID != null) {
        data['AD_Client_ID'] = aDClientID!.toJsonForIdempiereSqlUse();
      }
      if (aDOrgID != null) {
        data['AD_Org_ID'] = aDOrgID!.toJsonForIdempiereSqlUse();
      }
      data['Created'] = created;
      if (createdBy != null) {
        data['CreatedBy'] = createdBy!.toJsonForIdempiereSqlUse();
      }
      data['Updated'] = updated;
      if (updatedBy != null) {
        data['UpdatedBy'] = updatedBy!.toJsonForIdempiereSqlUse();
      }
      data['ConfirmedQty'] = confirmedQty;
      data['TargetQty'] = targetQty;
      data['ScrappedQty'] = scrappedQty;
      data['Processed'] = processed;
      data['Value'] = value;
      data['PriceEntered'] = priceEntered;
      data['PriceList'] = priceList;
      data['PriceActual'] = priceActual;
      data['ProductName'] = productName;
      data['LineNetAmt'] = lineNetAmt;
      data['active'] = active;
      data['propertyLabel'] = propertyLabel;
      data['identifier'] = identifier;
      data['image'] = image;
      data['category'] = category;
      data['name'] = name;
      data['SKU'] = sKU;
      data['UPC'] = uPC;*/

      return data;
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
    data['Updated'] = updated;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    if (mMovementID != null) {
      data['M_Movement_ID'] = mMovementID!.toJson();
    }
    if (mLocatorID != null) {
      data['M_Locator_ID'] = mLocatorID!.toJson();
    }
    if (mLocatorToID != null) {
      data['M_LocatorTo_ID'] = mLocatorToID!.toJson();
    }
    if (mProductID != null) {
      data['M_Product_ID'] = mProductID!.toJson();
    }
    data['MovementQty'] = movementQty;
    data['Description'] = description;
    data['Line'] = line;
    if (mAttributeSetInstanceID != null) {
      data['M_AttributeSetInstance_ID'] =
          mAttributeSetInstanceID!.toJson();
    }
    data['ConfirmedQty'] = confirmedQty;
    data['TargetQty'] = targetQty;
    data['ScrappedQty'] = scrappedQty;
    data['Processed'] = processed;
    data['Value'] = value;
    data['PriceEntered'] = priceEntered;
    data['PriceList'] = priceList;
    data['PriceActual'] = priceActual;
    data['ProductName'] = productName;
    data['LineNetAmt'] = lineNetAmt;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category;
    data['name'] = name;
    data['SKU'] = sKU;
    data['UPC'] = uPC;
    return data;
  }
  SqlDataMovementLine.fromJson(Map<String, dynamic> json) {
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
    updated = json['Updated'];
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    mMovementID = json['M_Movement_ID'] != null
        ?  IdempiereMovement.fromJson(json['M_Movement_ID'])
        : null;
    mLocatorID = json['M_Locator_ID'] != null
        ?  IdempiereLocator.fromJson(json['M_Locator_ID'])
        : null;
    mLocatorToID = json['M_LocatorTo_ID'] != null
        ?  IdempiereLocator.fromJson(json['M_LocatorTo_ID'])
        : null;
    mProductID = json['M_Product_ID'] != null
        ?  IdempiereProduct.fromJson(json['M_Product_ID'])
        : null;
    movementQty = json['MovementQty'];
    description = json['Description'];
    line = json['Line'];
    mAttributeSetInstanceID = json['M_AttributeSetInstance_ID'] != null
        ?  IdempiereAttributeSetInstance.fromJson(
        json['M_AttributeSetInstance_ID'])
        : null;
    confirmedQty = json['ConfirmedQty'];
    targetQty = json['TargetQty'];
    scrappedQty = json['ScrappedQty'];
    processed = json['Processed'];
    value = json['Value'];
    priceEntered = json['PriceEntered']!= null ? double.tryParse(json['PriceEntered'].toString()) : null;
    priceList = json['PriceList']!= null ? double.tryParse(json['PriceList'].toString()) : null;
    priceActual = json['PriceActual']!= null ? double.tryParse(json['PriceActual'].toString()) : null;
    productName = json['ProductName'];
    lineNetAmt = json['LineNetAmt']!= null ? double.tryParse(json['LineNetAmt'].toString()) : null;
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'];
    name = json['name'];
    sKU = json['SKU'];
    uPC = json['UPC'];
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
  }

  @override
  void setIdempiereWarehouseTo(int id) {
  }
  void setIdempiereLocator(int id) {
    mLocatorID = IdempiereLocator(id: id);
  }
  void setIdempiereLocatorTo(int id) {
    mLocatorToID = IdempiereLocator(id: id);
  }
  void setIdempiereProduct(int id) {
    mProductID = IdempiereProduct(id: id);
  }
  Map<String, dynamic> getUpdateMovementQuantityJson() {
    return {"MovementQty": movementQty};
  }
}