
import 'idempiere_discount_schema.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_price_list.dart';
import 'object_with_name_and_id.dart';

class IdempierePriceListVersion  extends IdempiereObject{
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  IdempierePriceList? mPriceListID;
  String? validFrom;
  IdempierePriceListVersion? mPricelistVersionBaseID;
  IdempiereDiscountSchema? mDiscountSchemaID;

  IdempierePriceListVersion(
      { 
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.mPriceListID,
        this.validFrom,
        this.mPricelistVersionBaseID,
        this.mDiscountSchemaID,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,
      });

  IdempierePriceListVersion.fromJson(Map<String, dynamic> json) {
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
    name = json['Name'];
    mPriceListID = json['M_PriceList_ID'] != null
        ?  IdempierePriceList.fromJson(json['M_PriceList_ID'])
        : null;
    validFrom = json['ValidFrom'];
    mPricelistVersionBaseID = json['M_Pricelist_Version_Base_ID'] != null
        ?  IdempierePriceListVersion.fromJson(json['M_Pricelist_Version_Base_ID'])
        : null;
    mDiscountSchemaID = json['M_DiscountSchema_ID'] != null
        ?  IdempiereDiscountSchema.fromJson(json['M_DiscountSchema_ID'])
        : null;
    modelName = json['model-name'];
    active = json['active'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;;
    identifier = json['identifier'];
    propertyLabel = json['propertyLabel'];
    image = json['image'];
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
    data['Name'] = name;
    if (mPriceListID != null) {
      data['M_PriceList_ID'] = mPriceListID!.toJson();
    }
    data['ValidFrom'] = validFrom;
    if (mPricelistVersionBaseID != null) {
      data['M_Pricelist_Version_Base_ID'] =
          mPricelistVersionBaseID!.toJson();
    }
    if (mDiscountSchemaID != null) {
      data['M_DiscountSchema_ID'] = mDiscountSchemaID!.toJson();
    }
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    return data;
  }
 
  static List<IdempierePriceListVersion> fromJsonList(List<dynamic> list){
    List<IdempierePriceListVersion> result =[];
    for (var item in list) {
      if(item is IdempierePriceListVersion){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePriceListVersion idempierePriceListVersion = IdempierePriceListVersion.fromJson(item);
        result.add(idempierePriceListVersion);
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
    if(name != null){
      list.add('${Messages.NAME}: ${name ?? '--'}');
    }
    if(mPriceListID != null){
      list.add(mPriceListID?.id?.toString() ?? '--');
    }
    return list;
  }
}