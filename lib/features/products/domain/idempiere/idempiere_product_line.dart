import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';

class IdempiereProductLine extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  bool? isActive;
  IdempiereProductLine? mOLIProductLineID;
  String? mOLILineSymbol;
  bool? mOLIIsApproval;
  bool? mOLIIsWHS;
  bool? mOLIIsLocalVendor;
  int? mOLILocalVendorRate;
  int? mOLIRTLCommissionRate;
  int? mOLIWHSCommissionRate;

  IdempiereProductLine(
      {
        uid,
        aDClientID,
        aDOrgID,
        created,
        createdBy,
        updated,
        updatedBy,
        isActive,
        mOLIProductLineID,
        mOLILineSymbol,
        mOLIIsApproval,
        mOLIIsWHS,
        mOLIIsLocalVendor,
        mOLILocalVendorRate,
        mOLIRTLCommissionRate,
        mOLIWHSCommissionRate,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
      });

  IdempiereProductLine.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    aDClientID = json['AD_Client_ID'] != null
        ?  IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ?  IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    created = json['Created'];
    createdBy = json['CreatedBy'] != null
        ?  IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    updated = json['Updated'];
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    isActive = json['IsActive'];
    name = json['Name'];
    mOLIProductLineID = json['MOLI_ProductLine_ID'] != null
        ?  IdempiereProductLine.fromJson(json['MOLI_ProductLine_ID'])
        : null;
    mOLILineSymbol = json['MOLI_LineSymbol'];
    mOLIIsApproval = json['MOLI_isApproval'];
    mOLIIsWHS = json['MOLI_isWHS'];
    mOLIIsLocalVendor = json['MOLI_IsLocalVendor'];
    mOLILocalVendorRate = json['MOLI_LocalVendorRate'];
    mOLIRTLCommissionRate = json['MOLI_RTLCommissionRate'];
    mOLIWHSCommissionRate = json['MOLI_WHSCommissionRate'];
    modelName = json['model-name'];
    identifier = json['identifier'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    id = json['id'];
    name = json['name'];
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
    if (mOLIProductLineID != null) {
      data['MOLI_ProductLine_ID'] = mOLIProductLineID!.toJson();
    }
    data['MOLI_LineSymbol'] = mOLILineSymbol;
    data['MOLI_isApproval'] = mOLIIsApproval;
    data['MOLI_isWHS'] = mOLIIsWHS;
    data['MOLI_IsLocalVendor'] = mOLIIsLocalVendor;
    data['MOLI_LocalVendorRate'] = mOLILocalVendorRate;
    data['MOLI_RTLCommissionRate'] = mOLIRTLCommissionRate;
    data['MOLI_WHSCommissionRate'] = mOLIWHSCommissionRate;
    data['model-name'] = modelName;
    data['identifier'] = identifier;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['id'] = id;
    data['name'] = name;
    return data;
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
    if(mOLILineSymbol != null){
      list.add(mOLILineSymbol!);
    }
    if(modelName != null){
      list.add(modelName!);
    }
    return list;
  }
  static List<IdempiereProductLine> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereProductLine.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereProductLine.fromJson(item)).toList();
    } else {
      // Handle other cases or throw an error if the json format is unexpected.
      // For now, returning an empty list.
      return [];
    }
  }
}


