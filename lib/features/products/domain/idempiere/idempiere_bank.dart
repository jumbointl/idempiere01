import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'idempiere_user.dart';
import 'object_with_name_and_id.dart';

class IdempiereBank extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? routingNo;
  String? swiftCode;
  bool? isOwnBank;
  int? mOLICBankID;

  IdempiereBank(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.routingNo,
        this.swiftCode,
        this.isOwnBank,
        this.mOLICBankID,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
      });

  IdempiereBank.fromJson(Map<String, dynamic> json) {
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
    routingNo = json['RoutingNo'];
    swiftCode = json['SwiftCode'];
    isOwnBank = json['IsOwnBank'];
    mOLICBankID = json['MOLI_C_Bank_ID'];
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;;
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
    data['RoutingNo'] = routingNo;
    data['SwiftCode'] = swiftCode;
    data['IsOwnBank'] = isOwnBank;
    data['MOLI_C_Bank_ID'] = mOLICBankID;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    return data;
  }
  static List<IdempiereBank> fromJsonList(List<dynamic> list){
    List<IdempiereBank> result =[];
    for (var item in list) {
      if(item is IdempiereBank){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereBank idempiereBank = IdempiereBank.fromJson(item);
        result.add(idempiereBank);
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

    return list;
  }
}


