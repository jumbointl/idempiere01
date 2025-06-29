
import 'idempiere_object.dart';

class IdempiereAssetGroup  extends IdempiereObject{

  IdempiereAssetGroup({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });
  factory IdempiereAssetGroup.fromJson(Map<String, dynamic> json) => IdempiereAssetGroup(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );
  static List<IdempiereAssetGroup> fromJsonList(List<dynamic> list){
    List<IdempiereAssetGroup> newList =[];
    for (var item in list) {
      if(item is IdempiereAssetGroup){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereAssetGroup idempiereAssetGroup = IdempiereAssetGroup.fromJson(item);
        newList.add(idempiereAssetGroup);
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