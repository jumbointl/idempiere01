
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';


class IdempiereTaxCategory extends IdempiereObject{
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  bool? isDefault;
  int? mOLICTaxCategoryID;

  IdempiereTaxCategory(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.isDefault,
        this.mOLICTaxCategoryID,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.propertyLabel,
        super.identifier,
        super.image,
      });

  IdempiereTaxCategory.fromJson(Map<String, dynamic> json) {
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
    isDefault = json['IsDefault'];
    mOLICTaxCategoryID = json['MOLI_C_TaxCategory_ID'];
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'];
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
    data['IsDefault'] = isDefault;
    data['MOLI_C_TaxCategory_ID'] = mOLICTaxCategoryID;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category;
    return data;
  }
  static List<IdempiereTaxCategory> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereTaxCategory.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereTaxCategory.fromJson(item)).toList();
    }

    List<IdempiereTaxCategory> newList =[];
    for (var item in json) {
      if(item is IdempiereTaxCategory){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereTaxCategory data = IdempiereTaxCategory.fromJson(item);
        newList.add(data);
      }
    }

    return newList;
  }
  @override
  List<String> getOtherDataToDisplay() {
    List<String> list = [];
    if (id != null) {
      list.add('${Messages.ID}: ${id ?? '--'}');
    }
    if (name != null) {
      list.add('${Messages.NAME}: ${name ?? '--'}');
    }
    if (isDefault != null) {
      list.add('${Messages.DEFAULT}: ${isDefault ?? false}');
    }
    return list;

  }  
}








