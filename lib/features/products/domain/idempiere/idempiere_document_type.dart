
import 'idempiere_object.dart';

class IdempiereDocumentType extends IdempiereObject{
  IdempiereDocumentType({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  });
  factory IdempiereDocumentType.fromJson(Map<String, dynamic> json) => IdempiereDocumentType(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
    category: json["category"],
  );
  static List<IdempiereDocumentType> fromJsonList(List<dynamic> list){
    List<IdempiereDocumentType> newList =[];
    for (var item in list) {
      if(item is IdempiereDocumentType){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereDocumentType idempiereDocumentType = IdempiereDocumentType.fromJson(item);
        newList.add(idempiereDocumentType);
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