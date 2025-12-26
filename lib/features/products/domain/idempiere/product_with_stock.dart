

import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_MOLIHSID.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product_line.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_storage_on_hande.dart';
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
import 'idempiere_product_type.dart';

class ProductWithStock extends IdempiereProduct {
  List<IdempiereStorageOnHande>? listStorageOnHande;
  List<IdempiereStorageOnHande>? sortedStorageOnHande;
  bool? searched = false;
  bool? showResultCard = true;
  String? searchString ;

  ProductWithStock(
      {
        super.uid,
        super.aDClientID,
        super.aDOrgID,
        super.isActive,
        super.created,
        super.createdBy,
        super.updated,
        super.updatedBy,
        super.isSummary,
        super.cUOMID,
        super.isStocked,
        super.isPurchased,
        super.isSold,
        super.volume,
        super.weight,
        super.value,
        super.mProductCategoryID,
        super.cTaxCategoryID,
        super.discontinued,
        super.isBOM,
        super.isInvoicePrintDetails,
        super.isPickListPrintDetails,
        super.isVerified,
        super.sResourceID,
        super.productType,
        super.mAttributeSetInstanceID,
        super.isWebStoreFeatured,
        super.isSelfService,
        super.isDropShip,
        super.isExcludeAutoDelivery,
        super.unitsPerPack,
        super.lowLevel,
        super.isKanban,
        super.isManufactured,
        super.isPhantom,
        super.isOwnBox,
        super.isAutoProduce,
        super.mOLIMProductID,
        super.mOLIIsLocalVendor,
        super.price,
        super.image1,
        super.uPC,
        super.sKU,
        super.salesRepID,
        super.shelfWidth,
        super.shelfHeight,
        super.shelfDepth,
        super.unitsPerPallet,
        super.guaranteeDays,
        super.guaranteeDaysMin,
        super.mOLIConfigurableSKU,
        super.descriptionURL,
        super.mOLIProductBrandID,
        super.mOLIProductLineID,
        super.mOLIHSID,
        super.imageURL,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
        this.listStorageOnHande,
        this.sortedStorageOnHande,
        this.searched,
        this.showResultCard,
        this.searchString,
      });

