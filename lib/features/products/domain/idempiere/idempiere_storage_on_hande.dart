
import 'idempiere_locator.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_product.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import 'idempiere_attribute_set_instance.dart';

class IdempiereStorageOnHande extends IdempiereObject{
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  String? created;
  IdempiereUser? createdBy;
  bool? isActive;
  IdempiereAttributeSetInstance? mAttributeSetInstanceID;
  IdempiereLocator? mLocatorID;
  IdempiereProduct? mProductID;
  double? qtyOnHand;
  String? updated;
  IdempiereUser? updatedBy;
  String? dateMaterialPolicy;

  IdempiereStorageOnHande(
      { 
        
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.created,
        this.createdBy,
        this.isActive,
        this.mAttributeSetInstanceID,
        this.mLocatorID,
        this.mProductID,
        this.qtyOnHand,
        this.updated,
        this.updatedBy,
        this.dateMaterialPolicy,
        super.modelName,
        super.id,
        super.identifier,
        super.propertyLabel,
        super.active,
        super.category,
        super.name,
        super.image,
      });

  IdempiereStorageOnHande.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    aDClientID = json['AD_Client_ID'] != null
        ?  IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ?  IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    created = json['Created'];
    createdBy = json['CreatedBy'] != null
        ?  IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    isActive = json['IsActive'];
    mAttributeSetInstanceID = json['M_AttributeSetInstance_ID'] != null
        ?  IdempiereAttributeSetInstance.fromJson(
        json['M_AttributeSetInstance_ID'])
        : null;
    mLocatorID = json['M_Locator_ID'] != null
        ?  IdempiereLocator.fromJson(json['M_Locator_ID'])
        : null;
    mProductID = json['M_Product_ID'] != null
        ?  IdempiereProduct.fromJson(json['M_Product_ID'])
        : null;
    qtyOnHand = json['QtyOnHand'] != null ? double.tryParse(json['QtyOnHand'].toString()) : null;
    updated = json['Updated'];
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    dateMaterialPolicy = json['DateMaterialPolicy'];
    modelName = json['model-name'];
    id = json['id'];
    identifier = json['identifier'];
    propertyLabel = json['propertyLabel'];
    active = json['active'];
    category = json['category'];
    name = json['name'];
    image = json['image'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    data['uid'] = uid;
    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }
    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }
    data['Created'] = created;
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    data['IsActive'] = isActive;
    if (mAttributeSetInstanceID != null) {
      data['M_AttributeSetInstance_ID'] =
          mAttributeSetInstanceID!.toJson();
    }
    if (mLocatorID != null) {
      data['M_Locator_ID'] = mLocatorID!.toJson();
    }
    if (mProductID != null) {
      data['M_Product_ID'] = mProductID!.toJson();
    }
    data['QtyOnHand'] = qtyOnHand;
    data['Updated'] = updated;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    data['DateMaterialPolicy'] = dateMaterialPolicy;
    data['model-name'] = modelName;
    data['id'] = id;
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['active'] = active;
    data['category'] = category;
    data['name'] = name;
    data['image'] = image;
    
    return data;
  }

  static List<IdempiereStorageOnHande>? fromJsonList(json) {

    if (json is List) {
      return json.map((item) => IdempiereStorageOnHande.fromJson(item)).toList();
    } else {
      return null ;
    }
  }
}

