import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';

class IdempiereCurrency extends IdempiereObject {
  String? uid;
  String? iSOCode;
  int? stdPrecision;
  String? description;
  int? costingPrecision;
  int? eMURate;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? curSymbol;
  bool? isEuro;
  bool? isEMUMember;

  IdempiereCurrency(
      {
        this.uid,
        this.iSOCode,
        this.stdPrecision,
        this.description,
        this.costingPrecision,
        this.eMURate,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.curSymbol,
        this.isEuro,
        this.isEMUMember,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,
        
      });

  IdempiereCurrency.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    iSOCode = json['ISO_Code'];
    stdPrecision = json['StdPrecision'];
    description = json['Description'];
    costingPrecision = json['CostingPrecision'];
    eMURate = json['EMURate'];
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
    curSymbol = json['CurSymbol'];
    isEuro = json['IsEuro'];
    isEMUMember = json['IsEMUMember'];
    modelName = json['model-name'];
    
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['ISO_Code'] = iSOCode;
    data['StdPrecision'] = stdPrecision;
    data['Description'] = description;
    data['CostingPrecision'] = costingPrecision;
    data['EMURate'] = eMURate;
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
    data['CurSymbol'] = curSymbol;
    data['IsEuro'] = isEuro;
    data['IsEMUMember'] = isEMUMember;
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    return data;
  }
  static List<IdempiereCurrency> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereCurrency.fromJson(json)];
    } else if (json is List<IdempiereCurrency>) {
      return json;
    } else if (json is List<dynamic>) {
      return json.map((item) => IdempiereCurrency.fromJson(item)).toList();
    }

    List<IdempiereCurrency> newList =[];
    for (var item in json) {
      if(item is IdempiereCurrency){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereCurrency idempiereCurrency = IdempiereCurrency.fromJson(item);
        newList.add(idempiereCurrency);
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
    if(description != null){
      list.add('${Messages.NAME}: ${description ?? '--'}');
    }
    if(curSymbol != null){
      list.add(curSymbol ?? '--');
    }
    return list;
  }
}


