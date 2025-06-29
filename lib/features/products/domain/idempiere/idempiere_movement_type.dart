
import 'idempiere_object_id_string.dart';


class IdempiereMovementType extends IdempiereObjectIdString{
  IdempiereMovementType({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  });
  factory IdempiereMovementType.fromJson(Map<String, dynamic> json) => IdempiereMovementType(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
    category: json["category"],
  );
  static List<IdempiereMovementType> fromJsonList(List<dynamic> list){
    List<IdempiereMovementType> newList =[];
    for (var item in list) {
      if(item is IdempiereMovementType){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereMovementType idempiereMovementType = IdempiereMovementType.fromJson(item);
        newList.add(idempiereMovementType);
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