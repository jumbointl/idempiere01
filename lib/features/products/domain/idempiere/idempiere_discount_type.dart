
import '../../../shared/data/messages.dart';
import 'idempiere_object.dart';

class IdempiereDiscountType extends IdempiereObject{
  IdempiereDiscountType({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  });
  factory IdempiereDiscountType.fromJson(Map<String, dynamic> json) => IdempiereDiscountType(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    image: json["image"],
    category: json["category"],
  );
  static List<IdempiereDiscountType> fromJsonList(List<dynamic> list){
    List<IdempiereDiscountType> newList =[];
    for (var item in list) {
      if(item is IdempiereDiscountType){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereDiscountType idempiereDiscountType = IdempiereDiscountType.fromJson(item);
        newList.add(idempiereDiscountType);
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

  @override
  List<String> getOtherDataToDisplay() {
    List<String> list = [];
    if(id != null){
      list.add('${Messages.ID}: ${id ?? '--'}');
    }
    if(identifier != null){
      list.add('${Messages.NAME}: ${identifier ?? '--'}');
    }
    if(identifier != null){
      list.add(propertyLabel!);
    }
    return list;
  }
}