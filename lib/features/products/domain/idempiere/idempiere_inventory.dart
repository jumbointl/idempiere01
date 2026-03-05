import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_currency.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_conversion_type.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_status.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_type.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_organization.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_tenant.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_user.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'object_with_name_and_id.dart';

class IdempiereInventory extends IdempiereObject {
  String? uid;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? documentNo;
  String? description;
  String? movementDate;
  bool? processed;
  bool? processing;
  IdempiereWarehouse? mWarehouseID;
  int? approvalAmt;
  IdempiereDocumentStatus? docStatus;
  bool? isApproved;
  IdempiereDocumentType? cDocTypeID;
  double? processedOn;
  IdempiereDocumentStatus? costingMethod;
  IdempiereCurrency? cCurrencyID;
  IdempiereConversionType? cConversionTypeID;

  IdempiereInventory({
    this.uid,
    this.aDClientID,
    this.aDOrgID,
    this.isActive,
    this.created,
    this.createdBy,
    this.updated,
    this.updatedBy,
    this.documentNo,
    this.description,
    this.movementDate,
    this.processed,
    this.processing,
    this.mWarehouseID,
    this.approvalAmt,
    this.docStatus,
    this.isApproved,
    this.cDocTypeID,
    this.processedOn,
    this.costingMethod,
    this.cCurrencyID,
    this.cConversionTypeID,
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName = 'm_inventory',
    super.image,
    super.category,
  });

  IdempiereInventory.fromJson(Map<String, dynamic> json) {
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
    documentNo = json['DocumentNo'];
    description = json['Description'];
    movementDate = json['MovementDate'];
    processed = getBoolFromJson(json['Processed']);
    processing = getBoolFromJson(json['Processing']);
    mWarehouseID = json['M_Warehouse_ID'] != null
        ? IdempiereWarehouse.fromJson(json['M_Warehouse_ID'])
        : null;
    approvalAmt = json['ApprovalAmt'];
    docStatus = json['DocStatus'] != null
        ? IdempiereDocumentStatus.fromJson(json['DocStatus'])
        : null;
    isApproved = getBoolFromJson(json['IsApproved']);
    cDocTypeID = json['C_DocType_ID'] != null
        ? IdempiereDocumentType.fromJson(json['C_DocType_ID'])
        : null;
    processedOn = json['ProcessedOn'] != null
        ? double.tryParse(json['ProcessedOn'].toString())
        : null;
    costingMethod = json['CostingMethod'] != null
        ? IdempiereDocumentStatus.fromJson(json['CostingMethod'])
        : null;
    cCurrencyID = json['C_Currency_ID'] != null
        ? IdempiereCurrency.fromJson(json['C_Currency_ID'])
        : null;
    cConversionTypeID = json['C_ConversionType_ID'] != null
        ? IdempiereConversionType.fromJson(json['C_ConversionType_ID'])
        : null;

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

  bool get canComplete {
    if (docStatus == null) return false;
    return docStatus?.id == 'DR';
  }

  bool get isCompleted {
    if (docStatus == null) return false;
    return docStatus?.id == 'CO';
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
    data['Description'] = description;
    data['MovementDate'] = movementDate;
    data['Processed'] = processed;
    data['Processing'] = processing;
    if (mWarehouseID != null) {
      data['M_Warehouse_ID'] = mWarehouseID!.toJson();
    }
    data['ApprovalAmt'] = approvalAmt;
    if (docStatus != null) {
      data['DocStatus'] = docStatus!.toJson();
    }
    data['IsApproved'] = isApproved;
    if (cDocTypeID != null) {
      data['C_DocType_ID'] = cDocTypeID!.toJson();
    }
    data['ProcessedOn'] = processedOn;
    if (costingMethod != null) {
      data['CostingMethod'] = costingMethod!.toJson();
    }
    if (cCurrencyID != null) {
      data['C_Currency_ID'] = cCurrencyID!.toJson();
    }
    if (cConversionTypeID != null) {
      data['C_ConversionType_ID'] = cConversionTypeID!.toJson();
    }

    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['name'] = name;

    return data;
  }

  static List<IdempiereInventory> fromJsonList(List<dynamic> list) {
    final List<IdempiereInventory> result = [];
    for (final item in list) {
      if (item is IdempiereInventory) {
        result.add(item);
      } else if (item is Map<String, dynamic>) {
        result.add(IdempiereInventory.fromJson(item));
      }
    }
    return result;
  }

  static List<IdempiereInventory>? fromJsonString(String jsonString) {
    if (jsonString.isEmpty) return null;

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      return null;
    } else {
      if (decoded.isEmpty) return null;
      if (decoded[0] is! Map<String, dynamic>) return null;
      if (decoded[0]['id'] == null) return null;
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map((e) => IdempiereInventory.fromJson(e))
        .toList();
  }

  @override
  List<String> getOtherDataToDisplay() {
    final List<String> list = [];

    if (id != null) {
      list.add('${Messages.ID}: ${id ?? '--'}');
    }
    if (documentNo != null) {
      list.add('Document No: ${documentNo ?? '--'}');
    }
    if (description != null) {
      list.add('${Messages.DESCRIPTION}: ${description ?? '--'}');
    }
    if (movementDate != null) {
      list.add('${Messages.DATE}: ${movementDate ?? '--'}');
    }
    if (docStatus?.identifier != null) {
      list.add('Status: ${docStatus?.identifier ?? '--'}');
    }
    if (cDocTypeID?.identifier != null) {
      list.add('Doc Type: ${cDocTypeID?.identifier ?? '--'}');
    }

    return list;
  }

  Color? get colorInventoryStatus {
    if (docStatus?.id == 'DR') return Colors.orange[100];
    if (docStatus?.id == 'CO') return Colors.green[100];
    return Colors.grey[100];
  }

  Color? get colorInventoryStatusDark {
    if (docStatus?.id == 'DR') return Colors.orange[800];
    if (docStatus?.id == 'CO') return Colors.green[800];
    return Colors.grey[800];
  }
}