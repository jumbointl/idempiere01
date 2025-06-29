
import 'idempiere_object_id_string.dart';


class IdempierePosKeyLayoutType extends IdempiereObjectIdString{
  IdempierePosKeyLayoutType({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  });
  factory IdempierePosKeyLayoutType.fromJson(Map<String, dynamic> json) => IdempierePosKeyLayoutType(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
    category: json["category"],
  );
  static List<IdempierePosKeyLayoutType> fromJsonList(List<dynamic> list){
    List<IdempierePosKeyLayoutType> newList =[];
    for (var item in list) {
      if(item is IdempierePosKeyLayoutType){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePosKeyLayoutType idempierePosKeyLayoutType = IdempierePosKeyLayoutType.fromJson(item);
        newList.add(idempierePosKeyLayoutType);
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
    "image": image,
    "category": category,
  };

}