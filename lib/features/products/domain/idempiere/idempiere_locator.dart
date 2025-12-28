import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';
import 'idempiere_warehouse.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'object_with_name_and_id.dart';

class IdempiereLocator extends IdempiereObject  {
  String? uid;
  IdempiereOrganization? aDOrgID;
  IdempiereTenant? aDClientID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  IdempiereWarehouse? mWarehouseID;
  String? x;
  String? y;
  String? z;
  String? value;
  int? priorityNo;
  bool? isDefault;

  IdempiereLocator(
      {
        this.uid,
        this.aDOrgID,
        this.aDClientID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.mWarehouseID,
        this.x,
        this.y,
        this.z,
        this.value,
        this.priorityNo,
        this.isDefault,
        super.id,
        super.name,
        super.modelName='m_locator',
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,

      });

  IdempiereLocator.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
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
    mWarehouseID = json['M_Warehouse_ID'] != null
        ? IdempiereWarehouse.fromJson(json['M_Warehouse_ID'])
        : null;
    x = json['X'];
    y = json['Y'];
    z = json['Z'];
    value = json['Value'];
    priorityNo = json['PriorityNo'];
    isDefault = json['IsDefault'];
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
    if (mWarehouseID != null) {
      data['M_Warehouse_ID'] = mWarehouseID!.toJson();
    }
    data['X'] = x;
    data['Y'] = y;
    data['Z'] = z;
    data['Value'] = value;
    data['PriorityNo'] = priorityNo;
    data['IsDefault'] = isDefault;
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    data['name'] = name;
    return data;
  }
  static List<IdempiereLocator> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereLocator.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereLocator.fromJson(item)).toList();
    }

    List<IdempiereLocator> newList =[];
    for (var item in json) {
      if(item is IdempiereLocator){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereLocator idempiereLocator = IdempiereLocator.fromJson(item);
        newList.add(idempiereLocator);
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
    if(value != null){
      list.add('${Messages.VALUE}: ${value ?? '--'}');
    }
    return list;
  }
}


