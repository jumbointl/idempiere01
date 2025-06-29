
import 'idempiere_object_id_string.dart';
class IdempiereSOPOType  extends IdempiereObjectIdString{
  IdempiereSOPOType({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
  });
  factory IdempiereSOPOType.fromJson(Map<String, dynamic> json) => IdempiereSOPOType(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
  );
  static List<IdempiereSOPOType> fromJsonList(List<dynamic> list){
    List<IdempiereSOPOType> newList =[];
    for (var item in list) {
      if(item is IdempiereSOPOType){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereSOPOType idempiereSOPOType = IdempiereSOPOType.fromJson(item);
        newList.add(idempiereSOPOType);
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
  };

}