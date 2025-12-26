import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';

import 'idempiere_object.dart';
import 'idempiere_user.dart';
import 'idempiere_discount_type.dart';
import 'object_with_name_and_id.dart';

class IdempiereDiscountSchema extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  String? description;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? validFrom;
  IdempiereDiscountType?  discountType;
  bool? isQuantityBased;
  bool? isBPartnerFlatDiscount;

  IdempiereDiscountSchema(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.description,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.validFrom,
        this.discountType,
        this.isQuantityBased,
        this.isBPartnerFlatDiscount,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
      });

  IdempiereDiscountSchema.fromJson(Map<String, dynamic> json) {
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
    description = json['Description'];
    createdBy = json['CreatedBy'] != null
        ?  IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    updated = json['Updated'];
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    name = json['Name'];
    validFrom = json['ValidFrom'];
    discountType = json['DiscountType'] != null
        ?  IdempiereDiscountType.fromJson(json['DiscountType'])
        : null;
    isQuantityBased = json['IsQuantityBased'];
    isBPartnerFlatDiscount = json['IsBPartnerFlatDiscount'];
    modelName = json['model-name'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;;
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    active = json['active'];
    
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
    data['Description'] = description;
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    data['Updated'] = updated;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    data['Name'] = name;
    data['ValidFrom'] = validFrom;
    if (discountType != null) {
      data['DiscountType'] = discountType!.toJson();
    }
    data['IsQuantityBased'] = isQuantityBased;
    data['IsBPartnerFlatDiscount'] = isBPartnerFlatDiscount;
    data['model-name'] = modelName;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['active'] = active;
    return data;
  }
}





