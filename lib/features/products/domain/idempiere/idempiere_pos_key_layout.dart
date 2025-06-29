
import 'idempiere_organization.dart';
import 'idempiere_print_font.dart';
import 'idempiere_tenant.dart';

import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';
import 'idempiere_pos_key_layout_type.dart';
import 'idempiere_print_color.dart';
import 'idempiere_user.dart';


class IdempierePosKeyLayout extends IdempiereObject {
  String? uid;
  IdempiereUser? createdBy;
  bool? isActive;
  String? updated;
  IdempiereOrganization? aDOrgID;
  String? created;
  IdempiereTenant? aDClientID;
  IdempiereUser? updatedBy;
  int? columns;
  IdempierePosKeyLayoutType? pOSKeyLayoutType;
  IdempierePrintColor? aDPrintColorID;
  IdempierePrintFont? aDPrintFontID;

  IdempierePosKeyLayout(
      {
        this.uid,
        this.createdBy,
        this.isActive,
        this.updated,
        this.aDOrgID,
        this.created,
        this.aDClientID,
        this.updatedBy,
        this.columns,
        this.pOSKeyLayoutType,
        this.aDPrintColorID,
        this.aDPrintFontID,
        super.id,
        super.name,
        super.active,
        super.propertyLabel,
        super.identifier,
        super.modelName,
        super.image,
        super.category,
      });

  IdempierePosKeyLayout.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uid = json['uid'];
    createdBy = json['CreatedBy'] != null
        ?  IdempiereUser.fromJson(json['CreatedBy'])
        : null;
    isActive = json['IsActive'];
    updated = json['Updated'];
    name = json['Name'];
    aDOrgID = json['AD_Org_ID'] != null
        ?  IdempiereOrganization.fromJson(json['AD_Org_ID'])
        : null;
    created = json['Created'];
    aDClientID = json['AD_Client_ID'] != null
        ?  IdempiereTenant.fromJson(json['AD_Client_ID'])
        : null;
    updatedBy = json['UpdatedBy'] != null
        ?  IdempiereUser.fromJson(json['UpdatedBy'])
        : null;
    columns = json['Columns'];
    pOSKeyLayoutType = json['POSKeyLayoutType'] != null
        ?  IdempierePosKeyLayoutType.fromJson(json['POSKeyLayoutType'])
        : null;
    aDPrintColorID = json['AD_PrintColor_ID'] != null
        ?  IdempierePrintColor.fromJson(json['AD_PrintColor_ID'])
        : null;
    aDPrintFontID = json['AD_PrintFont_ID'] != null
        ?  IdempierePrintFont.fromJson(json['AD_PrintFont_ID'])
        : null;
    modelName = json['model-name'];
    active = json['active'];
    propertyLabel = json['propertyLabel'];
    identifier = json['identifier'];
    image = json['image'];
    category = json['category'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data =  <String, dynamic>{};
    data['id'] = id;
    data['uid'] = uid;
    if (createdBy != null) {
      data['CreatedBy'] = createdBy!.toJson();
    }
    data['IsActive'] = isActive;
    data['Updated'] = updated;
    data['Name'] = name;
    if (aDOrgID != null) {
      data['AD_Org_ID'] = aDOrgID!.toJson();
    }
    data['Created'] = created;
    if (aDClientID != null) {
      data['AD_Client_ID'] = aDClientID!.toJson();
    }
    if (updatedBy != null) {
      data['UpdatedBy'] = updatedBy!.toJson();
    }
    data['Columns'] = columns;
    if (pOSKeyLayoutType != null) {
      data['POSKeyLayoutType'] = pOSKeyLayoutType!.toJson();
    }
    if (aDPrintColorID != null) {
      data['AD_PrintColor_ID'] = aDPrintColorID!.toJson();
    }
    if (aDPrintFontID != null) {
      data['AD_PrintFont_ID'] = aDPrintFontID!.toJson();
    }
    data['model-name'] = modelName;
    data['active'] = active;
    data['propertyLabel'] = propertyLabel;
    data['identifier'] = identifier;
    data['image'] = image;
    data['category'] = category;
    return data;
  }
  static List<IdempierePosKeyLayout> fromJsonList(List<dynamic> list){
    List<IdempierePosKeyLayout> newList =[];
    for (var item in list) {
      if(item is IdempierePosKeyLayout){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePosKeyLayout idempierePosKeyLayout = IdempierePosKeyLayout.fromJson(item);
        newList.add(idempierePosKeyLayout);
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

    return list;
  }
}


