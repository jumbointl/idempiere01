
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'idempiere_user.dart';


class IdempierePrintColor  extends IdempiereObject{
  String? uid;
  IdempiereUser? createdBy;
  String? created;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isDefault;
  String? code;
  bool? isActive;
  IdempiereUser? updatedBy;
  String? updated;

  IdempierePrintColor(
      {
        this.uid,
        this.createdBy,
        this.created,
        this.aDClientID,
        this.aDOrgID,
        this.isDefault,
        this.code,
        this.isActive,
        this.updatedBy,
        this.updated,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,

      });

  IdempierePrintColor.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    createdBy = json['CreatedBy'] != null
        ?  IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    created = json['Created'];
    aDClientID = json['AD_Client_ID'] != null
        ?  IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ?  IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    isDefault = json['IsDefault'];
    code = json['Code'];
    name = json['Name'];
    isActive = json['IsActive'];
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    updated = json['Updated'];
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'];

  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    data['Created'] = created;
    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }
    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }
    data['IsDefault'] = isDefault;
    data['Code'] = code;
    data['Name'] = name;
    data['IsActive'] = isActive;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    data['Updated'] = updated;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category;
    return data;
  }
  static List<IdempierePrintColor> fromJsonList(List<dynamic> list){
    List<IdempierePrintColor> result =[];
    for (var item in list) {
      if(item is IdempierePrintColor){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePrintColor idempierePrintColor = IdempierePrintColor.fromJson(item);
        result.add(idempierePrintColor);
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


























