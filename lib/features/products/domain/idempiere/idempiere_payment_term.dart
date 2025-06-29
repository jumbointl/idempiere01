
import 'idempiere_object.dart';

class IdempierePaymentTerm extends IdempiereObject{
  IdempierePaymentTerm({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempierePaymentTerm.fromJson(Map<String, dynamic> json) => IdempierePaymentTerm(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempierePaymentTerm> fromJsonList(List<dynamic> list){
    List<IdempierePaymentTerm> newList =[];
    for (var item in list) {
      if(item is IdempierePaymentTerm){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePaymentTerm idempierePaymentTerm = IdempierePaymentTerm.fromJson(item);
        newList.add(idempierePaymentTerm);
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