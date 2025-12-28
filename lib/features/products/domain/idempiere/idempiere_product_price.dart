import 'idempiere_organization.dart';
import 'idempiere_price_list_version.dart';
import 'idempiere_product.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'object_with_name_and_id.dart';

class IdempiereProductPrice extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  IdempiereProduct? mProductID;
  IdempierePriceListVersion? mPriceListVersionID;
  double? priceList;
  double? priceStd;
  double? priceLimit;

  IdempiereProductPrice(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.mProductID,
        this.mPriceListVersionID,
        this.priceList,
        this.priceStd,
        this.priceLimit,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,
      });

  IdempiereProductPrice.fromJson(Map<String, dynamic> json) {
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
    mProductID = json['M_Product_ID'] != null
        ?  IdempiereProduct.fromJson(json['M_Product_ID'])
        : null;
    mPriceListVersionID = json['M_PriceList_Version_ID'] != null
        ?  IdempierePriceListVersion.fromJson(json['M_PriceList_Version_ID'])
        : null;
    priceList = json['PriceList']!=null ? double.tryParse(json['PriceList'].toString()) : null;
    priceStd = json['PriceStd'] != null ? double.tryParse(json['PriceStd'].toString()) : null;
    priceLimit = json['PriceLimit']!=null ? double.tryParse(json['PriceLimit'].toString()) : null;
    modelName = json['model-name'];
    active = json['active'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
    identifier = json['identifier'];
    propertyLabel = json['propertyLabel'];
    image = json['image'];
    name = json['Name'];
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
    if (mProductID != null) {
      data['M_Product_ID'] = mProductID!.toJson();
    }
    if (mPriceListVersionID != null) {
      data['M_PriceList_Version_ID'] = mPriceListVersionID!.toJson();
    }
    data['PriceList'] = priceList;
    data['PriceStd'] = priceStd;
    data['PriceLimit'] = priceLimit;
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    data['Name'] = name;
    return data;
  }
  static List<IdempiereProductPrice> fromJsonList(List<dynamic> list){
    List<IdempiereProductPrice> resultList =[];
    for (var item in list) { // Iterate over the input list, not the resultList
      if(item is IdempiereProductPrice){
        resultList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereProductPrice idempiereProductPrice = IdempiereProductPrice.fromJson(item);
        resultList.add(idempiereProductPrice);
      }

    }
    return resultList;
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
    if(mProductID != null){
      if (mProductID!.id != null){
        list.add('${Messages.PRODUCT} ${Messages.ID}: ${mProductID!.id ?? '--'}');
      }
      if(mProductID!.identifier != null){
        list.add('${Messages.NAME}: ${mProductID!.identifier ?? '--'}');
      }
    }
    if(priceList != null){
      list.add('${Messages.PRICE_LIST}: ${priceList ?? '--'}');
    }
    if(priceStd != null){
      list.add('${Messages.PRICE_STANDARD}: ${priceStd ?? '--'}');
    }
    if(priceLimit != null){
      list.add('${Messages.PRICE_LIMIT}: ${priceLimit ?? '--'}');
    }
    return list;
  }
}


