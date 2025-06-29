
import 'idempiere_object.dart';

class IdempiereDunning extends IdempiereObject{
  IdempiereDunning({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempiereDunning.fromJson(Map<String, dynamic> json) => IdempiereDunning(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempiereDunning> fromJsonList(List<dynamic> list){
    List<IdempiereDunning> newList =[];
    for (var item in list) {
      if(item is IdempiereDunning){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereDunning idempiereDunning = IdempiereDunning.fromJson(item);
        newList.add(idempiereDunning);
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