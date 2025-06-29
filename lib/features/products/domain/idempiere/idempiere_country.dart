import 'idempiere_organization.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_language.dart';
import 'idempiere_object.dart';
import 'idempiere_tenant.dart';

class IdempiereCountry extends IdempiereObject {
  @override
  int? id;
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? description;
  String? countryCode;
  bool? hasRegion;
  String? displaySequence;
  bool? hasPostalAdd;
  IdempiereObject? cCurrencyID;
  IdempiereLanguage? aDLanguage;
  bool? isAddressLinesLocalReverse;
  bool? isAddressLinesReverse;
  bool? isPostcodeLookup;
  bool? allowCitiesOutOfList;
  String? captureSequence;
  String? countryCode3;
  bool? hasCommunity;
  bool? hasMunicipality;
  bool? hasParish;
  String? mOLIALP3CountryCode;
  @override
  String? modelName;

  IdempiereCountry(
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
        this.countryCode,
        this.hasRegion,
        this.displaySequence,
        this.hasPostalAdd,
        this.cCurrencyID,
        this.aDLanguage,
        this.isAddressLinesLocalReverse,
        this.isAddressLinesReverse,
        this.isPostcodeLookup,
        this.allowCitiesOutOfList,
        this.captureSequence,
        this.countryCode3,
        this.hasCommunity,
        this.hasMunicipality,
        this.hasParish,
        this.mOLIALP3CountryCode,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,
      });

  IdempiereCountry.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
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
    name = json['Name'];
    description = json['Description'];
    countryCode = json['CountryCode'];
    hasRegion = json['HasRegion'];
    displaySequence = json['DisplaySequence'];
    hasPostalAdd = json['HasPostal_Add'];
    cCurrencyID = json['C_Currency_ID'] != null
        ? IdempiereObject.fromJson(json['C_Currency_ID'])
        : null;
    aDLanguage = json['AD_Language'] != null
        ? IdempiereLanguage.fromJson(json['AD_Language'])
        : null;
    isAddressLinesLocalReverse = json['IsAddressLinesLocalReverse'];
    isAddressLinesReverse = json['IsAddressLinesReverse'];
    isPostcodeLookup = json['IsPostcodeLookup'];
    allowCitiesOutOfList = json['AllowCitiesOutOfList'];
    captureSequence = json['CaptureSequence'];
    countryCode3 = json['CountryCode3'];
    hasCommunity = json['HasCommunity'];
    hasMunicipality = json['HasMunicipality'];
    hasParish = json['HasParish'];
    mOLIALP3CountryCode = json['MOLI_ALP3CountryCode'];
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
    data['CountryCode'] = countryCode;
    data['HasRegion'] = hasRegion;
    data['DisplaySequence'] = displaySequence;
    data['HasPostal_Add'] = hasPostalAdd;
    if (cCurrencyID != null) {
      data['C_Currency_ID'] = cCurrencyID!.toJson();
    }
    if (aDLanguage != null) {
      data['AD_Language'] = aDLanguage!.toJson();
    }
    data['IsAddressLinesLocalReverse'] = isAddressLinesLocalReverse;
    data['IsAddressLinesReverse'] = isAddressLinesReverse;
    data['IsPostcodeLookup'] = isPostcodeLookup;
    data['AllowCitiesOutOfList'] = allowCitiesOutOfList;
    data['CaptureSequence'] = captureSequence;
    data['CountryCode3'] = countryCode3;
    data['HasCommunity'] = hasCommunity;
    data['HasMunicipality'] = hasMunicipality;
    data['HasParish'] = hasParish;
    data["MOLI_ALP3CountryCode"] = mOLIALP3CountryCode;
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category;
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    return data;
  }
  static List<IdempiereCountry> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereCountry.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereCountry.fromJson(item)).toList();
    }

    List<IdempiereCountry> newList =[];
    for (var item in json) {
      if(item is IdempiereCountry){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereCountry idempiereCountry = IdempiereCountry.fromJson(item);
        newList.add(idempiereCountry);
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
    if(aDLanguage?.name != null){
      list.add(aDLanguage?.name ?? '--');
    }
    if(countryCode != null){
      list.add(countryCode!);
    }
    return list;
  }
}



