
import 'idempiere_object.dart';

class IdempierePurchasePriceList extends IdempiereObject{
  IdempierePurchasePriceList({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempierePurchasePriceList.fromJson(Map<String, dynamic> json) => IdempierePurchasePriceList(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempierePurchasePriceList> fromJsonList(List<dynamic> list){
    List<IdempierePurchasePriceList> newList =[];
    for (var item in list) {
      if(item is IdempierePurchasePriceList){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePurchasePriceList idempierePurchasePriceList = IdempierePurchasePriceList.fromJson(item);
        newList.add(idempierePurchasePriceList);
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