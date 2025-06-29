import 'idempiere_object_id_string.dart';


class IdempiereCreditStatus  extends IdempiereObjectIdString{

  IdempiereCreditStatus({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempiereCreditStatus.fromJson(Map<String, dynamic> json) => IdempiereCreditStatus(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempiereCreditStatus> fromJsonList(List<dynamic> list){
    List<IdempiereCreditStatus> newList =[];
    for (var item in list) {
      if(item is IdempiereCreditStatus){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereCreditStatus idempiereCreditStatus = IdempiereCreditStatus.fromJson(item);
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