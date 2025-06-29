import 'idempiere_bank.dart';
import 'idempiere_currency.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_bank_account_type.dart';
import 'idempiere_user.dart';

class IdempiereBankAccount extends IdempiereObject {
  String? uid;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  IdempiereBank? cBankID;
  IdempiereCurrency? cCurrencyID;
  String? accountNo;
  int? currentBalance;
  int? creditLimit;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isDefault;
  IdempiereBankAccountType? bankAccountType;
  String? description;
  String? value;
  int? mOLICBankAccountID;

  IdempiereBankAccount(
      {
        this.uid,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.cBankID,
        this.cCurrencyID,
        this.accountNo,
        this.currentBalance,
        this.creditLimit,
        this.aDClientID,
        this.aDOrgID,
        this.isDefault,
        this.bankAccountType,
        this.description,
        this.value,
        this.mOLICBankAccountID,
      });

  IdempiereBankAccount.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    isActive = json['IsActive'];
    created = json['Created'];
    createdBy = json['CreatedBy'] != null
        ?  IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    updated = json['Updated'];
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    cBankID = json['C_Bank_ID'] != null
        ?  IdempiereBank.fromJson(json['C_Bank_ID'])
        : null;
    cCurrencyID = json['C_Currency_ID'] != null
        ?  IdempiereCurrency.fromJson(json['C_Currency_ID'])
        : null;
    accountNo = json['AccountNo'];
    currentBalance = json['CurrentBalance'];
    creditLimit = json['CreditLimit'];
    aDClientID = json['AD_Client_ID'] != null
        ?  IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    aDOrgID = json['AD_Org_ID'] != null
        ?  IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    isDefault = json['IsDefault'];
    bankAccountType = json['BankAccountType'] != null
        ?  IdempiereBankAccountType.fromJson(json['BankAccountType'])
        : null;
    description = json['Description'];
    value = json['Value'];
    name = json['Name'];
    mOLICBankAccountID = json['MOLI_C_BankAccount_ID'];
    modelName = json['model-name'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['IsActive'] = isActive;
    data['Created'] = created;
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    data['Updated'] = updated;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    if (cBankID != null) {
      data['C_Bank_ID'] = cBankID!.toJson();
    }
    if (cCurrencyID != null) {
      data['C_Currency_ID'] = cCurrencyID!.toJson();
    }
    data['AccountNo'] = accountNo;
    data['CurrentBalance'] = currentBalance;
    data['CreditLimit'] = creditLimit;
    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }
    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }
    data['IsDefault'] = isDefault;
    if (bankAccountType != null) {
      data['BankAccountType'] = bankAccountType!.toJson();
    }
    data['Description'] = description;
    data['Value'] = value;
    data['Name'] = name;
    data['MOLI_C_BankAccount_ID'] = mOLICBankAccountID;
    data['model-name'] = modelName;
    return data;
  }
  static List<IdempiereBankAccount> fromJsonList(List<dynamic> list){
    List<IdempiereBankAccount> newList =[];
    for (var item in list) {
      if(item is IdempiereBankAccount){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereBankAccount idempiereBankAccount = IdempiereBankAccount.fromJson(item);
        newList.add(idempiereBankAccount);
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
    if(cBankID != null){
      if(cBankID!.id != null){
        list.add('${Messages.BANK_ID}: ${cBankID!.id ?? '--'}');
      }
      if(cBankID!.name != null){
        list.add('${Messages.NAME}: ${cBankID!.name ?? '--'}');
      }

    }

    return list;
  }
}


