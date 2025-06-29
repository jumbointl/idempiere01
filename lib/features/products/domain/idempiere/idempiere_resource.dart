
import 'idempiere_object.dart';

class IdempiereResource extends IdempiereObject{
  IdempiereResource({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempiereResource.fromJson(Map<String, dynamic> json) => IdempiereResource(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempiereResource> fromJsonList(List<dynamic> list){
    List<IdempiereResource> newList =[];
    for (var item in list) {
      if(item is IdempiereResource){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereResource idempiereResource = IdempiereResource.fromJson(item);
        newList.add(idempiereResource);
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