

import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_MOLIHSID.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product_line.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/object_with_name_and_id.dart';

import 'idempiere_UOM.dart';
import 'idempiere_organization.dart';
import 'idempiere_product_brand.dart';
import 'idempiere_product_category.dart';
import 'idempiere_resource.dart';
import 'idempiere_tax_category.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import 'idempiere_attribute_set_instance.dart';
import 'idempiere_object.dart';
import 'idempiere_product_type.dart';

class IdempiereProduct extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  bool? isSummary;
  IdempiereUOM? cUOMID;
  bool? isStocked;
  bool? isPurchased;
  bool? isSold;
  int? volume;
  double? weight;
  String? value;
  IdempiereProductCategory? mProductCategoryID;
  IdempiereTaxCategory? cTaxCategoryID;
  bool? discontinued;
  bool? isBOM;
  bool? isInvoicePrintDetails;
  bool? isPickListPrintDetails;
  bool? isVerified;
  IdempiereResource? sResourceID;
  IdempiereProductType? productType;
  IdempiereAttributeSetInstance? mAttributeSetInstanceID;
  bool? isWebStoreFeatured;
  bool? isSelfService;
  bool? isDropShip;
  bool? isExcludeAutoDelivery;
  int? unitsPerPack;
  int? lowLevel;
  bool? isKanban;
  bool? isManufactured;
  bool? isPhantom;
  bool? isOwnBox;
  bool? isAutoProduce;
  int? mOLIMProductID;
  bool? mOLIIsLocalVendor;
  double? price;
  String? image1;
  String? uPC;
  String? sKU;
  IdempiereUser? salesRepID;
  int? shelfWidth;
  int? shelfHeight;
  int? shelfDepth;
  int? unitsPerPallet;
  int? guaranteeDays;
  int? guaranteeDaysMin;
  String? imageURL;

  String? mOLIConfigurableSKU;
  String? descriptionURL;
  IdempiereProductBrand? mOLIProductBrandID;
  IdempiereProductLine? mOLIProductLineID;
  IdempiereMOLIHSID? mOLIHSID;

  IdempiereProduct(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.isSummary,
        this.cUOMID,
        this.isStocked,
        this.isPurchased,
        this.isSold,
        this.volume,
        this.weight,
        this.value,
        this.mProductCategoryID,
        this.cTaxCategoryID,
        this.discontinued,
        this.isBOM,
        this.isInvoicePrintDetails,
        this.isPickListPrintDetails,
        this.isVerified,
        this.sResourceID,
        this.productType,
        this.mAttributeSetInstanceID,
        this.isWebStoreFeatured,
        this.isSelfService,
        this.isDropShip,
        this.isExcludeAutoDelivery,
        this.unitsPerPack,
        this.lowLevel,
        this.isKanban,
        this.isManufactured,
        this.isPhantom,
        this.isOwnBox,
        this.isAutoProduce,
        this.mOLIMProductID,
        this.mOLIIsLocalVendor,
        this.price,
        this.image1,
        this.uPC,
        this.sKU,
        this.salesRepID,
        this.shelfWidth,
        this.shelfHeight,
        this.shelfDepth,
        this.unitsPerPallet,
        this.guaranteeDays,
        this.guaranteeDaysMin,
        this.mOLIConfigurableSKU,
        this.descriptionURL,
        this.mOLIProductBrandID,
        this.mOLIProductLineID,
        this.mOLIHSID,
        this.imageURL,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
      });

  IdempiereProduct.fromJson(Map<String, dynamic> json) {
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
    isSummary = json['IsSummary'];
    cUOMID = json['C_UOM_ID'] != null
        ? IdempiereUOM.fromJson(json['C_UOM_ID'])
        : null;
    isStocked = json['IsStocked'];
    isPurchased = json['IsPurchased'];
    isSold = json['IsSold'];
    volume = json['Volume'];
    weight = json['Weight']!=null ? double.tryParse(json['Weight'].toString()) : null;
    value = json['Value'];
    mProductCategoryID = json['M_Product_Category_ID'] != null
        ? IdempiereProductCategory.fromJson(json['M_Product_Category_ID'])
        : null;
    cTaxCategoryID = json['C_TaxCategory_ID'] != null
        ? IdempiereTaxCategory.fromJson(json['C_TaxCategory_ID'])
        : null;
    discontinued = json['Discontinued'];
    isBOM = json['IsBOM'];
    isInvoicePrintDetails = json['IsInvoicePrintDetails'];
    isPickListPrintDetails = json['IsPickListPrintDetails'];
    isVerified = json['IsVerified'];
    sResourceID = json['S_Resource_ID'] != null
        ? IdempiereResource.fromJson(json['S_Resource_ID'])
        : null;
    productType = json['ProductType'] != null
        ? IdempiereProductType.fromJson(json['ProductType'])
        : null;
    mAttributeSetInstanceID = json['M_AttributeSetInstance_ID'] != null
        ? IdempiereAttributeSetInstance.fromJson(
        json['M_AttributeSetInstance_ID'])
        : null;
    isWebStoreFeatured = json['IsWebStoreFeatured'];
    isSelfService = json['IsSelfService'];
    isDropShip = json['IsDropShip'];
    isExcludeAutoDelivery = json['IsExcludeAutoDelivery'];
    unitsPerPack = json['UnitsPerPack'];
    lowLevel = json['LowLevel'];
    isKanban = json['IsKanban'];
    isManufactured = json['IsManufactured'];
    isPhantom = json['IsPhantom'];
    isOwnBox = json['IsOwnBox'];
    isAutoProduce = json['IsAutoProduce'];
    mOLIMProductID = json['MOLI_M_Product_ID'];
    mOLIIsLocalVendor = json['MOLI_IsLocalVendor'];
    modelName = json['model-name'];

    guaranteeDays = json['GuaranteeDays'];
    guaranteeDaysMin = json['GuaranteeDaysMin'];
    price = json['Price'];
    image1 = json['Image1'];
    uPC = json['UPC'];
    sKU = json['SKU'];
    shelfWidth = json['ShelfWidth'];
    shelfHeight = json['ShelfHeight'];
    shelfDepth = json['ShelfDepth'];
    unitsPerPallet = json['UnitsPerPallet'];
    discontinued = json['Discontinued'];
    salesRepID = json['SalesRep_ID'] != null
        ? IdempiereUser.fromJson(json['SalesRep_ID'])
        : null;
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
    descriptionURL = json['DescriptionURL'];
    mOLIProductBrandID = json['MOLI_ProductBrand_ID'] != null
        ? IdempiereProductBrand.fromJson(json['MOLI_ProductBrand_ID'])
        : null;
    mOLIProductLineID = json['MOLI_ProductLine_ID'] != null
        ? IdempiereProductLine.fromJson(json['MOLI_ProductLine_ID'])
        : null;
    mOLIHSID = json['MOLI_HS_ID'] != null
        ? IdempiereMOLIHSID.fromJson(json['MOLI_HS_ID'])
        : null;
    mOLIConfigurableSKU = json['MOLI_ConfigurableSKU'];
    imageURL = json['ImageURL'];

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
    data['IsSummary'] = isSummary;
    if (cUOMID != null) {
      data['C_UOM_ID'] = cUOMID!.toJson();
    }
    data['IsStocked'] = isStocked;
    data['IsPurchased'] = isPurchased;
    data['IsSold'] = isSold;
    data['Volume'] = volume;
    data['Weight'] = weight;
    data['Value'] = value;
    if (mProductCategoryID != null) {
      data['M_Product_Category_ID'] = mProductCategoryID!.toJson();
    }
    if (cTaxCategoryID != null) {
      data['C_TaxCategory_ID'] = cTaxCategoryID!.toJson();
    }
    data['Discontinued'] = discontinued;
    data['IsBOM'] = isBOM;
    data['IsInvoicePrintDetails'] = isInvoicePrintDetails;
    data['IsPickListPrintDetails'] = isPickListPrintDetails;
    data['IsVerified'] = isVerified;
    if (sResourceID != null) {
      data['S_Resource_ID'] = sResourceID!.toJson();
    }
    if (productType != null) {
      data['ProductType'] = productType!.toJson();
    }
    if (mAttributeSetInstanceID != null) {
      data['M_AttributeSetInstance_ID'] =
          mAttributeSetInstanceID!.toJson();
    }
    data['IsWebStoreFeatured'] = isWebStoreFeatured;
    data['IsSelfService'] = isSelfService;
    data['IsDropShip'] = isDropShip;
    data['IsExcludeAutoDelivery'] = isExcludeAutoDelivery;
    data['UnitsPerPack'] = unitsPerPack;
    data['LowLevel'] = lowLevel;
    data['IsKanban'] = isKanban;
    data['IsManufactured'] = isManufactured;
    data['IsPhantom'] = isPhantom;
    data['IsOwnBox'] = isOwnBox;
    data['IsAutoProduce'] = isAutoProduce;
    data['MOLI_M_Product_ID'] = mOLIMProductID;
    data['MOLI_IsLocalVendor'] = mOLIIsLocalVendor;
    data['model-name'] = modelName;
    data['GuaranteeDays'] = guaranteeDays;
    data['GuaranteeDaysMin'] = guaranteeDaysMin;
    data['Price'] = price;
    data['Image1'] = image1;
    data['UPC'] = uPC;
    data['SKU'] = sKU;
    data['ShelfWidth'] = shelfWidth;
    data['ShelfHeight'] = shelfHeight;
    data['ShelfDepth'] = shelfDepth;
    data['UnitsPerPallet'] = unitsPerPallet;
    data['Discontinued'] = discontinued;
    data['SalesRep_ID'] = salesRepID;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();

    data['MOLI_ConfigurableSKU'] = mOLIConfigurableSKU;
    if (mOLIHSID != null) {
      data['MOLI_HS_ID'] = mOLIHSID!.toJson();
    }
    if (mOLIProductBrandID != null) {
      data['MOLI_ProductBrand_ID'] = mOLIProductBrandID!.toJson();
    }
    if (mOLIProductLineID != null) {
      data['MOLI_ProductLine_ID'] = mOLIProductLineID!.toJson();
    }
    data['DescriptionURL'] = descriptionURL;
    data['ImageURL'] = imageURL;



    return data;
  }
  static List<IdempiereProduct> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereProduct.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereProduct.fromJson(item)).toList();
    }

    List<IdempiereProduct> newList =[];
    for (var item in json) {
      if(item is IdempiereProduct){
      newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereProduct idempiereProduct = IdempiereProduct.fromJson(item);
        newList.add(idempiereProduct);
      }
    }

    return newList;
  }

  IdempiereProduct copyWith({
    String? uid,
    IdempiereTenant? aDClientID,
    IdempiereOrganization? aDOrgID,
    bool? isActive,
    String? created,
    IdempiereUser? createdBy,
    String? updated,
    IdempiereUser? updatedBy,
    bool? isSummary,
    IdempiereUOM? cUOMID,
    bool? isStocked,
    bool? isPurchased,
    bool? isSold,
    int? volume,
    double? weight,
    String? value,
    IdempiereProductCategory? mProductCategoryID,
    IdempiereTaxCategory? cTaxCategoryID,
    bool? discontinued,
    bool? isBOM,
    bool? isInvoicePrintDetails,
    bool? isPickListPrintDetails,
    bool? isVerified,
    IdempiereResource? sResourceID,
    IdempiereProductType? productType,
    IdempiereAttributeSetInstance? mAttributeSetInstanceID,
    bool? isWebStoreFeatured,
    bool? isSelfService,
    bool? isDropShip,
    bool? isExcludeAutoDelivery,
    int? unitsPerPack,
    int? lowLevel,
    bool? isKanban,
    bool? isManufactured,
    bool? isPhantom,
    bool? isOwnBox,
    bool? isAutoProduce,
    int? mOLIMProductID,
    bool? mOLIIsLocalVendor,
    double? price,
    String? image1,
    String? uPC,
    String? sKU,
    IdempiereUser? salesRepID,
    int? shelfWidth,
    int? shelfHeight,
    int? shelfDepth,
    int? unitsPerPallet,
    int? guaranteeDays,
    int? guaranteeDaysMin,
    int? id,
    String? name,
    bool? active,
    String? propertyLabel,
    String? identifier,
    String? modelName,
    String? image,
    ObjectWithNameAndId? category,
    String? descriptionURL,
    IdempiereProductBrand? mOLIProductBrandID,
    IdempiereProductLine? mOLIProductLineID,
    IdempiereMOLIHSID? mOLIHSID,
    String? mOLIConfigurableSKU,
    String? imageURL,
  }) {
    return IdempiereProduct(
      uid: uid ?? this.uid,
      aDClientID: aDClientID ?? this.aDClientID,
      aDOrgID: aDOrgID ?? this.aDOrgID,
      isActive: isActive ?? this.isActive,
      created: created ?? this.created,
      createdBy: createdBy ?? this.createdBy,
      updated: updated ?? this.updated,
      updatedBy: updatedBy ?? this.updatedBy,
      isSummary: isSummary ?? this.isSummary,
      cUOMID: cUOMID ?? this.cUOMID,
      isStocked: isStocked ?? this.isStocked,
      isPurchased: isPurchased ?? this.isPurchased,
      isSold: isSold ?? this.isSold,
      volume: volume ?? this.volume,
      weight: weight ?? this.weight,
      value: value ?? this.value,
      mProductCategoryID: mProductCategoryID ?? this.mProductCategoryID,
      cTaxCategoryID: cTaxCategoryID ?? this.cTaxCategoryID,
      discontinued: discontinued ?? this.discontinued,
      isBOM: isBOM ?? this.isBOM,
      isInvoicePrintDetails: isInvoicePrintDetails ?? this.isInvoicePrintDetails,
      isPickListPrintDetails: isPickListPrintDetails ?? this.isPickListPrintDetails,
      isVerified: isVerified ?? this.isVerified,
      sResourceID: sResourceID ?? this.sResourceID,
      productType: productType ?? this.productType,
      mAttributeSetInstanceID: mAttributeSetInstanceID ?? this.mAttributeSetInstanceID,
      isWebStoreFeatured: isWebStoreFeatured ?? this.isWebStoreFeatured,
      isSelfService: isSelfService ?? this.isSelfService,
      isDropShip: isDropShip ?? this.isDropShip,
      isExcludeAutoDelivery: isExcludeAutoDelivery ?? this.isExcludeAutoDelivery,
      unitsPerPack: unitsPerPack ?? this.unitsPerPack,
      lowLevel: lowLevel ?? this.lowLevel,
      isKanban: isKanban ?? this.isKanban,
      isManufactured: isManufactured ?? this.isManufactured,
      isPhantom: isPhantom ?? this.isPhantom,
      isOwnBox: isOwnBox ?? this.isOwnBox,
      isAutoProduce: isAutoProduce ?? this.isAutoProduce,
      mOLIMProductID: mOLIMProductID ?? this.mOLIMProductID,
      mOLIIsLocalVendor: mOLIIsLocalVendor ?? this.mOLIIsLocalVendor,
      price: price ?? this.price,
      image1: image1 ?? this.image1,
      uPC: uPC ?? this.uPC,
      sKU: sKU ?? this.sKU,
      salesRepID: salesRepID ?? this.salesRepID,
      shelfWidth: shelfWidth ?? this.shelfWidth,
      shelfHeight: shelfHeight ?? this.shelfHeight,
      shelfDepth: shelfDepth ?? this.shelfDepth,
      unitsPerPallet: unitsPerPallet ?? this.unitsPerPallet,
      guaranteeDays: guaranteeDays ?? this.guaranteeDays,
      guaranteeDaysMin: guaranteeDaysMin ?? this.guaranteeDaysMin,
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      propertyLabel: propertyLabel ?? this.propertyLabel,
      identifier: identifier ?? this.identifier,
      modelName: modelName ?? this.modelName,
      image: image ?? this.image,
      category: category ?? this.category,
      descriptionURL: descriptionURL ?? this.descriptionURL,
      mOLIProductBrandID: mOLIProductBrandID ?? this.mOLIProductBrandID,
      mOLIProductLineID: mOLIProductLineID ?? this.mOLIProductLineID,
      mOLIHSID: mOLIHSID ?? this.mOLIHSID,
      mOLIConfigurableSKU: mOLIConfigurableSKU ?? this.mOLIConfigurableSKU,
    );
  }
}






