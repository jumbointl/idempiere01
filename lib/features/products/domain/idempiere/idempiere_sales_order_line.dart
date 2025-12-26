import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_UOM.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_attribute_set_instance.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_business_partner.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_business_partner_location.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_currency.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_sales_order.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_tax.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_tenant.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_user.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/object_with_name_and_id.dart';

import 'idempiere_object.dart';
import 'idempiere_organization.dart';

class IdempiereSalesOrderLine extends IdempiereObject{
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  IdempiereSalesOrder? cOrderID;
  int? line;
  String? dateOrdered;
  String? datePromised;
  String? dateDelivered;
  IdempiereProduct? mProductID;
  IdempiereUOM? cUOMID;
  IdempiereWarehouse? mWarehouseID;
  double? qtyOrdered;
  double? qtyReserved;
  double? qtyDelivered;
  double? qtyInvoiced;
  IdempiereCurrency? cCurrencyID;
  double? priceList;
  double? priceActual;
  IdempiereTax? cTaxID;
  IdempiereBusinessPartner? cBPartnerID;
  int? freightAmt;
  IdempiereBusinessPartnerLocation? cBPartnerLocationID;
  double? lineNetAmt;
  double? priceLimit;
  double? discount;
  IdempiereAttributeSetInstance? mAttributeSetInstanceID;
  bool? isDescription;
  bool? processed;
  double? priceEntered;
  double? qtyEntered;
  double? qtyLostSales;
  String? productName;
  String? sKU;
  String? uPC;

