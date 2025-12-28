import '../../../shared/data/memory.dart';
import 'idempiere_locator.dart';
import 'idempiere_movement.dart';
import 'idempiere_product.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_attribute_set_instance.dart';
import 'idempiere_object.dart';
import 'idempiere_organization.dart';
import 'object_with_name_and_id.dart';

class IdempiereMovementLine extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  IdempiereMovement? mMovementID;
  IdempiereLocator? mLocatorID;
  IdempiereLocator? mLocatorToID;
  IdempiereProduct? mProductID;
  double? movementQty;
  String? description;
  double? line;
  IdempiereAttributeSetInstance? mAttributeSetInstanceID;
  double? confirmedQty;
  double? targetQty;
  double? scrappedQty;
  bool? processed;
  String? value;
  double? priceEntered;
  double? priceList;
  double? priceActual;
  String? productName;
  double? lineNetAmt;
  String? sKU;
  String? uPC;

  IdempiereMovementLine(
      {
        this.uid,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.mMovementID,
        this.mLocatorID,
        this.mLocatorToID,
        this.mProductID,
        this.movementQty,
        this.description,
        this.line,
        this.mAttributeSetInstanceID,
        this.confirmedQty,
        this.targetQty,
        this.scrappedQty,
        this.processed,
        this.value,
        this.priceEntered,
        this.priceList,
        this.priceActual,
        this.productName,
        this.lineNetAmt,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName='m_movementline',
        super.image,
        super.category,
        this.sKU,
        this.uPC,
      });

  IdempiereMovementLine.fromJson(Map<String, dynamic> json) {
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
    mMovementID = json['M_Movement_ID'] != null
        ?  IdempiereMovement.fromJson(json['M_Movement_ID'])
        : null;
    mLocatorID = json['M_Locator_ID'] != null
        ?  IdempiereLocator.fromJson(json['M_Locator_ID'])
        : null;
    mLocatorToID = json['M_LocatorTo_ID'] != null
        ?  IdempiereLocator.fromJson(json['M_LocatorTo_ID'])
        : null;
    mProductID = json['M_Product_ID'] != null
        ?  IdempiereProduct.fromJson(json['M_Product_ID'])
        : null;
    movementQty = json['MovementQty'] != null ? double.tryParse(json['MovementQty'].toString()) : null;
    description = json['Description'];
    line = json['Line']!= null ? double.tryParse(json['Line'].toString()) : null;
    mAttributeSetInstanceID = json['M_AttributeSetInstance_ID'] != null
        ?  IdempiereAttributeSetInstance.fromJson(
        json['M_AttributeSetInstance_ID'])
        : null;
    confirmedQty = json['ConfirmedQty']!=null ? double.tryParse(json['ConfirmedQty'].toString()) : null;
    targetQty = json['TargetQty']!=null ? double.tryParse(json['TargetQty'].toString()) : null;
    scrappedQty = json['ScrappedQty']!=null ? double.tryParse(json['ScrappedQty'].toString()) : null;
    processed = json['Processed'];
    value = json['Value'];
    priceEntered = json['PriceEntered']!= null ? double.tryParse(json['PriceEntered'].toString()) : null;
    priceList = json['PriceList']!= null ? double.tryParse(json['PriceList'].toString()) : null;
    priceActual = json['PriceActual']!= null ? double.tryParse(json['PriceActual'].toString()) : null;
    productName = json['ProductName'];
    lineNetAmt = json['LineNetAmt']!= null ? double.tryParse(json['LineNetAmt'].toString()) : null;
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
    name = json['name'];
    sKU = json['SKU'];
    uPC = json['UPC'];
  }

  String get locatorToName => mLocatorToID?.value ?? mLocatorToID?.identifier ?? '';
  String get locatorFromName => mLocatorID?.value ?? mLocatorID?.identifier ?? '';

  String get productNameWithLine => '#$lineWithoutDigit ${productName ?? '--'}';
  String get lineWithoutDigit => Memory.numberFormatter0Digit.format(line);

  String? get attributeName => mAttributeSetInstanceID?.identifier;

  String get movementQtyString => Memory.numberFormatter0Digit.format(movementQty);


  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
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
    if (mMovementID != null) {
      data['M_Movement_ID'] = mMovementID!.toJson();
    }
    if (mLocatorID != null) {
      data['M_Locator_ID'] = mLocatorID!.toJson();
    }
    if (mLocatorToID != null) {
      data['M_LocatorTo_ID'] = mLocatorToID!.toJson();
    }
    if (mProductID != null) {
      data['M_Product_ID'] = mProductID!.toJson();
    }
    data['MovementQty'] = movementQty;
    data['Description'] = description;
    data['Line'] = line;
    if (mAttributeSetInstanceID != null) {
      data['M_AttributeSetInstance_ID'] =
          mAttributeSetInstanceID!.toJson();
    }
    data['ConfirmedQty'] = confirmedQty;
    data['TargetQty'] = targetQty;
    data['ScrappedQty'] = scrappedQty;
    data['Processed'] = processed;
    data['Value'] = value;
    data['PriceEntered'] = priceEntered;
    data['PriceList'] = priceList;
    data['PriceActual'] = priceActual;
    data['ProductName'] = productName;
    data['LineNetAmt'] = lineNetAmt;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['name'] = name;
    data['SKU'] = sKU;
    data['UPC'] = uPC;
    return data;
  }
  static List<IdempiereMovementLine> fromJsonList(List<dynamic> list){
    List<IdempiereMovementLine> result =[];
    for (var item in list) {
      if(item is IdempiereMovementLine){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereMovementLine idempiereMovementLine = IdempiereMovementLine.fromJson(item);
        result.add(idempiereMovementLine);
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
    if(description != null){
      list.add('${Messages.DESCRIPTION}: ${description ?? '--'}');
    }
    if( productName != null){
      list.add('${Messages.PRODUCT_NAME}: ${productName ?? '--'}');
    }
    if( movementQty != null){
      list.add('${Messages.QUANTITY}:${movementQty ?? '--'}');
    }
    if( updated != null){
      list.add('${Messages.DATE}: ${updated ?? '--'}');
    }


    return list;
  }
}



