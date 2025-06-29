import 'idempiere_tenant.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_notification_type.dart';
import 'idempiere_organization.dart';
import 'idempiere_user.dart';

class IdempiereUserWithDetail extends IdempiereUser  {
  String? uid;
  String? description;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? eMail;
  IdempiereUser? supervisorID;
  String? eMailUser;
  IdempiereNotificationType? notificationType;
  bool? isFullBPAccess;
  String? value;
  bool? isInPayroll;
  bool? isSalesLead;
  bool? isLocked;
  int? failedLoginCount;
  String? datePasswordChanged;
  String? dateLastLogin;
  bool? isNoPasswordReset;
  bool? isExpired;
  bool? isAddMailTextAutomatically;
  bool? isNoExpire;
  bool? isSupportUser;
  bool? isShipTo;
  bool? isBillTo;
  bool? isVendorLead;
  int? percentage;

  IdempiereUserWithDetail(
      {
        this.uid,
        this.description,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.eMail,
        this.supervisorID,
        this.eMailUser,
        this.notificationType,
        this.isFullBPAccess,
        this.value,
        this.isInPayroll,
        this.isSalesLead,
        this.isLocked,
        this.failedLoginCount,
        this.datePasswordChanged,
        this.dateLastLogin,
        this.isNoPasswordReset,
        this.isExpired,
        this.isAddMailTextAutomatically,
        this.isNoExpire,
        this.isSupportUser,
        this.isShipTo,
        this.isBillTo,
        this.isVendorLead,
        this.percentage,
        super.id,
        super.name,
        super.modelName,
        super.propertyLabel,
        super.identifier,
      });

  IdempiereUserWithDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    name = json['Name'];
    description = json['Description'];
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
    eMail = json['EMail'];
    supervisorID = json['Supervisor_ID'] != null
        ? IdempiereUser.fromJson(json['Supervisor_ID'])
        : null;
    eMailUser = json['EMailUser'];
    notificationType = json['NotificationType'] != null
        ? IdempiereNotificationType.fromJson(json['NotificationType'])
        : null;
    isFullBPAccess = json['IsFullBPAccess'];
    value = json['Value'];
    isInPayroll = json['IsInPayroll'];
    isSalesLead = json['IsSalesLead'];
    isLocked = json['IsLocked'];
    failedLoginCount = json['FailedLoginCount'];
    datePasswordChanged = json['DatePasswordChanged'];
    dateLastLogin = json['DateLastLogin'];
    isNoPasswordReset = json['IsNoPasswordReset'];
    isExpired = json['IsExpired'];
    isAddMailTextAutomatically = json['IsAddMailTextAutomatically'];
    isNoExpire = json['IsNoExpire'];
    isSupportUser = json['IsSupportUser'];
    isShipTo = json['IsShipTo'];
    isBillTo = json['IsBillTo'];
    isVendorLead = json['IsVendorLead'];
    percentage = json['Percentage'];
    modelName = json['model-name'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['Name'] = name;
    data['Description'] = description;
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
    data['EMail'] = eMail;
    if (supervisorID != null) {
      data['Supervisor_ID'] = supervisorID!.toJson();
    }
    data['EMailUser'] = eMailUser;
    if (notificationType != null) {
      data['NotificationType'] = notificationType!.toJson();
    }
    data['IsFullBPAccess'] = isFullBPAccess;
    data['Value'] = value;
    data['IsInPayroll'] = isInPayroll;
    data['IsSalesLead'] = isSalesLead;
    data['IsLocked'] = isLocked;
    data['FailedLoginCount'] = failedLoginCount;
    data['DatePasswordChanged'] = datePasswordChanged;
    data['DateLastLogin'] = dateLastLogin;
    data['IsNoPasswordReset'] = isNoPasswordReset;
    data['IsExpired'] = isExpired;
    data['IsAddMailTextAutomatically'] = isAddMailTextAutomatically;
    data['IsNoExpire'] = isNoExpire;
    data['IsSupportUser'] = isSupportUser;
    data['IsShipTo'] = isShipTo;
    data['IsBillTo'] = isBillTo;
    data['IsVendorLead'] = isVendorLead;
    data['Percentage'] = percentage;
    data['model-name'] = modelName;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;


    return data;
  }
  static List<IdempiereUserWithDetail> fromJsonList(List<dynamic> list){
    List<IdempiereUserWithDetail> newList =[];
    for (var item in list) {
      if(item is IdempiereUserWithDetail){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereUserWithDetail idempiereUserWithDetail = IdempiereUserWithDetail.fromJson(item);
        newList.add(idempiereUserWithDetail);
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
    if(eMailUser != null){
      list.add('${Messages.EMAIL}: ${eMailUser ?? '--'}');
    }
    return list;
  }
}




