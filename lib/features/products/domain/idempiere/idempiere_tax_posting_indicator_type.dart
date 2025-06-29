
import 'idempiere_object_id_string.dart';
class IdempiereTaxPostingIndicator  extends IdempiereObjectIdString{
  IdempiereTaxPostingIndicator({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
  });
  factory IdempiereTaxPostingIndicator.fromJson(Map<String, dynamic> json) => IdempiereTaxPostingIndicator(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
  );
  static List<IdempiereTaxPostingIndicator> fromJsonList(List<dynamic> list){
    List<IdempiereTaxPostingIndicator> newList =[];
    for (var item in list) {
      if(item is IdempiereTaxPostingIndicator){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereTaxPostingIndicator idempiereTaxPostingIndicator = IdempiereTaxPostingIndicator.fromJson(item);
        newList.add(idempiereTaxPostingIndicator);
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