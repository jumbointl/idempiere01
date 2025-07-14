import 'package:idempiere_rest/idempiere_rest.dart';

import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';

class IdempiereOrganization extends IdempiereObject {
  String? uid;
  String? description;
  IdempiereTenant? aDClientID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? value;
  bool? isSummary;
  int? mOLIADOrgID;

  IdempiereOrganization(
      {
        this.uid,
        this.description,
        this.aDClientID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.value,
        this.isSummary,
        this.mOLIADOrgID,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName = 'ad_org',
        super.category,
      });

  IdempiereOrganization.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    name = json['Name'];
    description = json['Description'];
    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
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
    value = json['Value'];
    isSummary = json['IsSummary'];
    mOLIADOrgID = json['MOLI_AD_Org_ID'];
    modelName = json['model-name'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    id = json['id'];
    name = json['Name'];
    active = json['Active'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['Name'] = name;
    data['Description'] = description;
    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
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
    data['Value'] = value;
    data['IsSummary'] = isSummary;
    data['MOLI_AD_Org_ID'] = mOLIADOrgID;
    data['model-name'] = modelName;
    return data;
  }
  static List<IdempiereOrganization> fromJsonList(List<dynamic> list){
    List<IdempiereOrganization> newList =[];
    for (var item in list) {
      if(item is IdempiereOrganization){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereOrganization idempiereOrganization = IdempiereOrganization.fromJson(item);
        newList.add(idempiereOrganization);
      } else if(item is Organization){
        IdempiereOrganization idempiereOrganization = IdempiereOrganization(id: item.id, name: item.name);
        newList.add(idempiereOrganization);
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
      list.add('${Messages.DESCRIPTION}: ${description ?? '--'}');
    }
    return list;
  }
}

