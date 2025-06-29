
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';

class IdempiereProductBrand extends IdempiereObject  {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  bool? isActive;
  String? mOLIBrandSymbol;
  bool? mOLIIsWHS;
  bool? mOLIIsApproval;

  IdempiereProductBrand(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.isActive,
        this.mOLIBrandSymbol,
        this.mOLIIsWHS,
        this.mOLIIsApproval,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,
      });

  IdempiereProductBrand.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    created = json['Created'];
    createdBy = json['CreatedBy'] != null
        ? IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    updated = json['Updated'];
    updatedBy = json['UpdatedBy'] != null
        ? IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    isActive = json['IsActive'];
    name = json['Name'];
    mOLIBrandSymbol = json['MOLI_BrandSymbol'];
    mOLIIsWHS = json['MOLI_isWHS'];
    mOLIIsApproval = json['MOLI_isApproval'];
    modelName = json['model-name'];
    active = json['active'];
    category = json['category'];
    identifier = json['identifier'];
    propertyLabel = json['propertyLabel'];
    image = json['image'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
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
    data['Updated'] = updated;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    data['IsActive'] = isActive;
    data['Name'] = name;
    data['MOLI_BrandSymbol'] = mOLIBrandSymbol;
    data['MOLI_isWHS'] = mOLIIsWHS;
    data['MOLI_isApproval'] = mOLIIsApproval;
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category;
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    return data;
  }

  static List<IdempiereProductBrand> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereProductBrand.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereProductBrand.fromJson(item)).toList();
    }

    List<IdempiereProductBrand> newList =[];
    for (var item in json) {
      if(item is IdempiereProductBrand){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereProductBrand idempiereProductBrand = IdempiereProductBrand.fromJson(item);
        newList.add(idempiereProductBrand);
      }
    }

    return newList;
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
    if(mOLIBrandSymbol != null){
      list.add(mOLIBrandSymbol!);
    }
    if(modelName != null){
      list.add(modelName!);
    }
    return list;
  }
}


