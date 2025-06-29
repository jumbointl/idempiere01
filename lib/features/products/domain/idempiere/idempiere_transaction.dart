import 'idempiere_locator.dart';
import 'idempiere_movement_line.dart';
import 'idempiere_organization.dart';
import 'idempiere_product.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_attribute_set_instance.dart';
import 'idempiere_movement_type.dart';
import 'idempiere_object.dart';

class IdempiereTransaction extends IdempiereObject  {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  IdempiereMovementType? movementType;
  IdempiereLocator? mLocatorID;
  IdempiereProduct? mProductID;
  String? movementDate;
  int? movementQty;
  IdempiereMovementLine? mMovementLineID;
  IdempiereAttributeSetInstance? mAttributeSetInstanceID;

  IdempiereTransaction(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.movementType,
        this.mLocatorID,
        this.mProductID,
        this.movementDate,
        this.movementQty,
        this.mMovementLineID,
        this.mAttributeSetInstanceID,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
      });

  IdempiereTransaction.fromJson(Map<String, dynamic> json) {
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
    movementType = json['MovementType'] != null
        ?  IdempiereMovementType.fromJson(json['MovementType'])
        : null;
    mLocatorID = json['M_Locator_ID'] != null
        ?  IdempiereLocator.fromJson(json['M_Locator_ID'])
        : null;
    mProductID = json['M_Product_ID'] != null
        ?  IdempiereProduct.fromJson(json['M_Product_ID'])
        : null;
    movementDate = json['MovementDate'];
    movementQty = json['MovementQty'];
    mMovementLineID = json['M_MovementLine_ID'] != null
        ?  IdempiereMovementLine.fromJson(json['M_MovementLine_ID'])
        : null;
    mAttributeSetInstanceID = json['M_AttributeSetInstance_ID'] != null
        ?  IdempiereAttributeSetInstance.fromJson(
        json['M_AttributeSetInstance_ID'])
        : null;
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'];
    name = json['name'];
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
    if (movementType != null) {
      data['MovementType'] = movementType!.toJson();
    }
    if (mLocatorID != null) {
      data['M_Locator_ID'] = mLocatorID!.toJson();
    }
    if (mProductID != null) {
      data['M_Product_ID'] = mProductID!.toJson();
    }
    data['MovementDate'] = movementDate;
    data['MovementQty'] = movementQty;
    if (mMovementLineID != null) {
      data['M_MovementLine_ID'] = mMovementLineID!.toJson();
    }
    if (mAttributeSetInstanceID != null) {
      data['M_AttributeSetInstance_ID'] =
          mAttributeSetInstanceID!.toJson();
    }
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category;
    data['name'] = name;
    return data;
  }
  static List<IdempiereTransaction> fromJsonList(List<dynamic> list){
    List<IdempiereTransaction> result =[];
    for (var item in list) {
      if(item is IdempiereTransaction){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereTransaction idempiereTransaction = IdempiereTransaction.fromJson(item);
        result.add(idempiereTransaction);
      }

    }
    return result;
  }
  @override
  List<String> getOtherDataToDisplay() {
    List<String> list = [];
    if(id != null){
      list.add('${Messages.ID}: ${id ?? '--'}');
    }
    if(mProductID != null){
      if( mProductID!.id != null){
        list.add('${Messages.PRODUCT_ID}: ${mProductID!.id ?? '--'}');
      }
      if( mProductID!.identifier!= null){
        list.add('${Messages.PRODUCT}: ${mProductID!.identifier ?? '--'}');
      }
    }

    if( movementQty != null){
      list.add('${Messages.QUANTITY}:${movementQty ?? '--'}');
    }
    if( updated != null){
      list.add('${Messages.DATE}: ${updated ?? '--'}');
    }


    return list;
  }
}



