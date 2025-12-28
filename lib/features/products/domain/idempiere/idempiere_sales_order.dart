import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_business_partner_location.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_currency.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_status.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_type.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_object.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_organization.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_payment_rule.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_payment_term.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_price_list.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_tenant.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_user.dart';

import 'idempiere_business_partner.dart';
import 'idempiere_object_id_string.dart';
import 'idempiere_warehouse.dart';
import 'object_with_name_and_id.dart';

class IdempiereSalesOrder  extends IdempiereObject{
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? documentNo;
  IdempiereDocumentStatus? docStatus;
  IdempiereDocumentType? cDocTypeID;
  IdempiereDocumentType? cDocTypeTargetID;
  String? description;
  bool? isApproved;
  bool? isCreditApproved;
  bool? isDelivered;
  bool? isInvoiced;
  bool? isPrinted;
  bool? isTransferred;
  String? dateOrdered;
  String? datePromised;
  String? dateAcct;
  IdempiereObject? salesRepID;
  IdempierePaymentTerm? cPaymentTermID;
  IdempiereCurrency? cCurrencyID;
  IdempiereObjectIdString? invoiceRule;
  int? freightAmt;
  IdempiereObjectIdString? deliveryViaRule;
  IdempiereObjectIdString? priorityRule;
  double? totalLines;
  double? grandTotal;
  IdempiereWarehouse? mWarehouseID;
  IdempierePriceList? mPriceListID;
  IdempiereBusinessPartner? cBPartnerID;
  int? chargeAmt;
  bool? processed;
  IdempiereBusinessPartnerLocation? cBPartnerLocationID;
  bool? isSOTrx;
  IdempiereObjectIdString? deliveryRule;
  IdempiereObjectIdString? freightCostRule;
  IdempierePaymentRule? paymentRule;
  bool? isDiscountPrinted;
  bool? isTaxIncluded;
  bool? isSelected;
  bool? sendEMail;
  IdempiereBusinessPartner? billBPartnerID;
  IdempiereBusinessPartnerLocation? billLocationID;
  bool? isSelfService;
  IdempiereObject? cConversionTypeID;
  bool? isDropShip;
  double? volume;
  double? weight;
  double? processedOn;
  bool? isPayScheduleValid;
  bool? isPriviledgedRate;
  bool? isOverrideCurrencyRate;
  double? currencyRate;

