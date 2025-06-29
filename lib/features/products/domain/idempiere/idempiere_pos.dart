import 'idempiere_bank_account.dart';
import 'idempiere_cash_book.dart';
import 'idempiere_document_type.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_pos_key_layout.dart';
import 'idempiere_price_list.dart';
import 'idempiere_tenant.dart';
import 'idempiere_warehouse.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_user.dart';

class IdempierePOS extends IdempiereObject {
  String? uid;
  String? created;
  IdempiereUser? updatedBy;
  IdempiereOrganization? aDOrgID;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? cPOSKeyLayoutID;
  IdempiereTenant? aDClientID;
  IdempiereUser? salesRepID;
  IdempiereCashBook? cCashBookID;
  IdempiereWarehouse? mWarehouseID;
  IdempierePriceList? mPriceListID;
  bool? isActive;
  bool? isModifyPrice;
  IdempiereDocumentType? cDocTypeID;
  IdempiereBankAccount? cBankAccountID;
  IdempierePosKeyLayout? oSKKeyLayoutID;
  IdempierePosKeyLayout? oSNPKeyLayoutID;

  IdempierePOS(
      {
        this.uid,
        this.created,
        this.updatedBy,
        this.aDOrgID,
        this.createdBy,
        this.updated,
        this.cPOSKeyLayoutID,
        this.aDClientID,
        this.salesRepID,
        this.cCashBookID,
        this.mWarehouseID,
        this.mPriceListID,
        this.isActive,
        this.isModifyPrice,
        this.cDocTypeID,
        this.cBankAccountID,
        this.oSKKeyLayoutID,
        this.oSNPKeyLayoutID,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
      });

  IdempierePOS.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    created = json['Created'];
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ?  IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    createdBy = json['CreatedBy'] != null
        ?  IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    updated = json['Updated'];
    cPOSKeyLayoutID = json['C_POSKeyLayout_ID'] != null
        ?  IdempiereUser.fromJson(json['C_POSKeyLayout_ID'])
        : null;
    aDClientID = json['AD_Client_ID'] != null
        ?  IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    salesRepID = json['SalesRep_ID'] != null
        ?  IdempiereUser.fromJson(json['SalesRep_ID'])
        : null;
    name = json['Name'];
    cCashBookID = json['C_CashBook_ID'] != null
        ?  IdempiereCashBook.fromJson(json['C_CashBook_ID'])
        : null;
    mWarehouseID = json['M_Warehouse_ID'] != null
        ?  IdempiereWarehouse.fromJson(json['M_Warehouse_ID'])
        : null;
    mPriceListID = json['M_PriceList_ID'] != null
        ?  IdempierePriceList.fromJson(json['M_PriceList_ID'])
        : null;
    isActive = json['IsActive'];
    isModifyPrice = json['IsModifyPrice'];
    cDocTypeID = json['C_DocType_ID'] != null
        ?  IdempiereDocumentType.fromJson(json['C_DocType_ID'])
        : null;
    cBankAccountID = json['C_BankAccount_ID'] != null
        ?  IdempiereBankAccount.fromJson(json['C_BankAccount_ID'])
        : null;
    oSKKeyLayoutID = json['OSK_KeyLayout_ID'] != null
        ?  IdempierePosKeyLayout.fromJson(json['OSK_KeyLayout_ID'])
        : null;
    oSNPKeyLayoutID = json['OSNP_KeyLayout_ID'] != null
        ?  IdempierePosKeyLayout.fromJson(json['OSNP_KeyLayout_ID'])
        : null;
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'];
  }
  static List<IdempierePOS> fromJsonList(List<dynamic> list){
    List<IdempierePOS> result =[];
    for (var item in list) {
      if(item is IdempierePOS){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePOS idempierePOS = IdempierePOS.fromJson(item);
        result.add(idempierePOS);
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

    return list;
  }
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['Created'] = created;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    data['Updated'] = updated;
    if (cPOSKeyLayoutID != null) {
      data['C_POSKeyLayout_ID'] = cPOSKeyLayoutID!.toJson();
    }
    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }
    if (salesRepID != null) {
      data['SalesRep_ID'] = salesRepID!.toJson();
    }
    data['Name'] = name;
    if (cCashBookID != null) {
      data['C_CashBook_ID'] = cCashBookID!.toJson();
    }
    if (mWarehouseID != null) {
      data['M_Warehouse_ID'] = mWarehouseID!.toJson();
    }
    if (mPriceListID != null) {
      data['M_PriceList_ID'] = mPriceListID!.toJson();
    }
    data['IsActive'] = isActive;
    data['IsModifyPrice'] = isModifyPrice;
    if (cDocTypeID != null) {
      data['C_DocType_ID'] = cDocTypeID!.toJson();
    }
    if (cBankAccountID != null) {
      data['C_BankAccount_ID'] = cBankAccountID!.toJson();
    }
    if (oSKKeyLayoutID != null) {
      data['OSK_KeyLayout_ID'] = oSKKeyLayoutID!.toJson();
    }
    if (oSNPKeyLayoutID != null) {
      data['OSNP_KeyLayout_ID'] = oSNPKeyLayoutID!.toJson();
    }
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category;
    return data;
  }

}


