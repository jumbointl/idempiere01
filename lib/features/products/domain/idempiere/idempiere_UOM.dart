
import 'idempiere_organization.dart';
import 'idempiere_tenant.dart';
import 'idempiere_user.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'object_with_name_and_id.dart';

class IdempiereUOM extends IdempiereObject {
  String? uid;
  int? stdPrecision;
  int? costingPrecision;
  IdempiereTenant? aDClientID;
  IdempiereOrganization? aDOrgID;
  bool? isActive;
  String? created;
  IdempiereUser? createdBy;
  String? updated;
  IdempiereUser? updatedBy;
  String? uOMSymbol;
  String? x12DE355;
  bool? isDefault;

  IdempiereUOM(
      {
        this.uid,
        this.stdPrecision,
        this.costingPrecision,
        this.aDClientID,
        this.aDOrgID,
        this.isActive,
        this.created,
        this.createdBy,
        this.updated,
        this.updatedBy,
        this.uOMSymbol,
        this.x12DE355,
        this.isDefault,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
      });

  IdempiereUOM.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    name = json['Name'];
    stdPrecision = json['StdPrecision'];
    costingPrecision = json['CostingPrecision'];
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
    uOMSymbol = json['UOMSymbol'];
    x12DE355 = json['X12DE355'];
    isDefault = json['IsDefault'];
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    data['Name'] = name;
    data['StdPrecision'] = stdPrecision;
    data['CostingPrecision'] = costingPrecision;
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
    data['UOMSymbol'] = uOMSymbol;
    data['X12DE355'] = x12DE355;
    data['IsDefault'] = isDefault;
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category?.toJson();
    return data;
  }
  static List<IdempiereUOM> fromJsonList(List<dynamic> list){
    List<IdempiereUOM> result =[];
    for (var item in list) {
      if(item is IdempiereUOM){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereUOM idempiereUOM = IdempiereUOM.fromJson(item);
        result.add(idempiereUOM);
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
    if( name != null){
      list.add('${Messages.NAME}: ${name ?? '--'}');
    }

    if( uOMSymbol != null){
      list.add('UOMSymbol: ${uOMSymbol ?? '--'}');
    }
    if( x12DE355 != null){
      list.add('X12DE355: ${x12DE355 ?? '--'}');
    }


    return list;
  }
}







