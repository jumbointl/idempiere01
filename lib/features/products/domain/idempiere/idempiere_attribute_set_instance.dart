
import 'idempiere_object.dart';

class IdempiereAttributeSetInstance extends IdempiereObject{
  IdempiereAttributeSetInstance({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempiereAttributeSetInstance.fromJson(Map<String, dynamic> json) => IdempiereAttributeSetInstance(
    active: json["active"],
    id: json["id"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempiereAttributeSetInstance> fromJsonList(List<dynamic> list){
    List<IdempiereAttributeSetInstance> newList =[];
    for (var item in list) {
      if(item is IdempiereAttributeSetInstance){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereAttributeSetInstance idempiereAttributeSetInstance = IdempiereAttributeSetInstance.fromJson(item);
        newList.add(idempiereAttributeSetInstance);
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