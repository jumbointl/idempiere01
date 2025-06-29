
import 'idempiere_object_id_string.dart';

class IdempierePaymentRule extends IdempiereObjectIdString{
  IdempierePaymentRule({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
  });
  factory IdempierePaymentRule.fromJson(Map<String, dynamic> json) => IdempierePaymentRule(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
  );
  static List<IdempierePaymentRule> fromJsonList(List<dynamic> list){
    List<IdempierePaymentRule> newList =[];
    for (var item in list) {
      if(item is IdempierePaymentRule){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempierePaymentRule idempierePaymentRule = IdempierePaymentRule.fromJson(item);
        newList.add(idempierePaymentRule);
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