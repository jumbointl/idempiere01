import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';
import 'object_with_name_and_id.dart';

class IdempiereConversionType extends IdempiereObject {
  String? uid;
  IdempiereUser? updatedBy;
  bool? isActive;
  IdempiereUser? createdBy;
  IdempiereTenant? aDClientID;
  String? updated;
  String? created;
  String? description;
  IdempiereOrganization? aDOrgID;
  bool? isDefault;
  String? value;

  IdempiereConversionType({
    this.uid,
    this.updatedBy,
    this.isActive,
    this.createdBy,
    this.aDClientID,
    this.updated,
    this.created,
    this.description,
    this.aDOrgID,
    this.isDefault,
    this.value,
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName = 'c_conversiontype',
    super.image,
    super.category,
  });

  IdempiereConversionType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];

    updatedBy = json['UpdatedBy'] != null
        ? IdempiereUser.fromJson(json['UpdatedBy'])
        : null;

    name = json['Name'];
    isActive = getBoolFromJson(json['IsActive']);
    active = getBoolFromJson(json['IsActive']);

    createdBy = json['CreatedBy'] != null
        ? IdempiereUser.fromJson(json['CreatedBy'])
        : null;

    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;

    updated = json['Updated'];
    created = json['Created'];
    description = json['Description'];

    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;

    isDefault = getBoolFromJson(json['IsDefault']);
    value = json['Value'];

    modelName = json['model-name'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'] ?? json['Name'];
    image = json['image'];
    category = json['category'] != null
        ? ObjectWithNameAndId.fromJson(json['category'])
        : null;
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['id'] = id;
    data['uid'] = uid;

    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }

    data['Name'] = name;
    data['IsActive'] = isActive;

    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }

    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }

    data['Updated'] = updated;
    data['Created'] = created;
    data['Description'] = description;

    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }

    data['IsDefault'] = isDefault;
    data['Value'] = value;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['name'] = name;

    return data;
  }
}