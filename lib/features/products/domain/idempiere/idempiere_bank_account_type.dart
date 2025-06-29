
import 'idempiere_object.dart';

class IdempiereBankAccountType extends IdempiereObject{
  IdempiereBankAccountType({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  });
  factory IdempiereBankAccountType.fromJson(Map<String, dynamic> json) => IdempiereBankAccountType(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
    category: json["category"],
  );
  static List<IdempiereBankAccountType> fromJsonList(List<dynamic> list){
    List<IdempiereBankAccountType> newList =[];
    for (var item in list) {
      if(item is IdempiereBankAccountType){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereBankAccountType idempiereBankAccountType = IdempiereBankAccountType.fromJson(item);
        newList.add(idempiereBankAccountType);
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