import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';

import 'idempiere_business_partner.dart';
import 'idempiere_business_partner_location.dart';
import 'idempiere_currency.dart';
import 'idempiere_document_status.dart';
import 'idempiere_document_type.dart';
import 'idempiere_object.dart';
import 'idempiere_object_id_string.dart';
import 'idempiere_organization.dart';
import 'idempiere_payment_rule.dart';
import 'idempiere_payment_term.dart';
import 'idempiere_price_list.dart';
import 'idempiere_sales_order.dart';
import 'idempiere_sales_order_line.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';
import 'idempiere_warehouse.dart';
import 'object_with_name_and_id.dart';

class SalesOrderAndLines extends IdempiereSalesOrder {
  List<IdempiereSalesOrderLine>? salesOrderLines;
  List<MInOut>? mInOutsInProgress;
  bool? orderComplete ;
  bool? orderRunning;
  bool? orderHasToDo;
  double? totalShipped;
  double? totalOrdered;
  int? inCompletedLines;


  SalesOrderAndLines({
    this.salesOrderLines,
    this.mInOutsInProgress,


    // ======== IdempiereSalesOrder ========
    super.uid,
    super.aDClientID,
    super.aDOrgID,
    super.isActive,
    super.created,
    super.createdBy,
    super.updated,
    super.updatedBy,
    super.documentNo,
    super.docStatus,
    super.cDocTypeID,
    super.cDocTypeTargetID,
    super.description,
    super.isApproved,
    super.isCreditApproved,
    super.isDelivered,
    super.isInvoiced,
    super.isPrinted,
    super.isTransferred,
    super.dateOrdered,
    super.datePromised,
    super.dateAcct,
    super.salesRepID,
    super.cPaymentTermID,
    super.cCurrencyID,
    super.invoiceRule,
    super.freightAmt,
    super.deliveryViaRule,
    super.priorityRule,
    super.totalLines,
    super.grandTotal,
    super.mWarehouseID,
    super.mPriceListID,
    super.cBPartnerID,
    super.chargeAmt,
    super.processed,
    super.cBPartnerLocationID,
    super.isSOTrx,
    super.deliveryRule,
    super.freightCostRule,
    super.paymentRule,
    super.isDiscountPrinted,
    super.isTaxIncluded,
    super.isSelected,
    super.sendEMail,
    super.billBPartnerID,
    super.billLocationID,
    super.isSelfService,
    super.cConversionTypeID,
    super.isDropShip,
    super.volume,
    super.weight,
    super.processedOn,
    super.isPayScheduleValid,
    super.isPriviledgedRate,
    super.isOverrideCurrencyRate,
    super.currencyRate,

    // ======== IdempiereObject ========
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.category,
    super.image,
  });

