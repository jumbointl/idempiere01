import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import 'idempiere_attribute_set_instance.dart';
import 'idempiere_charge.dart';
import 'idempiere_inventory.dart';
import 'idempiere_locator.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'idempiere_product.dart';
import 'idempiere_reference_list.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';
import 'object_with_name_and_id.dart';

class IdempiereInventoryLine extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  IdempiereInventory? mInventoryID;
  IdempiereLocator? mLocatorID;
  IdempiereProduct? mProductID;
  double? qtyBook;
  double? qtyCount;
  double? line;
  IdempiereAttributeSetInstance? mAttributeSetInstanceID;
  IdempiereCharge? cChargeID;
  IdempiereReferenceList? inventoryType;
  bool? processed;
  double? qtyInternalUse;
  String? value;
  String? uPC;
  double? qtyCsv;
  double? currentCostPrice;
  double? newCostPrice;
  String? productName;
  int? moliInventoryLineID;
  double? moliMovementQty;
  String? sKU;

  IdempiereInventoryLine({
    this.uid,
    this.aDClientID,
    this.aDOrgID,
    this.isActive,
    this.created,
    this.createdBy,
    this.updated,
    this.updatedBy,
    this.mInventoryID,
    this.mLocatorID,
    this.mProductID,
    this.qtyBook,
    this.qtyCount,
    this.line,
    this.mAttributeSetInstanceID,
    this.cChargeID,
    this.inventoryType,
    this.processed,
    this.qtyInternalUse,
    this.value,
    this.uPC,
    this.qtyCsv,
    this.currentCostPrice,
    this.newCostPrice,
    this.productName,
    this.moliInventoryLineID,
    this.moliMovementQty,
    this.sKU,
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName = 'm_inventoryline',
    super.image,
    super.category,
  });

  IdempiereInventoryLine.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];

    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;

    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;

    isActive = getBoolFromJson(json['IsActive']);
    created = json['Created'];

    createdBy = json['CreatedBy'] != null
        ? IdempiereUser.fromJson(json['CreatedBy'])
        : null;

    updated = json['Updated'];

    updatedBy = json['UpdatedBy'] != null
        ? IdempiereUser.fromJson(json['UpdatedBy'])
        : null;

    mInventoryID = json['M_Inventory_ID'] != null
        ? IdempiereInventory.fromJson(json['M_Inventory_ID'])
        : null;

    mLocatorID = json['M_Locator_ID'] != null
        ? IdempiereLocator.fromJson(json['M_Locator_ID'])
        : null;

    mProductID = json['M_Product_ID'] != null
        ? IdempiereProduct.fromJson(json['M_Product_ID'])
        : null;

    qtyBook = json['QtyBook'] != null
        ? double.tryParse(json['QtyBook'].toString())
        : null;

    qtyCount = json['QtyCount'] != null
        ? double.tryParse(json['QtyCount'].toString())
        : null;

    line = json['Line'] != null
        ? double.tryParse(json['Line'].toString())
        : null;

    mAttributeSetInstanceID = json['M_AttributeSetInstance_ID'] != null
        ? IdempiereAttributeSetInstance.fromJson(
      json['M_AttributeSetInstance_ID'],
    )
        : null;

    cChargeID = json['C_Charge_ID'] != null
        ? IdempiereCharge.fromJson(json['C_Charge_ID'])
        : null;

    inventoryType = json['InventoryType'] != null
        ? IdempiereReferenceList.fromJson(json['InventoryType'])
        : null;

    processed = getBoolFromJson(json['Processed']);

    qtyInternalUse = json['QtyInternalUse'] != null
        ? double.tryParse(json['QtyInternalUse'].toString())
        : null;

    value = json['Value'];
    uPC = json['UPC'];

    qtyCsv = json['QtyCsv'] != null
        ? double.tryParse(json['QtyCsv'].toString())
        : null;

    currentCostPrice = json['CurrentCostPrice'] != null
        ? double.tryParse(json['CurrentCostPrice'].toString())
        : null;

    newCostPrice = json['NewCostPrice'] != null
        ? double.tryParse(json['NewCostPrice'].toString())
        : null;

    productName = json['ProductName'];
    moliInventoryLineID = json['Moli_InventoryLine_ID'];
    moliMovementQty = json['Moli_MovementQty'] != null
        ? double.tryParse(json['Moli_MovementQty'].toString())
        : null;

    sKU = json['SKU'];

    modelName = json['model-name'];
    active = getBoolFromJson(json['active']);
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null
        ? ObjectWithNameAndId.fromJson(json['category'])
        : null;
    name = json['name'];
  }

  String get locatorName => mLocatorID?.value ?? mLocatorID?.identifier ?? '';

  String get productNameWithLine => '#$lineWithoutDigit ${productName ?? '--'}';

  String get lineWithoutDigit => Memory.numberFormatter0Digit.format(line);

  String? get attributeName => mAttributeSetInstanceID?.identifier;

  String get qtyCountString => Memory.numberFormatter0Digit.format(qtyCount);

  String get qtyBookString => Memory.numberFormatter0Digit.format(qtyBook);

  String get differenceQtyString {
    final double diff = (qtyCount ?? 0) - (qtyBook ?? 0);
    return Memory.numberFormatter0Digit.format(diff);
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

    if (mInventoryID != null) {
      data['M_Inventory_ID'] = mInventoryID!.toJson();
    }

    if (mLocatorID != null) {
      data['M_Locator_ID'] = mLocatorID!.toJson();
    }

    if (mProductID != null) {
      data['M_Product_ID'] = mProductID!.toJson();
    }

    data['QtyBook'] = qtyBook;
    data['QtyCount'] = qtyCount;
    data['Line'] = line;

    if (mAttributeSetInstanceID != null) {
      data['M_AttributeSetInstance_ID'] = mAttributeSetInstanceID!.toJson();
    }

    if (cChargeID != null) {
      data['C_Charge_ID'] = cChargeID!.toJson();
    }

    if (inventoryType != null) {
      data['InventoryType'] = inventoryType!.toJson();
    }

    data['Processed'] = processed;
    data['QtyInternalUse'] = qtyInternalUse;
    data['Value'] = value;
    data['UPC'] = uPC;
    data['QtyCsv'] = qtyCsv;
    data['CurrentCostPrice'] = currentCostPrice;
    data['NewCostPrice'] = newCostPrice;
    data['ProductName'] = productName;
    data['Moli_InventoryLine_ID'] = moliInventoryLineID;
    data['Moli_MovementQty'] = moliMovementQty;
    data['SKU'] = sKU;

    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['name'] = name;

    return data;
  }

  static List<IdempiereInventoryLine> fromJsonList(List<dynamic> list) {
    final List<IdempiereInventoryLine> result = [];
    for (final item in list) {
      if (item is IdempiereInventoryLine) {
        result.add(item);
      } else if (item is Map<String, dynamic>) {
        result.add(IdempiereInventoryLine.fromJson(item));
      }
    }
    return result;
  }

  @override
  List<String> getOtherDataToDisplay() {
    final List<String> list = [];

    if (id != null) {
      list.add('${Messages.ID}: ${id ?? '--'}');
    }
    if (productName != null) {
      list.add('${Messages.PRODUCT_NAME}: ${productName ?? '--'}');
    }
    if (qtyBook != null) {
      list.add('Qty Book: ${qtyBook ?? '--'}');
    }
    if (qtyCount != null) {
      list.add('Qty Count: ${qtyCount ?? '--'}');
    }
    if (updated != null) {
      list.add('${Messages.DATE}: ${updated ?? '--'}');
    }

    return list;
  }
}