  ProductWithStock.fromJson(Map<String, dynamic> json) {
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
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;;
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
    listStorageOnHande = json['listStorageOnHande'] != null ? IdempiereStorageOnHande.fromJsonList(json['listStorageOnHande']) : null;
    searched = json['searched'];
    showResultCard = json['showResultCard'];
    sortedStorageOnHande = json['sortedStorageOnHande'] != null ? IdempiereStorageOnHande.fromJsonList(json['sortedStorageOnHande']) : null;
    searchString = json['searchString'];

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
    data['listStorageOnHande'] = listStorageOnHande?.map((x) => x.toJson()).toList();
    data['searched'] = searched;
    data['showResultCard'] = showResultCard;
    data['sortedStorageOnHande'] = sortedStorageOnHande?.map((x) => x.toJson()).toList();
    data['searchString'] = searchString;


    return data;
  }
  static List<ProductWithStock> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [ProductWithStock.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => ProductWithStock.fromJson(item)).toList();
    }

    List<ProductWithStock> newList =[];
    for (var item in json) {
      if(item is ProductWithStock){
      newList.add(item);
      } else if(item is Map<String, dynamic>){
        ProductWithStock productWithStock = ProductWithStock.fromJson(item);
        newList.add(productWithStock);
      }
    }

    return newList;
  }
  void copyWithProduct(IdempiereProduct product){
    uid=product.uid;
    aDClientID= product.aDClientID;
    aDOrgID= product.aDOrgID;
    isActive= product.isActive;
    created= product.created;
    createdBy= product.createdBy;
    updated= product.updated;
    updatedBy= product.updatedBy;
    isSummary= product.isSummary;
    cUOMID= product.cUOMID;
    isStocked= product.isStocked;
    isPurchased= product.isPurchased;
    isSold= product.isSold;
    volume= product.volume;
    weight= product.weight;
    value=  product.value;
    mProductCategoryID= product.mProductCategoryID;
    cTaxCategoryID= product.cTaxCategoryID;
    discontinued= product.discontinued;
    isBOM= product.isBOM;
    isInvoicePrintDetails= product.isInvoicePrintDetails;
    isPickListPrintDetails=  product.isPickListPrintDetails;
    isVerified= product.isVerified;
    sResourceID= product.sResourceID;
    productType= product.productType;
    mAttributeSetInstanceID= product.mAttributeSetInstanceID;
    isWebStoreFeatured= product.isWebStoreFeatured;
    isSelfService= product.isSelfService;
    isDropShip= product.isDropShip;
    isExcludeAutoDelivery= product.isExcludeAutoDelivery;
    unitsPerPack= product.unitsPerPack;
    lowLevel= product.lowLevel;
    isKanban= product.isKanban;
    isManufactured= product.isManufactured;
    isPhantom= product.isPhantom;
    isOwnBox= product.isOwnBox;
    isAutoProduce= product.isAutoProduce;
    mOLIMProductID= product.mOLIMProductID;
    mOLIIsLocalVendor= product.mOLIIsLocalVendor;
    price= product.price;
    image1= product.image1;
    uPC= product.uPC;
    sKU= product.sKU;
    salesRepID= product.salesRepID;
    shelfWidth= product.shelfWidth;
    shelfHeight= product.shelfHeight;
    shelfDepth= product.shelfDepth;
    unitsPerPallet= product.unitsPerPallet;
    guaranteeDays=  product.guaranteeDays;
    guaranteeDaysMin= product.guaranteeDaysMin;
    id= product.id;
    name= product.name;
    active= product.active;
    propertyLabel= product.propertyLabel;
    identifier= product.identifier;
    modelName= product.modelName;
    image= product.image;
    category= product.category;
    descriptionURL= product.descriptionURL;
    mOLIProductBrandID= product.mOLIProductBrandID;
    mOLIProductLineID=  product.mOLIProductLineID;
    mOLIHSID= product.mOLIHSID;
    mOLIConfigurableSKU= product.mOLIConfigurableSKU;
    imageURL= product.imageURL;

  }
  void copyWithProductWithStock(ProductWithStock product){
    uid=product.uid;
    aDClientID= product.aDClientID;
    aDOrgID= product.aDOrgID;
    isActive= product.isActive;
    created= product.created;
    createdBy= product.createdBy;
    updated= product.updated;
    updatedBy= product.updatedBy;
    isSummary= product.isSummary;
    cUOMID= product.cUOMID;
    isStocked= product.isStocked;
    isPurchased= product.isPurchased;
    isSold= product.isSold;
    volume= product.volume;
    weight= product.weight;
    value=  product.value;
    mProductCategoryID= product.mProductCategoryID;
    cTaxCategoryID= product.cTaxCategoryID;
    discontinued= product.discontinued;
    isBOM= product.isBOM;
    isInvoicePrintDetails= product.isInvoicePrintDetails;
    isPickListPrintDetails=  product.isPickListPrintDetails;
    isVerified= product.isVerified;
    sResourceID= product.sResourceID;
    productType= product.productType;
    mAttributeSetInstanceID= product.mAttributeSetInstanceID;
    isWebStoreFeatured= product.isWebStoreFeatured;
    isSelfService= product.isSelfService;
    isDropShip= product.isDropShip;
    isExcludeAutoDelivery= product.isExcludeAutoDelivery;
    unitsPerPack= product.unitsPerPack;
    lowLevel= product.lowLevel;
    isKanban= product.isKanban;
    isManufactured= product.isManufactured;
    isPhantom= product.isPhantom;
    isOwnBox= product.isOwnBox;
    isAutoProduce= product.isAutoProduce;
    mOLIMProductID= product.mOLIMProductID;
    mOLIIsLocalVendor= product.mOLIIsLocalVendor;
    price= product.price;
    image1= product.image1;
    uPC= product.uPC;
    sKU= product.sKU;
    salesRepID= product.salesRepID;
    shelfWidth= product.shelfWidth;
    shelfHeight= product.shelfHeight;
    shelfDepth= product.shelfDepth;
    unitsPerPallet= product.unitsPerPallet;
    guaranteeDays=  product.guaranteeDays;
    guaranteeDaysMin= product.guaranteeDaysMin;
    id= product.id;
    name= product.name;
    active= product.active;
    propertyLabel= product.propertyLabel;
    identifier= product.identifier;
    modelName= product.modelName;
    image= product.image;
    category= product.category;
    descriptionURL= product.descriptionURL;
    mOLIProductBrandID= product.mOLIProductBrandID;
    mOLIProductLineID=  product.mOLIProductLineID;
    mOLIHSID= product.mOLIHSID;
    mOLIConfigurableSKU= product.mOLIConfigurableSKU;
    imageURL= product.imageURL;
    listStorageOnHande= product.listStorageOnHande;
    searched= product.searched;
    showResultCard=  product.showResultCard;
    sortedStorageOnHande= product.sortedStorageOnHande;



  }
  @override
  ProductWithStock copyWith({
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
    bool? searched,
    bool? showResultCard,
    List<IdempiereStorageOnHande>? listStorageOnHande,
    List<IdempiereStorageOnHande>? sortedStorageOnHande,
  }) {
    return ProductWithStock(
      uid: uid ?? super.uid,
      aDClientID: aDClientID ?? super.aDClientID,
      aDOrgID: aDOrgID ?? super.aDOrgID,
      isActive: isActive ?? super.isActive,
      created: created ?? super.created,
      createdBy: createdBy ?? super.createdBy,
      updated: updated ?? super.updated,
      updatedBy: updatedBy ?? super.updatedBy,
      isSummary: isSummary ?? super.isSummary,
      cUOMID: cUOMID ?? super.cUOMID,
      isStocked: isStocked ?? super.isStocked,
      isPurchased: isPurchased ?? super.isPurchased,
      isSold: isSold ?? super.isSold,
      volume: volume ?? super.volume,
      weight: weight ?? super.weight,
      value: value ?? super.value,
      mProductCategoryID: mProductCategoryID ?? super.mProductCategoryID,
      cTaxCategoryID: cTaxCategoryID ?? super.cTaxCategoryID,
      discontinued: discontinued ?? super.discontinued,
      isBOM: isBOM ?? super.isBOM,
      isInvoicePrintDetails: isInvoicePrintDetails ?? super.isInvoicePrintDetails,
      isPickListPrintDetails: isPickListPrintDetails ?? super.isPickListPrintDetails,
      isVerified: isVerified ?? super.isVerified,
      sResourceID: sResourceID ?? super.sResourceID,
      productType: productType ?? super.productType,
      mAttributeSetInstanceID: mAttributeSetInstanceID ?? super.mAttributeSetInstanceID,
      isWebStoreFeatured: isWebStoreFeatured ?? super.isWebStoreFeatured,
      isSelfService: isSelfService ?? super.isSelfService,
      isDropShip: isDropShip ?? super.isDropShip,
      isExcludeAutoDelivery: isExcludeAutoDelivery ?? super.isExcludeAutoDelivery,
      unitsPerPack: unitsPerPack ?? super.unitsPerPack,
      lowLevel: lowLevel ?? super.lowLevel,
      isKanban: isKanban ?? super.isKanban,
      isManufactured: isManufactured ?? super.isManufactured,
      isPhantom: isPhantom ?? super.isPhantom,
      isOwnBox: isOwnBox ?? super.isOwnBox,
      isAutoProduce: isAutoProduce ?? super.isAutoProduce,
      mOLIMProductID: mOLIMProductID ?? super.mOLIMProductID,
      mOLIIsLocalVendor: mOLIIsLocalVendor ?? super.mOLIIsLocalVendor,
      price: price ?? super.price,
      image1: image1 ?? super.image1,
      uPC: uPC ?? super.uPC,
      sKU: sKU ?? super.sKU,
      salesRepID: salesRepID ?? super.salesRepID,
      shelfWidth: shelfWidth ?? super.shelfWidth,
      shelfHeight: shelfHeight ?? super.shelfHeight,
      shelfDepth: shelfDepth ?? super.shelfDepth,
      unitsPerPallet: unitsPerPallet ?? super.unitsPerPallet,
      guaranteeDays: guaranteeDays ?? super.guaranteeDays,
      guaranteeDaysMin: guaranteeDaysMin ?? super.guaranteeDaysMin,
      id: id ?? super.id,
      name: name ?? super.name,
      active: active ?? super.active,
      propertyLabel: propertyLabel ?? super.propertyLabel,
      identifier: identifier ?? super.identifier,
      modelName: modelName ?? super.modelName,
      image: image ?? super.image,
      category: category ?? super.category,
      descriptionURL: descriptionURL ?? super.descriptionURL,
      mOLIProductBrandID: mOLIProductBrandID ?? super.mOLIProductBrandID,
      mOLIProductLineID: mOLIProductLineID ?? super.mOLIProductLineID,
      mOLIHSID: mOLIHSID ?? super.mOLIHSID,
      mOLIConfigurableSKU: mOLIConfigurableSKU ?? super.mOLIConfigurableSKU,
      searched: searched,
      showResultCard: showResultCard,
      imageURL: imageURL ?? super.imageURL,
      listStorageOnHande: listStorageOnHande,
      sortedStorageOnHande: sortedStorageOnHande,
    );
  }
  bool get isSearched => searched ?? false;
  bool get hasProduct => id != null && id! > 0;
  bool get hasListStorageOnHande => listStorageOnHande != null && listStorageOnHande!.isNotEmpty;


}






