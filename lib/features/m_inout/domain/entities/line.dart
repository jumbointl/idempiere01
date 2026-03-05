import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_sales_order_line.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/ad_entity_id.dart';

import '../../../products/domain/idempiere/idempiere_attribute_set_instance.dart';

class Line {
  int? id;
  int? line;
  double? movementQty;
  double? confirmedQty;
  double? pickedQty;
  double? scrappedQty;
  double? targetQty;
  AdEntityId? mLocatorId;
  AdEntityId? mLocatorToId;
  AdEntityId? mProductId;
  IdempiereAttributeSetInstance? mAttributeSetInstanceID;
  IdempiereSalesOrderLine? cOrderLineId;
  String? upc;
  String? sku;
  String? productName;
  String? verifiedStatus;
  int? scanningQty;
  double? manualQty;
  double? get differenceQty => (targetQty ?? 0.0) - (confirmedQty ?? 0.0) - (scrappedQty ?? 0.0);
  int? confirmId;
  int? editLocator;

  Line({
    this.id,
    this.line,
    this.movementQty,
    this.targetQty,
    this.confirmedQty,
    this.pickedQty,
    this.scrappedQty,
    this.mLocatorId,
    this.mLocatorToId,
    this.mProductId,
    this.upc,
    this.sku,
    this.productName,
    this.verifiedStatus,
    this.scanningQty,
    this.manualQty,
    this.confirmId,
    this.editLocator,
    this.mAttributeSetInstanceID,
    this.cOrderLineId,
  });

  factory Line.fromJson(Map<String, dynamic> json) => Line(
        id: json["id"],
        line: json["Line"],
        movementQty: json["MovementQty"] != null
            ? (json["MovementQty"] is double
                ? json["MovementQty"]
                : double.tryParse(json["MovementQty"].toString()) ?? 0.0)
            : 0.0,
        targetQty: json["TargetQty"] != null
            ? (json["TargetQty"] is double
                ? json["TargetQty"]
                : double.tryParse(json["TargetQty"].toString()) ?? 0.0)
            : 0.0,
        confirmedQty: json["ConfirmedQty"] != null
            ? (json["ConfirmedQty"] is double
                ? json["ConfirmedQty"]
                : double.tryParse(json["ConfirmedQty"].toString()) ?? 0.0)
            : 0.0,
        scrappedQty: json["ScrappedQty"] != null
            ? (json["ScrappedQty"] is double
                ? json["ScrappedQty"]
                : double.tryParse(json["ScrappedQty"].toString()) ?? 0.0)
            : 0.0,
        mLocatorId: AdEntityId.fromJson(json["M_Locator_ID"] ?? {}),
        mLocatorToId: AdEntityId.fromJson(json["M_LocatorTo_ID"] ?? {}),
        mProductId: AdEntityId.fromJson(json["M_Product_ID"] ?? {}),
        upc: json["UPC"],
        sku: json["SKU"],
        productName: json["ProductName"],
        verifiedStatus: json["VerifiedStatus"],
        scanningQty: json["ScanningQty"],
        manualQty: json["ManualQty"],
        confirmId: json["ConfirmId"],
        editLocator: json["EditLocator"],
        mAttributeSetInstanceID: json["M_AttributeSetInstance_ID"] != null
            ? IdempiereAttributeSetInstance.fromJson(json["M_AttributeSetInstance_ID"])
            : null,
        cOrderLineId: json["C_OrderLine_ID"] != null
            ? IdempiereSalesOrderLine.fromJson(json["C_OrderLine_ID"])
            : null,


      );

  Line copyWith({
    int? id,
    int? line,
    double? movementQty,
    double? targetQty,
    double? confirmedQty,
    double? pickedQty,
    double? scrappedQty,
    AdEntityId? mLocatorId,
    AdEntityId? mLocatorToId,
    AdEntityId? mProductId,
    String? upc,
    String? sku,
    String? productName,
    String? verifiedStatus,
    int? scanningQty,
    double? manualQty,
    int? confirmId,
    int? editLocator,
    IdempiereAttributeSetInstance? mAttributeSetInstanceID,
    IdempiereSalesOrderLine? cOrderLineId,
  }) {
    return Line(
      id: id ?? this.id,
      line: line ?? this.line,
      movementQty: movementQty ?? this.movementQty,
      targetQty: targetQty ?? this.targetQty,
      confirmedQty: confirmedQty ?? this.confirmedQty,
      pickedQty: pickedQty ?? this.pickedQty,
      scrappedQty: scrappedQty ?? this.scrappedQty,
      mLocatorId: mLocatorId ?? this.mLocatorId,
      mLocatorToId: mLocatorToId ?? this.mLocatorToId,
      mProductId: mProductId ?? this.mProductId,
      upc: upc ?? this.upc,
      sku: sku ?? this.sku,
      productName: productName ?? this.productName,
      verifiedStatus: verifiedStatus ?? this.verifiedStatus,
      scanningQty: scanningQty ?? this.scanningQty,
      manualQty: manualQty ?? this.manualQty,
      confirmId: confirmId ?? this.confirmId,
      editLocator: editLocator ?? this.editLocator,
      mAttributeSetInstanceID: mAttributeSetInstanceID ?? this.mAttributeSetInstanceID,
      cOrderLineId: cOrderLineId ?? this.cOrderLineId,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "Line": line,
        "MovementQty": movementQty,
        "TargetQty": targetQty,
        "ConfirmedQty": confirmedQty,
        "ScrappedQty": scrappedQty,
        "M_Locator_ID": mLocatorId?.toJson(),
        "M_LocatorTo_ID": mLocatorToId?.toJson(),
        "M_Product_ID": mProductId?.toJson(),
        "UPC": upc,
        "SKU": sku,
        "ProductName": productName,

        "ScanningQty": scanningQty,
        "ManualQty": manualQty,
        "VerifiedStatus":verifiedStatus,
        "ConfirmId": confirmId,
        "EditLocator": editLocator,
        "M_AttributeSetInstance_ID": mAttributeSetInstanceID?.toJson(),
        "C_OrderLine_ID": cOrderLineId?.toJson(),
  };

}
