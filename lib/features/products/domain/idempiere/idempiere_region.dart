import 'idempiere_country.dart';
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'object_with_name_and_id.dart';

class IdempiereRegion extends IdempiereObject  {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? description;
  IdempiereCountry? cCountryID;
  bool? isDefault;

  IdempiereRegion(
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
        this.cCountryID,
        this.isDefault,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,

      });

  IdempiereRegion.fromJson(Map<String, dynamic> json) {
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
    description = json['Description'];
    cCountryID = json['C_Country_ID'] != null
        ?  IdempiereCountry.fromJson(json['C_Country_ID'])
        : null;
    isDefault = json['IsDefault'];
    modelName = json['model-name'];
    active = json['active'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
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
    if (cCountryID != null) {
      data['C_Country_ID'] = cCountryID!.toJson();
    }
    data['IsDefault'] = isDefault;
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    return data;
  }
  static List<IdempiereRegion> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereRegion.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereRegion.fromJson(item)).toList();
    }

    List<IdempiereRegion> newList =[];
    for (var item in json) {
      if(item is IdempiereRegion){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereRegion idempiereRegion = IdempiereRegion.fromJson(item);
        newList.add(idempiereRegion);
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
    if( cCountryID?.name != null){
      list.add(cCountryID?.name ?? '--');
    }
    return list;
  }
}
