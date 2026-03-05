import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_tax_category.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';
import 'object_with_name_and_id.dart';

class IdempiereCharge extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? description;
  double? chargeAmt;
  bool? isSameTax;
  IdempiereTaxCategory? cTaxCategoryID;
  bool? isSameCurrency;
  bool? isTaxIncluded;
  int? moliCChargeID;

  IdempiereCharge({
    this.uid,
    this.aDClientID,
    this.aDOrgID,
    this.isActive,
    this.created,
    this.createdBy,
    this.updated,
    this.updatedBy,
    this.description,
    this.chargeAmt,
    this.isSameTax,
    this.cTaxCategoryID,
    this.isSameCurrency,
    this.isTaxIncluded,
    this.moliCChargeID,
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName = 'c_charge',
    super.image,
    super.category,
  });

  IdempiereCharge.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];

    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;

    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;

    isActive = getBoolFromJson(json['IsActive']);
    active = getBoolFromJson(json['IsActive']);

    created = json['Created'];

    createdBy = json['CreatedBy'] != null
        ? IdempiereUser.fromJson(json['CreatedBy'])
        : null;

    updated = json['Updated'];

    updatedBy = json['UpdatedBy'] != null
        ? IdempiereUser.fromJson(json['UpdatedBy'])
        : null;

    name = json['Name'];
    description = json['Description'];

    chargeAmt = json['ChargeAmt'] != null
        ? double.tryParse(json['ChargeAmt'].toString())
        : null;

    isSameTax = getBoolFromJson(json['IsSameTax']);

    cTaxCategoryID = json['C_TaxCategory_ID'] != null
        ? IdempiereTaxCategory.fromJson(json['C_TaxCategory_ID'])
        : null;

    isSameCurrency = getBoolFromJson(json['IsSameCurrency']);
    isTaxIncluded = getBoolFromJson(json['IsTaxIncluded']);
    moliCChargeID = json['MOLI_C_Charge_ID'];

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

    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }

    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }

    data['IsActive'] = isActive;
    data['active'] = active;
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
    data['ChargeAmt'] = chargeAmt;
    data['IsSameTax'] = isSameTax;

    if (cTaxCategoryID != null) {
      data['C_TaxCategory_ID'] = cTaxCategoryID!.toJson();
    }

    data['IsSameCurrency'] = isSameCurrency;
    data['IsTaxIncluded'] = isTaxIncluded;
    data['MOLI_C_Charge_ID'] = moliCChargeID;

    data['model-name'] = modelName;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['name'] = name;

    return data;
  }
}