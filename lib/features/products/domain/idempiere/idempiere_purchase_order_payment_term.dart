
import 'idempiere_object.dart';

class IdempierePurchaseOrderPaymentTerm extends IdempiereObject{
  IdempierePurchaseOrderPaymentTerm({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempierePurchaseOrderPaymentTerm.fromJson(Map<String, dynamic> json) => IdempierePurchaseOrderPaymentTerm(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempierePurchaseOrderPaymentTerm> fromJsonList(List<dynamic> list){
    List<IdempierePurchaseOrderPaymentTerm> newList =[];
    for (var item in list) {
      if(item is IdempierePurchaseOrderPaymentTerm){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePurchaseOrderPaymentTerm idempierePurchaseOrderPaymentType = IdempierePurchaseOrderPaymentTerm.fromJson(item);
        newList.add(idempierePurchaseOrderPaymentType);
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