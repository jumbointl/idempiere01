import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_movement.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_organization.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_user.dart';

import 'idempiere_document_status.dart';
import 'idempiere_object.dart';
import 'idempiere_tenant.dart';
import 'object_with_name_and_id.dart';

class IdempiereMovementConfirm  extends IdempiereObject {
  String? uid;
  String? created;
  IdempiereTenant? aDClientID;
  IdempiereDocumentStatus? docStatus;
  IdempiereMovement? mMovementID;
  bool? isActive;
  bool? processing;
  IdempiereUser? updatedBy;
  String? updated;
  int? approvalAmt;
  IdempiereUser? createdBy;
  bool? processed;
  bool? isApproved;
  IdempiereOrganization? aDOrgID;
  String? documentNo;

  IdempiereMovementConfirm(
      {
        this.uid,
        this.created,
        this.aDClientID,
        this.docStatus,
        this.mMovementID,
        this.isActive,
        this.processing,
        this.updatedBy,
        this.updated,
        this.approvalAmt,
        this.createdBy,
        this.processed,
        this.isApproved,
        this.aDOrgID,
        this.documentNo,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName='m_movementconfirm',
        super.image,
        super.category,
      });

  IdempiereMovementConfirm.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    created = json['Created'];
    aDClientID = json['AD_Client_ID'] != null
        ? IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    docStatus = json['DocStatus'] != null
        ? IdempiereDocumentStatus.fromJson(json['DocStatus'])
        : null;
    mMovementID = json['M_Movement_ID'] != null
        ? IdempiereMovement.fromJson(json['M_Movement_ID'])
        : null;
    isActive = json['IsActive'];
    processing = json['Processing'];
    updatedBy = json['UpdatedBy'] != null
        ? IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    updated = json['Updated'];
    approvalAmt = json['ApprovalAmt'];
    createdBy = json['CreatedBy'] != null
        ? IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    processed = json['Processed'];
    isApproved = json['IsApproved'];
    aDOrgID = json['AD_Org_ID'] != null
        ? IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    documentNo = json['DocumentNo'];
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;;
    name = json['name'];


  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['Created'] = created;
    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }
    if (docStatus != null) {
      data['DocStatus'] = docStatus!.toJson();
    }
    if (mMovementID != null) {
      data['M_Movement_ID'] = mMovementID!.toJson();
    }
    data['IsActive'] = isActive;
    data['Processing'] = processing;
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    data['Updated'] = updated;
    data['ApprovalAmt'] = approvalAmt;
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    data['Processed'] = processed;
    data['IsApproved'] = isApproved;
    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }
    data['DocumentNo'] = documentNo;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['name'] = name;

    return data;
  }

  static List<IdempiereMovementConfirm>? fromJsonList(List<dynamic> list) {
    List<IdempiereMovementConfirm> result =[];
    for (var item in list) {
      if(item is IdempiereMovementConfirm){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereMovementConfirm idempiereMovementConfirm = IdempiereMovementConfirm.fromJson(item);
        result.add(idempiereMovementConfirm);
      }

    }
    return result;
  }
}

