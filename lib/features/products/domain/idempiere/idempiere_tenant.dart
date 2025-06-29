
import 'idempiere_object.dart';

class IdempiereTenant extends IdempiereObject{
  IdempiereTenant({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  });
  factory IdempiereTenant.fromJson(Map<String, dynamic> json) => IdempiereTenant(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
    category: json["category"],
  );
  static List<IdempiereTenant> fromJsonList(List<dynamic> list){
    List<IdempiereTenant> result =[];
    for (var item in list) {
      if(item is IdempiereTenant){
        result.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereTenant idempiereTenant = IdempiereTenant.fromJson(item);
        result.add(idempiereTenant);
      }

    }
    return result;
  }
  @override
  Map<String, dynamic> toJson() => {
    "active": active,
    "id": id,
    "name": name,
    "propertyLabel": propertyLabel,
    "identifier": identifier,
    "modelName": modelName,
    "image": image,
    "category": category,
  };

}