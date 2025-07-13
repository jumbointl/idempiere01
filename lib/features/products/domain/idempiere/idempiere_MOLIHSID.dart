
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';




class IdempiereMOLIHSID extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  bool? isActive;
  String? value;
  String? description;
  String? mOLIHSChapter;
  String? mOLIHSSubHeading;
  String? mOLIHSSubHeadingExt;
  int? mOLIHSTariff;
  int? mOLIHSTariffN;
  int? mOLIHSVat;
  int? mOLIHSSalesTax;
  double? mOLIHSIncomeTax;
  int? mOLIHSIncomeCharge;
  int? mOLIHSSelectiveTax;
  int? mOLIHSSelectiveTaxSND;
  int? mOLIHSOtherTax;

  IdempiereMOLIHSID(
      { 
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.isActive,
        this.value,
        this.description,
        this.mOLIHSChapter,
        this.mOLIHSSubHeading,
        this.mOLIHSSubHeadingExt,
        this.mOLIHSTariff,
        this.mOLIHSTariffN,
        this.mOLIHSVat,
        this.mOLIHSSalesTax,
        this.mOLIHSIncomeTax,
        this.mOLIHSIncomeCharge,
        this.mOLIHSSelectiveTax,
        this.mOLIHSSelectiveTaxSND,
        this.mOLIHSOtherTax,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
      });

  IdempiereMOLIHSID.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    created = json['Created'];
    createdBy = json['CreatedBy'] != null
        ? IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    updated = json['Updated'];
    updatedBy = json['UpdatedBy'] != null
        ? IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    isActive = json['IsActive'];
    value = json['Value'];
    name = json['Name'];
    description = json['Description'];
    mOLIHSChapter = json['MOLI_HSChapter'];
    mOLIHSSubHeading = json['MOLI_HSSubHeading'];
    mOLIHSSubHeadingExt = json['MOLI_HSSubHeadingExt'];
    mOLIHSTariff = json['MOLI_HSTariff'];
    mOLIHSTariffN = json['MOLI_HSTariffN'];
    mOLIHSVat = json['MOLI_HSVat'];
    mOLIHSSalesTax = json['MOLI_HSSalesTax'];
    mOLIHSIncomeTax = json['MOLI_HSIncomeTax'];
    mOLIHSIncomeCharge = json['MOLI_HSIncomeCharge'];
    mOLIHSSelectiveTax = json['MOLI_HSSelectiveTax'];
    mOLIHSSelectiveTaxSND = json['MOLI_HSSelectiveTaxSND'];
    mOLIHSOtherTax = json['MOLI_HSOtherTax'];
    modelName = json['model-name'];
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
    data['Created'] = created;
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    data['Updated'] = updated;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    data['IsActive'] = isActive;
    data['Value'] = value;
    data['Name'] = name;
    data['Description'] = description;
    data['MOLI_HSChapter'] = mOLIHSChapter;
    data['MOLI_HSSubHeading'] = mOLIHSSubHeading;
    data['MOLI_HSSubHeadingExt'] = mOLIHSSubHeadingExt;
    data['MOLI_HSTariff'] = mOLIHSTariff;
    data['MOLI_HSTariffN'] = mOLIHSTariffN;
    data['MOLI_HSVat'] = mOLIHSVat;
    data['MOLI_HSSalesTax'] = mOLIHSSalesTax;
    data['MOLI_HSIncomeTax'] = mOLIHSIncomeTax;
    data['MOLI_HSIncomeCharge'] = mOLIHSIncomeCharge;
    data['MOLI_HSSelectiveTax'] = mOLIHSSelectiveTax;
    data['MOLI_HSSelectiveTaxSND'] = mOLIHSSelectiveTaxSND;
    data['MOLI_HSOtherTax'] = mOLIHSOtherTax;
    data['model-name'] = modelName;
    return data;
  }

  static List<IdempiereMOLIHSID> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereMOLIHSID.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereMOLIHSID.fromJson(item)).toList();
    }

    List<IdempiereMOLIHSID> newList =[];
    for (var item in json) {
      if(item is IdempiereMOLIHSID){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereMOLIHSID idempiereProductBrand = IdempiereMOLIHSID.fromJson(item);
        newList.add(idempiereProductBrand);
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
      list.add('${Messages.NAME}: ${name?? '--'}');
    }
    if(value != null){
      list.add('${Messages.VALUE}: ${value?? '--'}');
    }
    return list;
  }
}


