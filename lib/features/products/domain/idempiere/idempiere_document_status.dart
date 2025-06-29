
import 'idempiere_object_id_string.dart';


class IdempiereDocumentStatus extends IdempiereObjectIdString{
  IdempiereDocumentStatus({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  });
  factory IdempiereDocumentStatus.fromJson(Map<String, dynamic> json) => IdempiereDocumentStatus(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
    category: json["category"],
  );
  static List<IdempiereDocumentStatus> fromJsonList(List<dynamic> list){
    List<IdempiereDocumentStatus> newList =[];
    for (var item in list) {
      if(item is IdempiereDocumentStatus){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereDocumentStatus idempiereDocumentStatus = IdempiereDocumentStatus.fromJson(item);
        newList.add(idempiereDocumentStatus);
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