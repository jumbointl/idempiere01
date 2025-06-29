
import 'idempiere_currency.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';

class IdempierePriceList extends IdempiereObject{
  
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? description;
  IdempiereCurrency? cCurrencyID;
  bool? isSOPriceList;
  bool? enforcePriceLimit;
  bool? isTaxIncluded;
  bool? isDefault;
  int? pricePrecision;
  bool? isPresentForProduct;
  bool? isMandatory;
  int? mOLIMPriceListID;

  IdempierePriceList({
      
       this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.description,
        this.cCurrencyID,
        this.isSOPriceList,
        this.enforcePriceLimit,
        this.isTaxIncluded,
        this.isDefault,
        this.pricePrecision,
        this.isPresentForProduct,
        this.isMandatory,
        this.mOLIMPriceListID,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.category,
        super.image,
  }
  );

  IdempierePriceList.fromJson(Map<String, dynamic> json) {
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
    cCurrencyID = json['C_Currency_ID'] != null
        ?  IdempiereCurrency.fromJson(json['C_Currency_ID'])
        : null;
    isSOPriceList = json['IsSOPriceList'];
    enforcePriceLimit = json['EnforcePriceLimit'];
    isTaxIncluded = json['IsTaxIncluded'];
    isDefault = json['IsDefault'];
    pricePrecision = json['PricePrecision'];
    isPresentForProduct = json['isPresentForProduct'];
    isMandatory = json['IsMandatory'];
    mOLIMPriceListID = json['MOLI_M_PriceList_ID'];
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
    if (cCurrencyID != null) {
      data['C_Currency_ID'] = cCurrencyID!.toJson();
    }
    data['IsSOPriceList'] = isSOPriceList;
    data['EnforcePriceLimit'] = enforcePriceLimit;
    data['IsTaxIncluded'] = isTaxIncluded;
    data['IsDefault'] = isDefault;
    data['PricePrecision'] = pricePrecision;
    data['isPresentForProduct'] = isPresentForProduct;
    data['IsMandatory'] = isMandatory;
    data['MOLI_M_PriceList_ID'] = mOLIMPriceListID;
    data['model-name'] = modelName;
    return data;
  }

 
  static List<IdempierePriceList> fromJsonList(List<dynamic> list){
    List<IdempierePriceList> result =[];
    for (var item in list) {
      if(item is IdempierePriceList){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePriceList idempierePriceList = IdempierePriceList.fromJson(item);
        result.add(idempierePriceList);
      }
    }
    return result;
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
    return list;
  }
}