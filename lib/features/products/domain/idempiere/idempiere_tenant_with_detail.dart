import 'idempiere_autentication_type.dart';
import 'idempiere_auto_archive.dart';
import 'idempiere_language.dart';
import 'idempiere_material_policy.dart';
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'object_with_name_and_id.dart';

class IdempiereTenantWithDetail extends IdempiereTenant {
  String? uid;
  String? description;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? value;
  IdempiereLanguage? aDLanguage;
  String? requestEMail;
  String? requestFolder;
  String? requestUser;
  bool? isMultiLingualDocument;
  bool? isSmtpAuthorization;
  bool? isUseBetaFunctions;
  IdempiereAutoArchive? autoArchive;
  IdempiereMaterialPolicy? mMPolicy;
  bool? isPostImmediate;
  bool? isUseASP;
  bool? isSecureSMTP;
  IdempiereAuthenticationType? authenticationType;

  IdempiereTenantWithDetail(
      {
        this.uid,
        this.description,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.value,
        this.aDLanguage,
        this.requestEMail,
        this.requestFolder,
        this.requestUser,
        this.isMultiLingualDocument,
        this.isSmtpAuthorization,
        this.isUseBetaFunctions,
        this.autoArchive,
        this.mMPolicy,
        this.isPostImmediate,
        this.isUseASP,
        this.isSecureSMTP,
        this.authenticationType,
        super.id,
        super.name,
        super.modelName,
        super.active,
        super.category,
        super.identifier,
        super.propertyLabel,
        super.image,
        

      });

  IdempiereTenantWithDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    name = json['Name'];
    description = json['Description'];
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
    value = json['Value'];
    aDLanguage = json['AD_Language'] != null
        ?  IdempiereLanguage.fromJson(json['AD_Language'])
        : null;
    requestEMail = json['RequestEMail'];
    requestFolder = json['RequestFolder'];
    requestUser = json['RequestUser'];
    isMultiLingualDocument = json['IsMultiLingualDocument'];
    isSmtpAuthorization = json['IsSmtpAuthorization'];
    isUseBetaFunctions = json['IsUseBetaFunctions'];
    autoArchive = json['AutoArchive'] != null
        ?  IdempiereAutoArchive.fromJson(json['AutoArchive'])
        : null;
    mMPolicy = json['MMPolicy'] != null
        ?  IdempiereMaterialPolicy.fromJson(json['MMPolicy'])
        : null;
    isPostImmediate = json['IsPostImmediate'];
    isUseASP = json['IsUseASP'];
    isSecureSMTP = json['IsSecureSMTP'];
    authenticationType = json['AuthenticationType'] != null
        ?  IdempiereAuthenticationType.fromJson(json['AuthenticationType'])
        : null;
    modelName = json['model-name'];
    active = json['active'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;;
    identifier = json['identifier'];
    propertyLabel = json['propertyLabel'];
    image = json['image'];
    
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['Name'] = name;
    data['Description'] = description;
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
    data['Value'] = value;
    if (aDLanguage != null) {
      data['AD_Language'] = aDLanguage!.toJson();
    }
    data['RequestEMail'] = requestEMail;
    data['RequestFolder'] = requestFolder;
    data['RequestUser'] = requestUser;
    data['IsMultiLingualDocument'] = isMultiLingualDocument;
    data['IsSmtpAuthorization'] = isSmtpAuthorization;
    data['IsUseBetaFunctions'] = isUseBetaFunctions;
    if (autoArchive != null) {
      data['AutoArchive'] = autoArchive!.toJson();
    }
    if (mMPolicy != null) {
      data['MMPolicy'] = mMPolicy!.toJson();
    }
    data['IsPostImmediate'] = isPostImmediate;
    data['IsUseASP'] = isUseASP;
    data['IsSecureSMTP'] = isSecureSMTP;
    if (authenticationType != null) {
      data['AuthenticationType'] = authenticationType!.toJson();
    }
    data['model-name'] = modelName;
    data['active'] = active;
    data['category'] = category?.toJson();
    data['identifier'] = identifier;
    data['propertyLabel'] = propertyLabel;
    data['image'] = image;
    return data;
  }
  static List<IdempiereTenantWithDetail> fromJsonList(List<dynamic> list){
    List<IdempiereTenantWithDetail> newList =[];
    for (var item in list) {
      if(item is IdempiereTenantWithDetail){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereTenantWithDetail idempiereTenantWithDetail = IdempiereTenantWithDetail.fromJson(item);
        newList.add(idempiereTenantWithDetail);
      }

    }
    return newList;
  }
  @override
  List<String> getOtherDataToDisplay() {
    List<String> list = [];
    if(id != null){
      list.add('${Messages.ID}: ${id ?? '--'}');
    }
    if(name != null){
      list.add('${Messages.NAME}: ${name ?? '--'}');
    }
    if(description != null){
      list.add('${Messages.DESCRIPTION}: ${description ?? '--'}');
    }
    return list;
  }
}




