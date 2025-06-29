
import 'idempiere_object.dart';

class IdempiereCreditStatus2 extends IdempiereObject{
  IdempiereCreditStatus2({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempiereCreditStatus2.fromJson(Map<String, dynamic> json) => IdempiereCreditStatus2(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempiereCreditStatus2> fromJsonList(List<dynamic> list){
    List<IdempiereCreditStatus2> newList =[];
    for (var item in list) {
      if(item is IdempiereCreditStatus2){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereCreditStatus2 idempiereCreditStatus = IdempiereCreditStatus2.fromJson(item);
        newList.add(idempiereCreditStatus);
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