  IdempiereSalesOrderLine(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.cOrderID,
        this.line,
        this.dateOrdered,
        this.datePromised,
        this.dateDelivered,
        this.mProductID,
        this.cUOMID,
        this.mWarehouseID,
        this.qtyOrdered,
        this.qtyReserved,
        this.qtyDelivered,
        this.qtyInvoiced,
        this.cCurrencyID,
        this.priceList,
        this.priceActual,
        this.cTaxID,
        this.cBPartnerID,
        this.freightAmt,
        this.cBPartnerLocationID,
        this.lineNetAmt,
        this.priceLimit,
        this.discount,
        this.mAttributeSetInstanceID,
        this.isDescription,
        this.processed,
        this.priceEntered,
        this.qtyEntered,
        this.qtyLostSales,
        this.productName,
        this.sKU,
        this.uPC,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.category,
        super.image,
      });

  IdempiereSalesOrderLine.fromJson(Map<String, dynamic> json) {
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
    cOrderID = json['C_Order_ID'] != null
        ? IdempiereSalesOrder.fromJson(json['C_Order_ID'])
        : null;
    line = json['Line'];
    dateOrdered = json['DateOrdered'];
    datePromised = json['DatePromised'];
    dateDelivered = json['DateDelivered'];
    mProductID = json['M_Product_ID'] != null
        ? IdempiereProduct.fromJson(json['M_Product_ID'])
        : null;
    cUOMID = json['C_UOM_ID'] != null
        ? IdempiereUOM.fromJson(json['C_UOM_ID'])
        : null;
    mWarehouseID = json['M_Warehouse_ID'] != null
        ? IdempiereWarehouse.fromJson(json['M_Warehouse_ID'])
        : null;
    qtyOrdered = json['QtyOrdered']?.toDouble();
    qtyReserved = json['QtyReserved']?.toDouble();
    qtyDelivered = json['QtyDelivered']?.toDouble();
    qtyInvoiced = json['QtyInvoiced']?.toDouble();
    cCurrencyID = json['C_Currency_ID'] != null
        ? IdempiereCurrency.fromJson(json['C_Currency_ID'])
        : null;
    priceList = json['PriceList']?.toDouble();
    priceActual = json['PriceActual']?.toDouble();
    cTaxID = json['C_Tax_ID'] != null
        ? IdempiereTax.fromJson(json['C_Tax_ID'])
        : null;
    cBPartnerID = json['C_BPartner_ID'] != null
        ? IdempiereBusinessPartner.fromJson(json['C_BPartner_ID'])
        : null;
    freightAmt = json['FreightAmt'];
    cBPartnerLocationID = json['C_BPartner_Location_ID'] != null
        ? IdempiereBusinessPartnerLocation.fromJson(json['C_BPartner_Location_ID'])
        : null;
    lineNetAmt = json['LineNetAmt']?.toDouble();
    priceLimit = json['PriceLimit']?.toDouble();
    discount = json['Discount']?.toDouble();
    mAttributeSetInstanceID = json['M_AttributeSetInstance_ID'] != null
        ? IdempiereAttributeSetInstance.fromJson(
        json['M_AttributeSetInstance_ID'])
        : null;
    isDescription = json['IsDescription'];
    processed = json['Processed'];
    priceEntered = json['PriceEntered']?.toDouble();
    qtyEntered = json['QtyEntered']?.toDouble();
    qtyLostSales = json['QtyLostSales']?.toDouble();
    productName = json['ProductName'];
    sKU = json['SKU'];
    uPC = json['UPC'];
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null; 
    name = json['name'];

  }

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
    if (cOrderID != null) {
      data['C_Order_ID'] = cOrderID!.toJson();
    }
    data['Line'] = line;
    data['DateOrdered'] = dateOrdered;
    data['DatePromised'] = datePromised;
    data['DateDelivered'] = dateDelivered;
    if (mProductID != null) {
      data['M_Product_ID'] = mProductID!.toJson();
    }
    if (cUOMID != null) {
      data['C_UOM_ID'] = cUOMID!.toJson();
    }
    if (mWarehouseID != null) {
      data['M_Warehouse_ID'] = mWarehouseID!.toJson();
    }
    data['QtyOrdered'] = qtyOrdered;
    data['QtyReserved'] = qtyReserved;
    data['QtyDelivered'] = qtyDelivered;
    data['QtyInvoiced'] = qtyInvoiced;
    if (cCurrencyID != null) {
      data['C_Currency_ID'] = cCurrencyID!.toJson();
    }
    data['PriceList'] = priceList;
    data['PriceActual'] = priceActual;
    if (cTaxID != null) {
      data['C_Tax_ID'] = cTaxID!.toJson();
    }
    if (cBPartnerID != null) {
      data['C_BPartner_ID'] = cBPartnerID!.toJson();
    }
    data['FreightAmt'] = freightAmt;
    if (cBPartnerLocationID != null) {
      data['C_BPartner_Location_ID'] = cBPartnerLocationID!.toJson();
    }
    data['LineNetAmt'] = lineNetAmt;
    data['PriceLimit'] = priceLimit;
    data['Discount'] = discount;
    if (mAttributeSetInstanceID != null) {
      data['M_AttributeSetInstance_ID'] =
          mAttributeSetInstanceID!.toJson();
    }
    data['IsDescription'] = isDescription;
    data['Processed'] = processed;
    data['PriceEntered'] = priceEntered;
    data['QtyEntered'] = qtyEntered;
    data['QtyLostSales'] = qtyLostSales;
    data['ProductName'] = productName;
    data['SKU'] = sKU;
    data['UPC'] = uPC;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['name'] = name;
    return data;
  }
  IdempiereSalesOrderLine copyWith({
    String? uid,
    IdempiereTenant? aDClientID,
    IdempiereOrganization? aDOrgID,
    bool? isActive,
    String? created,
    IdempiereUser? createdBy,
    String? updated,
    IdempiereUser? updatedBy,
    IdempiereSalesOrder? cOrderID,
    int? line,
    String? dateOrdered,
    String? datePromised,
    String? dateDelivered,
    IdempiereProduct? mProductID,
    IdempiereUOM? cUOMID,
    IdempiereWarehouse? mWarehouseID,
    double? qtyOrdered,
    double? qtyReserved,
    double? qtyDelivered,
    double? qtyInvoiced,
    IdempiereCurrency? cCurrencyID,
    double? priceList,
    double? priceActual,
    IdempiereTax? cTaxID,
    IdempiereBusinessPartner? cBPartnerID,
    int? freightAmt,
    IdempiereBusinessPartnerLocation? cBPartnerLocationID,
    double? lineNetAmt,
    double? priceLimit,
    double? discount,
    IdempiereAttributeSetInstance? mAttributeSetInstanceID,
    bool? isDescription,
    bool? processed,
    double? priceEntered,
    double? qtyEntered,
    double? qtyLostSales,
    String? productName,
    String? sKU,
    String? uPC,

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
    return IdempiereSalesOrderLine(
      uid: uid ?? this.uid,
      aDClientID: aDClientID ?? this.aDClientID,
      aDOrgID: aDOrgID ?? this.aDOrgID,
      isActive: isActive ?? this.isActive,
      created: created ?? this.created,
      createdBy: createdBy ?? this.createdBy,
      updated: updated ?? this.updated,
      updatedBy: updatedBy ?? this.updatedBy,
      cOrderID: cOrderID ?? this.cOrderID,
      line: line ?? this.line,
      dateOrdered: dateOrdered ?? this.dateOrdered,
      datePromised: datePromised ?? this.datePromised,
      dateDelivered: dateDelivered ?? this.dateDelivered,
      mProductID: mProductID ?? this.mProductID,
      cUOMID: cUOMID ?? this.cUOMID,
      mWarehouseID: mWarehouseID ?? this.mWarehouseID,
      qtyOrdered: qtyOrdered ?? this.qtyOrdered,
      qtyReserved: qtyReserved ?? this.qtyReserved,
      qtyDelivered: qtyDelivered ?? this.qtyDelivered,
      qtyInvoiced: qtyInvoiced ?? this.qtyInvoiced,
      cCurrencyID: cCurrencyID ?? this.cCurrencyID,
      priceList: priceList ?? this.priceList,
      priceActual: priceActual ?? this.priceActual,
      cTaxID: cTaxID ?? this.cTaxID,
      cBPartnerID: cBPartnerID ?? this.cBPartnerID,
      freightAmt: freightAmt ?? this.freightAmt,
      cBPartnerLocationID:
      cBPartnerLocationID ?? this.cBPartnerLocationID,
      lineNetAmt: lineNetAmt ?? this.lineNetAmt,
      priceLimit: priceLimit ?? this.priceLimit,
      discount: discount ?? this.discount,
      mAttributeSetInstanceID:
      mAttributeSetInstanceID ?? this.mAttributeSetInstanceID,
      isDescription: isDescription ?? this.isDescription,
      processed: processed ?? this.processed,
      priceEntered: priceEntered ?? this.priceEntered,
      qtyEntered: qtyEntered ?? this.qtyEntered,
      qtyLostSales: qtyLostSales ?? this.qtyLostSales,
      productName: productName ?? this.productName,
      sKU: sKU ?? this.sKU,
      uPC: uPC ?? this.uPC,

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

