import 'idempiere_business_partner.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';
import 'object_with_name_and_id.dart';

class IdempiereBusinessPartnerLocation extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  IdempiereBusinessPartner? cBPartnerID;
  bool? isBillTo;
  bool? isShipTo;
  bool? isPayFrom;
  bool? isRemitTo;
  bool? isPreserveCustomName;
  int? mOLICBPartnerLocationID;

  IdempiereBusinessPartnerLocation(
      { 
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.cBPartnerID,
        this.isBillTo,
        this.isShipTo,
        this.isPayFrom,
        this.isRemitTo,
        this.isPreserveCustomName,
        this.mOLICBPartnerLocationID,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,
      });

  IdempiereBusinessPartnerLocation.fromJson(Map<String, dynamic> json) {
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
    cBPartnerID = json['C_BPartner_ID'] != null
        ?  IdempiereBusinessPartner.fromJson(json['C_BPartner_ID'])
        : null;
    name = json['Name'];
    isBillTo = json['IsBillTo'];
    isShipTo = json['IsShipTo'];
    isPayFrom = json['IsPayFrom'];
    isRemitTo = json['IsRemitTo'];
    isPreserveCustomName = json['IsPreserveCustomName'];
    mOLICBPartnerLocationID = json['MOLI_C_BPartner_Location_ID'];
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
    if (cBPartnerID != null) {
      data['C_BPartner_ID'] = cBPartnerID!.toJson();
    }
    data['Name'] = name;
    data['IsBillTo'] = isBillTo;
    data['IsShipTo'] = isShipTo;
    data['IsPayFrom'] = isPayFrom;
    data['IsRemitTo'] = isRemitTo;
    data['IsPreserveCustomName'] = isPreserveCustomName;
    data['MOLI_C_BPartner_Location_ID'] = mOLICBPartnerLocationID;
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    return data;
  }

  static List<IdempiereBusinessPartnerLocation> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereBusinessPartnerLocation.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereBusinessPartnerLocation.fromJson(item)).toList();
    }

    List<IdempiereBusinessPartnerLocation> list =[];
    for (var item in json) {
      if(item is IdempiereBusinessPartnerLocation){
        list.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereBusinessPartnerLocation idempiereBusinessPartner = IdempiereBusinessPartnerLocation.fromJson(item);
        list.add(idempiereBusinessPartner);
      }
    }

    return list;
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
    if(modelName != null){
      list.add(modelName!);
    }
    return list;
  }
}



