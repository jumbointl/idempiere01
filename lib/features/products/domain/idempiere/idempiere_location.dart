import 'idempiere_object.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_country.dart';
import 'idempiere_organization.dart';
import 'idempiere_region.dart';
import 'object_with_name_and_id.dart';

class IdempiereLocation extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? address1;
  String? city;
  IdempiereCountry? cCountryID;
  IdempiereRegion? cRegionID;
  String? postal;
  bool? isValid;

  IdempiereLocation(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.address1,
        this.city,
        this.cCountryID,
        this.cRegionID,
        this.postal,
        this.isValid,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,
        
      });

  IdempiereLocation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    isActive = getBoolFromJson(json['IsActive']);
    created = json['Created'];
    if(json['CreatedBy'] !=null){
     if(json['CreatedBy'] is Map<String, dynamic>){
       createdBy = IdempiereUser.fromJson(json['CreatedBy']);
     } else if(json['CreatedBy'] is String){
       int? aux = int.tryParse(json['CreatedBy']);
       if(aux!=null){
         createdBy = IdempiereUser(id: aux,propertyLabel: "Created By",name: '');
       }
     } else if(json['CreatedBy'] is int){
       createdBy = IdempiereUser(id: json['CreatedBy'],propertyLabel: "Created By",name: '');
     }
    }

    updated = json['Updated'];
    if(json['UpdatedBy'] !=null){
      if(json['UpdatedBy'] is Map<String, dynamic>){
        updatedBy = IdempiereUser.fromJson(json['UpdatedBy']);
      } else if(json['UpdatedBy'] is String){
        int? aux = int.tryParse(json['UpdatedBy']);
        if(aux!=null){
          updatedBy = IdempiereUser(id: aux,propertyLabel: "Updated By",identifier: '');
        }
      } else if(json['UpdatedBy'] is int){
        updatedBy = IdempiereUser(id: json['UpdatedBy'],propertyLabel: "Updated By",identifier: '');
      }
    }

    address1 = json['Address1'];
    city = json['City'];
    cCountryID = json['C_Country_ID'] != null
        ? IdempiereCountry.fromJson(json['C_Country_ID'])
        : null;
    cRegionID = json['C_Region_ID'] != null
        ? IdempiereRegion.fromJson(json['C_Region_ID'])
        : null;
    postal = json['Postal'];
    isValid = getBoolFromJson(json['IsValid']);
    modelName = json['model-name'];
    active = json['active'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
    identifier = json['identifier'];
    propertyLabel = json['propertyLabel'];
    image = json['image'];
    name = json['name'];
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
    data['Address1'] = address1;
    data['City'] = city;
    if (cCountryID != null) {
      data['C_Country_ID'] = cCountryID!.toJson();
    }
    if (cRegionID != null) {
      data['C_Region_ID'] = cRegionID!.toJson();
    }
    data['Postal'] = postal;
    data['IsValid'] = isValid;
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    data['name'] = name;
    return data;
  }
  static List<IdempiereLocation> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereLocation.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereLocation.fromJson(item)).toList();
    }

    List<IdempiereLocation> newList =[];
    for (var item in json) {
      if(item is IdempiereLocation){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereLocation idempiereLocation = IdempiereLocation.fromJson(item);
        newList.add(idempiereLocation);
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
    if(address1 != null){
      list.add('${Messages.ADDRESS}: ${address1 ?? '--'}');
    }
    if( city != null){
      list.add(city ?? '--');
    }
    return list;
  }
}