  // =========================================================
  // fromJson
  // =========================================================
  SalesOrderAndLines.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (json['salesOrderLines'] != null) {
      salesOrderLines = (json['salesOrderLines'] as List)
          .map((e) => IdempiereSalesOrderLine.fromJson(e))
          .toList();
    }
    if (json['mInOutsInProgress'] != null) {
      mInOutsInProgress = (json['mInOutsInProgress'] as List)
          .map((e) => MInOut.fromJson(e)).toList();
    }

  }

  bool get hasLines =>  salesOrderLines != null && salesOrderLines!.isNotEmpty;

  bool get hasToDoWorks {
    if(orderComplete == true) return false;
    if(orderRunning == true) return false;
    if(orderHasToDo ==true) return true;
    if(salesOrderLines == null || salesOrderLines!.isEmpty) return false ;
    if(inCompletedLines==null){
      compueteShippedAndOrdered();
    }
    if(inCompletedLines! >0){
      if(mInOutsInProgress == null || mInOutsInProgress!.isEmpty){
        orderHasToDo = true;
        return true ;
      } else {
        return false ;
      }

    } else {
      return false;
    }


  }

  bool get isRunning {
    if(orderComplete == true) return false;
    if(orderHasToDo == true) return false ;
    if(orderRunning ==true) return true;
    if(salesOrderLines == null || salesOrderLines!.isEmpty) return false ;
    if(mInOutsInProgress == null || mInOutsInProgress!.isEmpty) return false ;
    orderRunning = true;
    return true;

  }

  bool get isDone {
    if(orderComplete ==true) return true;
    if(salesOrderLines == null || salesOrderLines!.isEmpty) return true ;
    if(totalOrdered == null || totalShipped==null){
      compueteShippedAndOrdered();
    }

    if(inCompletedLines==0){
      orderComplete = true;
      return true;
    } else {
      orderComplete = false;
      return false;
    }
  }

  // =========================================================
  // toJson
  // =========================================================
  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();
    if (salesOrderLines != null) {
      data['salesOrderLines'] =
          salesOrderLines!.map((e) => e.toJson()).toList();
    }
    if (mInOutsInProgress != null){
      data['mInOutsInProgress'] = mInOutsInProgress!.map((e) => e.toJson()).toList();
    }
    return data;
  }

  // =========================================================
  // copyWith
  // =========================================================
  @override
  SalesOrderAndLines copyWith({
    List<IdempiereSalesOrderLine>? salesOrderLines,
    List<MInOut>? mInOuts,


    // ===== IdempiereSalesOrder =====
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

    // ===== IdempiereObject =====
    int? id,
    String? name,
    bool? active,
    String? propertyLabel,
    String? identifier,
    String? modelName,
    ObjectWithNameAndId? category,
    String? image,
  }) {
    return SalesOrderAndLines(
      salesOrderLines: salesOrderLines ?? this.salesOrderLines,
      mInOutsInProgress: mInOuts ?? mInOutsInProgress,



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
      cDocTypeTargetID:
      cDocTypeTargetID ?? this.cDocTypeTargetID,
      description: description ?? this.description,
      isApproved: isApproved ?? this.isApproved,
      isCreditApproved:
      isCreditApproved ?? this.isCreditApproved,
      isDelivered: isDelivered ?? this.isDelivered,
      isInvoiced: isInvoiced ?? this.isInvoiced,
      isPrinted: isPrinted ?? this.isPrinted,
      isTransferred: isTransferred ?? this.isTransferred,
      dateOrdered: dateOrdered ?? this.dateOrdered,
      datePromised: datePromised ?? this.datePromised,
      dateAcct: dateAcct ?? this.dateAcct,
      salesRepID: salesRepID ?? this.salesRepID,
      cPaymentTermID:
      cPaymentTermID ?? this.cPaymentTermID,
      cCurrencyID: cCurrencyID ?? this.cCurrencyID,
      invoiceRule: invoiceRule ?? this.invoiceRule,
      freightAmt: freightAmt ?? this.freightAmt,
      deliveryViaRule:
      deliveryViaRule ?? this.deliveryViaRule,
      priorityRule: priorityRule ?? this.priorityRule,
      totalLines: totalLines ?? this.totalLines,
      grandTotal: grandTotal ?? this.grandTotal,
      mWarehouseID:
      mWarehouseID ?? this.mWarehouseID,
      mPriceListID:
      mPriceListID ?? this.mPriceListID,
      cBPartnerID:
      cBPartnerID ?? this.cBPartnerID,
      chargeAmt: chargeAmt ?? this.chargeAmt,
      processed: processed ?? this.processed,
      cBPartnerLocationID:
      cBPartnerLocationID ?? this.cBPartnerLocationID,
      isSOTrx: isSOTrx ?? this.isSOTrx,
      deliveryRule: deliveryRule ?? this.deliveryRule,
      freightCostRule:
      freightCostRule ?? this.freightCostRule,
      paymentRule: paymentRule ?? this.paymentRule,
      isDiscountPrinted:
      isDiscountPrinted ?? this.isDiscountPrinted,
      isTaxIncluded:
      isTaxIncluded ?? this.isTaxIncluded,
      isSelected: isSelected ?? this.isSelected,
      sendEMail: sendEMail ?? this.sendEMail,
      billBPartnerID:
      billBPartnerID ?? this.billBPartnerID,
      billLocationID:
      billLocationID ?? this.billLocationID,
      isSelfService:
      isSelfService ?? this.isSelfService,
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

  void compueteShippedAndOrdered() {
    if(salesOrderLines == null || salesOrderLines!.isEmpty) {
      totalShipped = null;
      totalOrdered = null;
      return;
    }
    totalShipped = 0;
    totalOrdered = 0;
    inCompletedLines = 0;
    for (IdempiereSalesOrderLine line in salesOrderLines!) {
      double shipped = line.qtyDelivered ?? 0;
      double ordered = line.qtyOrdered ?? 0;
      if(shipped < ordered){
        inCompletedLines = inCompletedLines! + 1;
      }
      totalShipped = totalShipped! + shipped;
      totalOrdered = totalOrdered! + ordered;

    }
  }
}
