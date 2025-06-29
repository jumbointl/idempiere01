import 'package:idempiere_rest/idempiere_rest.dart';

import 'object_with_name_and_id.dart';

class IdempiereRol extends ObjectWithNameAndId{
  IdempiereRol({
    super.id,
    super.name,
    super.active,
});
  factory IdempiereRol.fromJson(Map<String, dynamic> json) => IdempiereRol(
    active: json["active"],
    id: json["id"],
    name: json["name"],
  );
  static List<IdempiereRol> fromJsonList(List<dynamic> list){
    List<IdempiereRol> newList =[];
    for (var item in list) {
      if(item is IdempiereRol){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereRol idempiereRol = IdempiereRol.fromJson(item);
        newList.add(idempiereRol);
      } else if(item is Role){
        IdempiereRol idempiereRol = IdempiereRol(id: item.id, name: item.name);
        newList.add(idempiereRol);
      }

    }
    return newList;
  }
  @override
  Map<String, dynamic> toJson() => {
    "active": active,
    "id": id,
    "name": name,
  };

}