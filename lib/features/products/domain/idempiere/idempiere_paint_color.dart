
import 'idempiere_object.dart';

class IdempierePaintColor  extends IdempiereObject{

  IdempierePaintColor({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempierePaintColor.fromJson(Map<String, dynamic> json) => IdempierePaintColor(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempierePaintColor> fromJsonList(List<dynamic> list){
    List<IdempierePaintColor> newList =[];
    for (var item in list) {
      if(item is IdempierePaintColor){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePaintColor idempierePaintColor = IdempierePaintColor.fromJson(item);
        newList.add(idempierePaintColor);
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