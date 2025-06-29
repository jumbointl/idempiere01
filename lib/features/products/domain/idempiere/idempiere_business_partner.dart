import '../../../shared/data/messages.dart';
import 'idempiere_business_partner_group.dart';
import 'idempiere_credit_status.dart';
import 'idempiere_dunning.dart';
import 'idempiere_language.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_payment_rule.dart';
import 'idempiere_payment_term.dart';
import 'idempiere_price_list.dart';
import 'idempiere_purchase_order_payment_term.dart';
import 'idempiere_purchase_price_list.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

class IdempiereBusinessPartner extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? value;
  int? salesVolume;
  int? numberEmployees;
  bool? isSummary;
  IdempiereLanguage? aDLanguage;
  bool? isVendor;
  bool? isCustomer;
  bool? isProspect;
  int? sOCreditLimit;
  double? sOCreditUsed;
  int? acqusitionCost;
  int? potentialLifeTimeValue;
  IdempierePaymentTerm? cPaymentTermID;
  double? actualLifeTimeValue;
  int? shareOfCustomer;
  bool? isEmployee;
  bool? isSalesRep;
  IdempierePriceList? mPriceListID;
  IdempierePurchasePriceList? pOPriceListID;
  bool? isOneTime;
  bool? isTaxExempt;
  IdempiereDunning? cDunningID;
  int? documentCopies;
  IdempierePaymentRule? paymentRulePO;
  bool? isDiscountPrinted;
  IdempiereUser? salesRepID;
  IdempiereBusinessPartnerGroup? cBPGroupID;
  IdempierePurchaseOrderPaymentTerm? pOPaymentTermID;
  bool? sendEMail;
  IdempiereCreditStatus? sOCreditStatus;
  int? shelfLifeMinPct;
  int? flatDiscount;
  double? totalOpenBalance;
  bool? isPOTaxExempt;
  bool? isManufacturer;
  bool? is1099Vendor;
  bool? isVip;
  bool? amerpIsvalidationseniat;
  bool? amerpWithholdingagent;
  bool? amerpIvataxpayer;
  bool? isUseTaxIdDigit;
  bool? isDetailedNames;
  int? mOLICBPartnerID;
  bool? isSocialSecurity;
  bool? mOLIIsEDI;
  bool? mOLIIsGMRKenzo;
  bool? mOLIIsPromoter;


  IdempiereBusinessPartner(
      {super.id,
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.value,
        super.name,
        this.salesVolume,
        this.numberEmployees,
        this.isSummary,
        this.aDLanguage,
        this.isVendor,
        this.isCustomer,
        this.isProspect,
        this.sOCreditLimit,
        this.sOCreditUsed,
        this.acqusitionCost,
        this.potentialLifeTimeValue,
        this.cPaymentTermID,
        this.actualLifeTimeValue,
        this.shareOfCustomer,
        this.isEmployee,
        this.isSalesRep,
        this.mPriceListID,
        this.pOPriceListID,
        this.isOneTime,
        this.isTaxExempt,
        this.cDunningID,
        this.documentCopies,
        this.paymentRulePO,
        this.isDiscountPrinted,
        this.salesRepID,
        this.cBPGroupID,
        this.pOPaymentTermID,
        this.sendEMail,
        this.sOCreditStatus,
        this.shelfLifeMinPct,
        this.flatDiscount,
        this.totalOpenBalance,
        this.isPOTaxExempt,
        this.isManufacturer,
        this.is1099Vendor,
        this.isVip,
        this.amerpIsvalidationseniat,
        this.amerpWithholdingagent,
        this.amerpIvataxpayer,
        this.isUseTaxIdDigit,
        this.isDetailedNames,
        this.mOLICBPartnerID,
        this.isSocialSecurity,
        this.mOLIIsEDI,
        this.mOLIIsGMRKenzo,
        this.mOLIIsPromoter,
        super.modelName,
        super.propertyLabel,
        super.identifier,
      });

  IdempiereBusinessPartner.fromJson(Map<String, dynamic> json) {
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
    value = json['Value'];
    name = json['Name'];
    salesVolume = json['SalesVolume'];
    numberEmployees = json['NumberEmployees'];
    isSummary = json['IsSummary'];
    aDLanguage = json['AD_Language'] != null
        ? IdempiereLanguage.fromJson(json['AD_Language'])
        : null;
    isVendor = json['IsVendor'];
    isCustomer = json['IsCustomer'];
    isProspect = json['IsProspect'];
    sOCreditLimit = json['SO_CreditLimit'];
    sOCreditUsed = json['SO_CreditUsed'] == null ? null : double.tryParse(json['SO_CreditUsed'].toString());
    var d = json['SO_CreditUsed'];
    acqusitionCost = json['AcqusitionCost'];
    potentialLifeTimeValue = json['PotentialLifeTimeValue'];
    cPaymentTermID = json['C_PaymentTerm_ID'] != null
        ? IdempierePaymentTerm.fromJson(json['C_PaymentTerm_ID'])
        : null;
    actualLifeTimeValue = json['ActualLifeTimeValue'] == null ? null : double.tryParse(json['ActualLifeTimeValue'].toString());
    shareOfCustomer = json['ShareOfCustomer'];
    isEmployee = json['IsEmployee'];
    isSalesRep = json['IsSalesRep'];
    mPriceListID = json['M_PriceList_ID'] != null
        ? IdempierePriceList.fromJson(json['M_PriceList_ID'])
        : null;
    pOPriceListID = json['PO_PriceList_ID'] != null
        ? IdempierePurchasePriceList.fromJson(json['PO_PriceList_ID'])
        : null;
    isOneTime = json['IsOneTime'];
    isTaxExempt = json['IsTaxExempt'];
    cDunningID = json['C_Dunning_ID'] != null
        ? IdempiereDunning.fromJson(json['C_Dunning_ID'])
        : null;
    documentCopies = json['DocumentCopies'];
    paymentRulePO = json['PaymentRulePO'] != null
        ? IdempierePaymentRule.fromJson(json['PaymentRulePO'])
        : null;
    isDiscountPrinted = json['IsDiscountPrinted'];
    salesRepID = json['SalesRep_ID'] != null
        ? IdempiereUser.fromJson(json['SalesRep_ID'])
        : null;
    cBPGroupID = json['C_BP_Group_ID'] != null
        ? IdempiereBusinessPartnerGroup.fromJson(json['C_BP_Group_ID'])
        : null;
    pOPaymentTermID = json['PO_PaymentTerm_ID'] != null
        ? IdempierePurchaseOrderPaymentTerm.fromJson(json['PO_PaymentTerm_ID'])
        : null;
    sendEMail = json['SendEMail'];
    sOCreditStatus = json['SOCreditStatus'] != null
        ? IdempiereCreditStatus.fromJson(json['SOCreditStatus'])
        : null;
    shelfLifeMinPct = json['ShelfLifeMinPct'];
    flatDiscount = json['FlatDiscount'];
    totalOpenBalance = json['TotalOpenBalance'] == null ? null : double.tryParse(json['TotalOpenBalance'].toString());
    isPOTaxExempt = json['IsPOTaxExempt'];
    isManufacturer = json['IsManufacturer'];
    is1099Vendor = json['Is1099Vendor'];
    isVip = json['isVip'];
    amerpIsvalidationseniat = json['amerp_isvalidationseniat'];
    amerpWithholdingagent = json['amerp_withholdingagent'];
    amerpIvataxpayer = json['amerp_ivataxpayer'];
    isUseTaxIdDigit = json['IsUseTaxIdDigit'];
    isDetailedNames = json['IsDetailedNames'];
    mOLICBPartnerID = json['MOLI_C_BPartner_ID'];
    isSocialSecurity = json['isSocialSecurity'];
    mOLIIsEDI = json['MOLI_IsEDI'];
    mOLIIsGMRKenzo = json['MOLI_IsGMRKenzo'];
    mOLIIsPromoter = json['MOLI_IsPromoter'];
    modelName = json['model-name'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];

  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
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
    data['Value'] = value;
    data['Name'] = name;
    data['SalesVolume'] = salesVolume;
    data['NumberEmployees'] = numberEmployees;
    data['IsSummary'] = isSummary;
    if (aDLanguage != null) {
      data['AD_Language'] = aDLanguage!.toJson();
    }
    data['IsVendor'] = isVendor;
    data['IsCustomer'] = isCustomer;
    data['IsProspect'] = isProspect;
    data['SO_CreditLimit'] = sOCreditLimit;
    data['SO_CreditUsed'] = sOCreditUsed;
    data['AcqusitionCost'] = acqusitionCost;
    data['PotentialLifeTimeValue'] = potentialLifeTimeValue;
    if (cPaymentTermID != null) {
      data['C_PaymentTerm_ID'] = cPaymentTermID!.toJson();
    }
    data['ActualLifeTimeValue'] = actualLifeTimeValue;
    data['ShareOfCustomer'] = shareOfCustomer;
    data['IsEmployee'] = isEmployee;
    data['IsSalesRep'] = isSalesRep;
    if (mPriceListID != null) {
      data['M_PriceList_ID'] = mPriceListID!.toJson();
    }
    if (pOPriceListID != null) {
      data['PO_PriceList_ID'] = pOPriceListID!.toJson();
    }
    data['IsOneTime'] = isOneTime;
    data['IsTaxExempt'] = isTaxExempt;
    if (cDunningID != null) {
      data['C_Dunning_ID'] = cDunningID!.toJson();
    }
    data['DocumentCopies'] = documentCopies;
    if (paymentRulePO != null) {
      data['PaymentRulePO'] = paymentRulePO!.toJson();
    }
    data['IsDiscountPrinted'] = isDiscountPrinted;
    if (salesRepID != null) {
      data['SalesRep_ID'] = salesRepID!.toJson();
    }
    if (cBPGroupID != null) {
      data['C_BP_Group_ID'] = cBPGroupID!.toJson();
    }
    if (pOPaymentTermID != null) {
      data['PO_PaymentTerm_ID'] = pOPaymentTermID!.toJson();
    }
    data['SendEMail'] = sendEMail;
    if (sOCreditStatus != null) {
      data['SOCreditStatus'] = sOCreditStatus!.toJson();
    }
    data['ShelfLifeMinPct'] = shelfLifeMinPct;
    data['FlatDiscount'] = flatDiscount;
    data['TotalOpenBalance'] = totalOpenBalance;
    data['IsPOTaxExempt'] = isPOTaxExempt;
    data['IsManufacturer'] = isManufacturer;
    data['Is1099Vendor'] = is1099Vendor;
    data['isVip'] = isVip;
    data['amerp_isvalidationseniat'] = amerpIsvalidationseniat;
    data['amerp_withholdingagent'] = amerpWithholdingagent;
    data['amerp_ivataxpayer'] = amerpIvataxpayer;
    data['IsUseTaxIdDigit'] = isUseTaxIdDigit;
    data['IsDetailedNames'] = isDetailedNames;
    data['MOLI_C_BPartner_ID'] = mOLICBPartnerID;
    data['isSocialSecurity'] = isSocialSecurity;
    data['MOLI_IsEDI'] = mOLIIsEDI;
    data['MOLI_IsGMRKenzo'] = mOLIIsGMRKenzo;
    data['MOLI_IsPromoter'] = mOLIIsPromoter;
    data['model-name'] = modelName;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    return data;
  }
  static List<IdempiereBusinessPartner> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereBusinessPartner.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereBusinessPartner.fromJson(item)).toList();
    }

    List<IdempiereBusinessPartner> newList =[];
    for (var item in json) {
      if(item is IdempiereBusinessPartner){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereBusinessPartner idempiereBusinessPartner = IdempiereBusinessPartner.fromJson(item);
        newList.add(idempiereBusinessPartner);
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
    if(modelName != null){
      list.add(modelName!);
    }
    return list;
  }
}