  IdempiereSalesOrder(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.documentNo,
        this.docStatus,
        this.cDocTypeID,
        this.cDocTypeTargetID,
        this.description,
        this.isApproved,
        this.isCreditApproved,
        this.isDelivered,
        this.isInvoiced,
        this.isPrinted,
        this.isTransferred,
        this.dateOrdered,
        this.datePromised,
        this.dateAcct,
        this.salesRepID,
        this.cPaymentTermID,
        this.cCurrencyID,
        this.invoiceRule,
        this.freightAmt,
        this.deliveryViaRule,
        this.priorityRule,
        this.totalLines,
        this.grandTotal,
        this.mWarehouseID,
        this.mPriceListID,
        this.cBPartnerID,
        this.chargeAmt,
        this.processed,
        this.cBPartnerLocationID,
        this.isSOTrx,
        this.deliveryRule,
        this.freightCostRule,
        this.paymentRule,
        this.isDiscountPrinted,
        this.isTaxIncluded,
        this.isSelected,
        this.sendEMail,
        this.billBPartnerID,
        this.billLocationID,
        this.isSelfService,
        this.cConversionTypeID,
        this.isDropShip,
        this.volume,
        this.weight,
        this.processedOn,
        this.isPayScheduleValid,
        this.isPriviledgedRate,
        this.isOverrideCurrencyRate,
        this.currencyRate,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.category,
        super.image,
      });

  IdempiereSalesOrder.fromJson(Map<String, dynamic> json) {
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
    documentNo = json['DocumentNo'];
    docStatus = json['DocStatus'] != null
        ? IdempiereDocumentStatus.fromJson(json['DocStatus'])
        : null;
    cDocTypeID = json['C_DocType_ID'] != null
        ? IdempiereDocumentType.fromJson(json['C_DocType_ID'])
        : null;
    cDocTypeTargetID = json['C_DocTypeTarget_ID'] != null
        ? IdempiereDocumentType.fromJson(json['C_DocTypeTarget_ID'])
        : null;
    description = json['Description'];
    isApproved = json['IsApproved'];
    isCreditApproved = json['IsCreditApproved'];
    isDelivered = json['IsDelivered'];
    isInvoiced = json['IsInvoiced'];
    isPrinted = json['IsPrinted'];
    isTransferred = json['IsTransferred'];
    dateOrdered = json['DateOrdered'];
    datePromised = json['DatePromised'];
    dateAcct = json['DateAcct'];
    salesRepID = json['SalesRep_ID'] != null
        ? IdempiereObject.fromJson(json['SalesRep_ID'])
        : null;
    cPaymentTermID = json['C_PaymentTerm_ID'] != null
        ? IdempierePaymentTerm.fromJson(json['C_PaymentTerm_ID'])
        : null;
    cCurrencyID = json['C_Currency_ID'] != null
        ? IdempiereCurrency.fromJson(json['C_Currency_ID'])
        : null;
    invoiceRule = json['InvoiceRule'] != null
        ? IdempiereObjectIdString.fromJson(json['InvoiceRule'])
        : null;
    freightAmt = json['FreightAmt'];
    deliveryViaRule = json['DeliveryViaRule'] != null
        ? IdempiereObjectIdString.fromJson(json['DeliveryViaRule'])
        : null;
    priorityRule = json['PriorityRule'] != null
        ? IdempiereObjectIdString.fromJson(json['PriorityRule'])
        : null;
    totalLines = json['TotalLines']?.toDouble() ;
    grandTotal = json['GrandTotal']?.toDouble() ;
    mWarehouseID = json['M_Warehouse_ID'] != null
        ? IdempiereWarehouse.fromJson(json['M_Warehouse_ID'])
        : null;
    mPriceListID = json['M_PriceList_ID'] != null
        ? IdempierePriceList.fromJson(json['M_PriceList_ID'])
        : null;
    cBPartnerID = json['C_BPartner_ID'] != null
        ? IdempiereBusinessPartner.fromJson(json['C_BPartner_ID'])
        : null;
    chargeAmt = json['ChargeAmt'];
    processed = json['Processed'];
    cBPartnerLocationID = json['C_BPartner_Location_ID'] != null
        ? IdempiereBusinessPartnerLocation.fromJson(json['C_BPartner_Location_ID'])
        : null;
    isSOTrx = json['IsSOTrx'];
    deliveryRule = json['DeliveryRule'] != null
        ?IdempiereObjectIdString.fromJson(json['DeliveryRule'])
        : null;
    freightCostRule = json['FreightCostRule'] != null
        ? IdempiereObjectIdString.fromJson(json['FreightCostRule'])
        : null;
    paymentRule = json['PaymentRule'] != null
        ? IdempierePaymentRule.fromJson(json['PaymentRule'])
        : null;
    isDiscountPrinted = json['IsDiscountPrinted'];
    isTaxIncluded = json['IsTaxIncluded'];
    isSelected = json['IsSelected'];
    sendEMail = json['SendEMail'];
    billBPartnerID = json['Bill_BPartner_ID'] != null
        ? IdempiereBusinessPartner.fromJson(json['Bill_BPartner_ID'])
        : null;
    billLocationID = json['Bill_Location_ID'] != null
        ? IdempiereBusinessPartnerLocation.fromJson(json['Bill_Location_ID'])
        : null;
    isSelfService = json['IsSelfService'];
    cConversionTypeID = json['C_ConversionType_ID'] != null
        ? IdempiereObject.fromJson(json['C_ConversionType_ID'])
        : null;
    isDropShip = json['IsDropShip'];
    volume = json['Volume'];
    weight = json['Weight'];
    processedOn = json['ProcessedOn'];
    isPayScheduleValid = json['IsPayScheduleValid'];
    isPriviledgedRate = json['IsPriviledgedRate'];
    isOverrideCurrencyRate = json['IsOverrideCurrencyRate'];
    currencyRate = json['CurrencyRate'];
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
    name = json['name'];
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
    data['DocumentNo'] = documentNo;
    if (docStatus != null) {
      data['DocStatus'] = docStatus!.toJson();
    }
    if (cDocTypeID != null) {
      data['C_DocType_ID'] = cDocTypeID!.toJson();
    }
    if (cDocTypeTargetID != null) {
      data['C_DocTypeTarget_ID'] = cDocTypeTargetID!.toJson();
    }
    data['Description'] = description;
    data['IsApproved'] = isApproved;
    data['IsCreditApproved'] = isCreditApproved;
    data['IsDelivered'] = isDelivered;
    data['IsInvoiced'] = isInvoiced;
    data['IsPrinted'] = isPrinted;
    data['IsTransferred'] = isTransferred;
    data['DateOrdered'] = dateOrdered;
    data['DatePromised'] = datePromised;
    data['DateAcct'] = dateAcct;
    if (salesRepID != null) {
      data['SalesRep_ID'] = salesRepID!.toJson();
    }
    if (cPaymentTermID != null) {
      data['C_PaymentTerm_ID'] = cPaymentTermID!.toJson();
    }
    if (cCurrencyID != null) {
      data['C_Currency_ID'] = cCurrencyID!.toJson();
    }
    if (invoiceRule != null) {
      data['InvoiceRule'] = invoiceRule!.toJson();
    }
    data['FreightAmt'] = freightAmt;
    if (deliveryViaRule != null) {
      data['DeliveryViaRule'] = deliveryViaRule!.toJson();
    }
    if (priorityRule != null) {
      data['PriorityRule'] = priorityRule!.toJson();
    }
    data['TotalLines'] = totalLines;
    data['GrandTotal'] = grandTotal;
    if (mWarehouseID != null) {
      data['M_Warehouse_ID'] = mWarehouseID!.toJson();
    }
    if (mPriceListID != null) {
      data['M_PriceList_ID'] = mPriceListID!.toJson();
    }
    if (cBPartnerID != null) {
      data['C_BPartner_ID'] = cBPartnerID!.toJson();
    }
    data['ChargeAmt'] = chargeAmt;
    data['Processed'] = processed;
    if (cBPartnerLocationID != null) {
      data['C_BPartner_Location_ID'] = cBPartnerLocationID!.toJson();
    }
    data['IsSOTrx'] = isSOTrx;
    if (deliveryRule != null) {
      data['DeliveryRule'] = deliveryRule!.toJson();
    }
    if (freightCostRule != null) {
      data['FreightCostRule'] = freightCostRule!.toJson();
    }
    if (paymentRule != null) {
      data['PaymentRule'] = paymentRule!.toJson();
    }
    data['IsDiscountPrinted'] = isDiscountPrinted;
    data['IsTaxIncluded'] = isTaxIncluded;
    data['IsSelected'] = isSelected;
    data['SendEMail'] = sendEMail;
    if (billBPartnerID != null) {
      data['Bill_BPartner_ID'] = billBPartnerID!.toJson();
    }
    if (billLocationID != null) {
      data['Bill_Location_ID'] = billLocationID!.toJson();
    }
    data['IsSelfService'] = isSelfService;
    if (cConversionTypeID != null) {
      data['C_ConversionType_ID'] = cConversionTypeID!.toJson();
    }
    data['IsDropShip'] = isDropShip;
    data['Volume'] = volume;
    data['Weight'] = weight;
    data['ProcessedOn'] = processedOn;
    data['IsPayScheduleValid'] = isPayScheduleValid;
    data['IsPriviledgedRate'] = isPriviledgedRate;
    data['IsOverrideCurrencyRate'] = isOverrideCurrencyRate;
    data['CurrencyRate'] = currencyRate;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['name'] = name;
    return data;
  }
  IdempiereSalesOrder copyWith({
    String? uid,
    IdempiereTenant? aDClientID,
    IdempiereOrganization? aDOrgID,
    bool? isActive,
    String? created,
    IdempiereUser? createdBy,
    String? updated,
    IdempiereUser? updatedBy,
    String? documentNo,
    IdempiereDocumentStatus? docStatus,
    IdempiereDocumentType? cDocTypeID,
    IdempiereDocumentType? cDocTypeTargetID,
    String? description,
    bool? isApproved,
    bool? isCreditApproved,
    bool? isDelivered,
    bool? isInvoiced,
    bool? isPrinted,
    bool? isTransferred,
    String? dateOrdered,
    String? datePromised,
    String? dateAcct,
    IdempiereObject? salesRepID,
    IdempierePaymentTerm? cPaymentTermID,
    IdempiereCurrency? cCurrencyID,
    IdempiereObjectIdString? invoiceRule,
    int? freightAmt,
    IdempiereObjectIdString? deliveryViaRule,
    IdempiereObjectIdString? priorityRule,
    double? totalLines,
    double? grandTotal,
    IdempiereWarehouse? mWarehouseID,
    IdempierePriceList? mPriceListID,
    IdempiereBusinessPartner? cBPartnerID,
    int? chargeAmt,
    bool? processed,
    IdempiereBusinessPartnerLocation? cBPartnerLocationID,
    bool? isSOTrx,
    IdempiereObjectIdString? deliveryRule,
    IdempiereObjectIdString? freightCostRule,
    IdempierePaymentRule? paymentRule,
    bool? isDiscountPrinted,
    bool? isTaxIncluded,
    bool? isSelected,
    bool? sendEMail,
    IdempiereBusinessPartner? billBPartnerID,
    IdempiereBusinessPartnerLocation? billLocationID,
    bool? isSelfService,
    IdempiereObject? cConversionTypeID,
    bool? isDropShip,
    double? volume,
    double? weight,
    double? processedOn,
    bool? isPayScheduleValid,
    bool? isPriviledgedRate,
    bool? isOverrideCurrencyRate,
    double? currencyRate,

    // IdempiereObject
    int? id,
    String? name,
    bool? active,
    String? propertyLabel,
    String? identifier,
    String? modelName,
    ObjectWithNameAndId? category,
    String? image,
  }) {
    return IdempiereSalesOrder(
      uid: uid ?? this.uid,
      aDClientID: aDClientID ?? this.aDClientID,
      aDOrgID: aDOrgID ?? this.aDOrgID,
      isActive: isActive ?? this.isActive,
      created: created ?? this.created,
      createdBy: createdBy ?? this.createdBy,
      updated: updated ?? this.updated,
      updatedBy: updatedBy ?? this.updatedBy,
      documentNo: documentNo ?? this.documentNo,
      docStatus: docStatus ?? this.docStatus,
      cDocTypeID: cDocTypeID ?? this.cDocTypeID,
      cDocTypeTargetID: cDocTypeTargetID ?? this.cDocTypeTargetID,
      description: description ?? this.description,
      isApproved: isApproved ?? this.isApproved,
      isCreditApproved: isCreditApproved ?? this.isCreditApproved,
      isDelivered: isDelivered ?? this.isDelivered,
      isInvoiced: isInvoiced ?? this.isInvoiced,
      isPrinted: isPrinted ?? this.isPrinted,
      isTransferred: isTransferred ?? this.isTransferred,
      dateOrdered: dateOrdered ?? this.dateOrdered,
      datePromised: datePromised ?? this.datePromised,
      dateAcct: dateAcct ?? this.dateAcct,
      salesRepID: salesRepID ?? this.salesRepID,
      cPaymentTermID: cPaymentTermID ?? this.cPaymentTermID,
      cCurrencyID: cCurrencyID ?? this.cCurrencyID,
      invoiceRule: invoiceRule ?? this.invoiceRule,
      freightAmt: freightAmt ?? this.freightAmt,
      deliveryViaRule: deliveryViaRule ?? this.deliveryViaRule,
      priorityRule: priorityRule ?? this.priorityRule,
      totalLines: totalLines ?? this.totalLines,
      grandTotal: grandTotal ?? this.grandTotal,
      mWarehouseID: mWarehouseID ?? this.mWarehouseID,
      mPriceListID: mPriceListID ?? this.mPriceListID,
      cBPartnerID: cBPartnerID ?? this.cBPartnerID,
      chargeAmt: chargeAmt ?? this.chargeAmt,
      processed: processed ?? this.processed,
      cBPartnerLocationID:
      cBPartnerLocationID ?? this.cBPartnerLocationID,
      isSOTrx: isSOTrx ?? this.isSOTrx,
      deliveryRule: deliveryRule ?? this.deliveryRule,
      freightCostRule: freightCostRule ?? this.freightCostRule,
      paymentRule: paymentRule ?? this.paymentRule,
      isDiscountPrinted:
      isDiscountPrinted ?? this.isDiscountPrinted,
      isTaxIncluded: isTaxIncluded ?? this.isTaxIncluded,
      isSelected: isSelected ?? this.isSelected,
      sendEMail: sendEMail ?? this.sendEMail,
      billBPartnerID: billBPartnerID ?? this.billBPartnerID,
      billLocationID: billLocationID ?? this.billLocationID,
      isSelfService: isSelfService ?? this.isSelfService,
      cConversionTypeID:
      cConversionTypeID ?? this.cConversionTypeID,
      isDropShip: isDropShip ?? this.isDropShip,
      volume: volume ?? this.volume,
      weight: weight ?? this.weight,
      processedOn: processedOn ?? this.processedOn,
      isPayScheduleValid:
      isPayScheduleValid ?? this.isPayScheduleValid,
      isPriviledgedRate:
      isPriviledgedRate ?? this.isPriviledgedRate,
      isOverrideCurrencyRate:
      isOverrideCurrencyRate ?? this.isOverrideCurrencyRate,
      currencyRate: currencyRate ?? this.currencyRate,

      // super
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      propertyLabel: propertyLabel ?? this.propertyLabel,
      identifier: identifier ?? this.identifier,
      modelName: modelName ?? this.modelName,
      category: category ?? this.category,
      image: image ?? this.image,
    );
  }
}


