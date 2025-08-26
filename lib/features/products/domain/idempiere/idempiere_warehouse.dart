import 'package:idempiere_rest/idempiere_rest.dart';

import 'idempiere_location.dart';
import 'idempiere_locator.dart';
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';

class IdempiereWarehouse extends IdempiereObject  {
  String? uid;
  IdempiereLocation? cLocationID;
  IdempiereOrganization? aDOrgID;
  IdempiereTenant? aDClientID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? value;
  String? separator;
  bool? isInTransit;
  bool? isDisallowNegativeInv;
  IdempiereLocator? mReserveLocatorID;

  IdempiereWarehouse(
      {
        this.uid,
        this.cLocationID,
        this.aDOrgID,
        this.aDClientID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.value,
        this.separator,
        this.isInTransit,
        this.isDisallowNegativeInv,
        this.mReserveLocatorID,
        super.id,
        super.name,
        super.modelName = 'm_warehouse',
        super.active,
        super.category,
      });

  IdempiereWarehouse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    name = json['Name'];
    //print('---------------------------------------2');
    cLocationID = json['C_Location_ID'] != null
        ? IdempiereLocation.fromJson(json['C_Location_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
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
    separator = json['Separator'];
    isInTransit = json['IsInTransit'];
    isDisallowNegativeInv = json['IsDisallowNegativeInv'];
    mReserveLocatorID = json['M_ReserveLocator_ID'] != null
        ? IdempiereLocator.fromJson(json['M_ReserveLocator_ID'])
        : null;
    modelName = json['model-name'];
    active = json['active'];
    category = json['category'];
    identifier = json['identifier'];
    propertyLabel = json['propertyLabel'];
    image = json['image'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['Name'] = name;
    if (cLocationID != null) {
      data['C_Location_ID'] = cLocationID!.toJson();
    }
    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }
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
    data['Separator'] = separator;
    data['IsInTransit'] = isInTransit;
    data['IsDisallowNegativeInv'] = isDisallowNegativeInv;
    if (mReserveLocatorID != null) {
      data['M_ReserveLocator_ID'] = mReserveLocatorID!.toJson();
    }
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category;
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    return data;
  }
  static List<IdempiereWarehouse> fromJsonList(List<dynamic> list){
    List<IdempiereWarehouse> newList =[];
    for (var item in list) {
      if(item is IdempiereWarehouse){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereWarehouse idempiereWarehouse = IdempiereWarehouse.fromJson(item);
        newList.add(idempiereWarehouse);
      } else if(item is Warehouse){
        IdempiereWarehouse idempiereWarehouse = IdempiereWarehouse(id: item.id, name: item.name);
        newList.add(idempiereWarehouse);
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
    if(value != null){
      list.add('${Messages.VALUE}: ${value ?? '--'}');
    }
    return list;
  }
}


