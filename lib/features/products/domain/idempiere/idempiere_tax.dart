import '../../../shared/data/memory.dart';
import 'idempiere_country.dart';
import 'idempiere_tax_category.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_sopo_type.dart';
import 'idempiere_tax_posting_indicator_type.dart';
import 'object_with_name_and_id.dart';

class IdempiereTax extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? description;
  IdempiereTax? parentTaxID;
  IdempiereCountry? cCountryID;
  IdempiereCountry? toCountryID;
  IdempiereTaxCategory? cTaxCategoryID;
  String? updated;
  IdempiereUser? updatedBy;
  bool? isDocumentLevel;
  String? validFrom;
  bool? isSummary;
  double? rate;
  bool? requiresTaxCertificate;
  String? taxIndicator;
  bool? isDefault;
  bool? isTaxExempt;
  IdempiereSOPOType? sOPOType;
  bool? isSalesTax;
  IdempiereTaxPostingIndicator? taxPostingIndicator;
  int? mOLICTaxID;

  IdempiereTax(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.description,
        this.parentTaxID,
        this.cCountryID,
        this.toCountryID,
        this.cTaxCategoryID,
        this.updated,
        this.updatedBy,
        this.isDocumentLevel,
        this.validFrom,
        this.isSummary,
        this.rate,
        this.requiresTaxCertificate,
        this.taxIndicator,
        this.isDefault,
        this.isTaxExempt,
        this.sOPOType,
        this.isSalesTax,
        this.taxPostingIndicator,
        this.mOLICTaxID,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
      });

  IdempiereTax.fromJson(Map<String, dynamic> json) {
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
    name = json['Name'];
    description = json['Description'];
    parentTaxID = json['Parent_Tax_ID'] != null
        ?  IdempiereTax.fromJson(json['Parent_Tax_ID'])
        : null;
    cCountryID = json['C_Country_ID'] != null
        ?  IdempiereCountry.fromJson(json['C_Country_ID'])
        : null;
    toCountryID = json['To_Country_ID'] != null
        ?  IdempiereCountry.fromJson(json['To_Country_ID'])
        : null;
    cTaxCategoryID = json['C_TaxCategory_ID'] != null
        ?  IdempiereTaxCategory.fromJson(json['C_TaxCategory_ID'])
        : null;
    updated = json['Updated'];
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    isDocumentLevel = json['IsDocumentLevel'];
    validFrom = json['ValidFrom'];
    isSummary = json['IsSummary'];
    rate = json['Rate']!= null ? double.tryParse(json['Rate'].toString()) : null;
    requiresTaxCertificate = json['RequiresTaxCertificate'];
    taxIndicator = json['TaxIndicator'];
    isDefault = json['IsDefault'];
    isTaxExempt = json['IsTaxExempt'];
    sOPOType = json['SOPOType'] != null
        ?  IdempiereSOPOType.fromJson(json['SOPOType'])
        : null;
    isSalesTax = json['IsSalesTax'];
    taxPostingIndicator = json['TaxPostingIndicator'] != null
        ?  IdempiereTaxPostingIndicator.fromJson(json['TaxPostingIndicator'])
        : null;
    mOLICTaxID = json['MOLI_C_Tax_ID'];
    modelName = json['model-name'];
    active = json['active'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
    propertyLabel = json['propertyLabel'];
    image = json['image'];
    identifier = json['identifier'];
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
    data['Name'] = name;
    data['Description'] = description;
    if (parentTaxID != null) {
      data['Parent_Tax_ID'] = parentTaxID!.toJson();
    }
    if (cCountryID != null) {
      data['C_Country_ID'] = cCountryID!.toJson();
    }
    if (toCountryID != null) {
      data['To_Country_ID'] = toCountryID!.toJson();
    }
    if (cTaxCategoryID != null) {
      data['C_TaxCategory_ID'] = cTaxCategoryID!.toJson();
    }
    data['Updated'] = updated;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    data['IsDocumentLevel'] = isDocumentLevel;
    data['ValidFrom'] = validFrom;
    data['IsSummary'] = isSummary;
    data['Rate'] = rate;
    data['RequiresTaxCertificate'] = requiresTaxCertificate;
    data['TaxIndicator'] = taxIndicator;
    data['IsDefault'] = isDefault;
    data['IsTaxExempt'] = isTaxExempt;
    if (sOPOType != null) {
      data['SOPOType'] = sOPOType!.toJson();
    }
    data['IsSalesTax'] = isSalesTax;
    if (taxPostingIndicator != null) {
      data['TaxPostingIndicator'] = taxPostingIndicator!.toJson();
    }
    data['MOLI_C_Tax_ID'] = mOLICTaxID;
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    data['identifier'] = identifier;
    return data;
  }
  static List<IdempiereTax> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereTax.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereTax.fromJson(item)).toList();
    }

    List<IdempiereTax> newList =[];
    for (var item in json) {
      if(item is IdempiereTax){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereTax idempiereTax = IdempiereTax.fromJson(item);
        newList.add(idempiereTax);
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
    if(description != null){
      list.add(description!);
    }
    if(rate != null){
      String rateString = Memory.numberFormatter2Digit.format(rate!);
      list.add('${Messages.RATE}: $rateString');
    }
    return list;
  }
}


