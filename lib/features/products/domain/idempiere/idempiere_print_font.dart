
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'idempiere_user.dart';
import 'object_with_name_and_id.dart';

class IdempierePrintFont extends IdempiereObject {
  String? uid;
  bool? isActive;
  IdempiereUser? updatedBy;
  IdempiereOrganization? aDOrgID;
  IdempiereTenant? aDClientID;
  String? code;
  String? created;
  bool? isDefault;
  String? updated;
  IdempiereUser? createdBy;

  IdempierePrintFont(
      {
        this.uid,
        this.isActive,
        this.updatedBy,
        this.aDOrgID,
        this.aDClientID,
        this.code,
        this.created,
        this.isDefault,
        this.updated,
        this.createdBy,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
      });

  IdempierePrintFont.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    name = json['Name'];
    isActive = json['IsActive'];
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ?  IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    aDClientID = json['AD_Client_ID'] != null
        ?  IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    code = json['Code'];
    created = json['Created'];
    isDefault = json['IsDefault'];
    updated = json['Updated'];
    createdBy = json['CreatedBy'] != null
        ?  IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;;
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['Name'] = name;
    data['IsActive'] = isActive;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }
    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }
    data['Code'] = code;
    data['Created'] = created;
    data['IsDefault'] = isDefault;
    data['Updated'] = updated;
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    return data;
  }
  static List<IdempierePrintFont> fromJsonList(List<dynamic> list){
    List<IdempierePrintFont> result =[];
    for (var item in list) {
      if(item is IdempierePrintFont){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePrintFont idempierePrintFont = IdempierePrintFont.fromJson(item);
        result.add(idempierePrintFont);
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
    if(code != null){
      list.add('${Messages.CODE}: ${code ?? '--'}');
    }
    return list;
  }
}

