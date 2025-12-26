import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_asset_group.dart';
import 'idempiere_material_policy.dart';
import 'idempiere_paint_color.dart';
import 'object_with_name_and_id.dart';

class IdempiereProductCategory extends IdempiereObject {

  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;

  String? description;
  String? value;
  bool? isDefault;
  int? plannedMargin;
  IdempiereAssetGroup? aAssetGroupID;
  bool? isSelfService;
  IdempierePaintColor? aDPrintColorID;
  IdempiereMaterialPolicy? mMPolicy;



  IdempiereProductCategory(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.description,
        this.value,
        this.isDefault,
        this.plannedMargin,
        this.aAssetGroupID,
        this.isSelfService,
        this.aDPrintColorID,
        this.mMPolicy,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,
      });

  IdempiereProductCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    isActive = json['IsActive'];
    created = json['Created'];
    createdBy = json['CreatedBy'] != null
        ? IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    updated = json['Updated'];
    updatedBy = json['UpdatedBy'] != null
        ? IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    name = json['Name'];
    description = json['Description'];
    value = json['Value'];
    isDefault = json['IsDefault'];
    plannedMargin = json['PlannedMargin'];
    aAssetGroupID = json['A_Asset_Group_ID'] != null
        ? IdempiereAssetGroup.fromJson(json['A_Asset_Group_ID'])
        : null;
    isSelfService = json['IsSelfService'];
    aDPrintColorID = json['AD_PrintColor_ID'] != null
        ? IdempierePaintColor.fromJson(json['AD_PrintColor_ID'])
        : null;
    mMPolicy = json['MMPolicy'] != null
        ? IdempiereMaterialPolicy.fromJson(json['MMPolicy'])
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
    final Map<String, dynamic> data = <String, dynamic>{};
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
    data['Description'] = description;
    data['Value'] = value;
    data['IsDefault'] = isDefault;
    data['PlannedMargin'] = plannedMargin;
    if (aAssetGroupID != null) {
      data['A_Asset_Group_ID'] = aAssetGroupID!.toJson();
    }
    data['IsSelfService'] = isSelfService;
    if (aDPrintColorID != null) {
      data['AD_PrintColor_ID'] = aDPrintColorID!.toJson();
    }
    if (mMPolicy != null) {
      data['MMPolicy'] = mMPolicy!.toJson();
    }
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    return data;
  }
  static List<IdempiereProductCategory> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereProductCategory.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereProductCategory.fromJson(item)).toList();
    }

    List<IdempiereProductCategory> newList =[];
    for (var item in json) {
      if(item is IdempiereProductCategory){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereProductCategory idempiereProductCategory = IdempiereProductCategory.fromJson(item);
        newList.add(idempiereProductCategory);
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
    if(description != null){
      list.add(description!);
    }
    if(modelName != null){
      list.add(modelName!);
    }
    return list;
  }
}



