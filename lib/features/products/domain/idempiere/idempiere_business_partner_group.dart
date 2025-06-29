
import 'idempiere_object.dart';

class IdempiereBusinessPartnerGroup extends IdempiereObject{
  IdempiereBusinessPartnerGroup({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempiereBusinessPartnerGroup.fromJson(Map<String, dynamic> json) => IdempiereBusinessPartnerGroup(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempiereBusinessPartnerGroup> fromJsonList(List<dynamic> list){
    List<IdempiereBusinessPartnerGroup> newList =[];
    for (var item in list) {
      if(item is IdempiereBusinessPartnerGroup){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereBusinessPartnerGroup idempiereBusinessPartnerGroup = IdempiereBusinessPartnerGroup.fromJson(item);
        newList.add(idempiereBusinessPartnerGroup);
      }

    }
    return newList;
  }
  @override
  Map<String, dynamic> toJson() => {
    "active": active,
    "id": id,
    "name": name,
    "propertyLabel": propertyLabel,
    "identifier": identifier,
    "modelName": modelName,
  };

}