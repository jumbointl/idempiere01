import 'dart:convert';

ObjectWithNameAndId objectWithNameAndIdFromJson(String str) => ObjectWithNameAndId.fromJson(json.decode(str));

String objectWithNameAndIdToJson(ObjectWithNameAndId data) => json.encode(data.toJson());

class ObjectWithNameAndId {
  int? active ;
  int? id ;
  String? name;


  ObjectWithNameAndId({
    this.active,
    this.id,
    this.name,
  });

  factory ObjectWithNameAndId.fromJson(Map<String, dynamic> json) => ObjectWithNameAndId(
    active: json["active"],
    id: json["id"],
    name: json["name"],
  );
  static List<ObjectWithNameAndId> fromJsonList(List<dynamic> list){
    List<ObjectWithNameAndId> newList =[];
    for (var item in list) {
      if(item is ObjectWithNameAndId){
        newList.add(item);
      } else {
        ObjectWithNameAndId objectWithNameAndId = ObjectWithNameAndId.fromJson(item);
        newList.add(objectWithNameAndId);
      }

    }
    return newList;
  }
  Map<String, dynamic> toJson() => {
    "active": active,
    "id": id,
    "name": name,
  };
  bool isActive(){
    if(active!=null && active==1){
      return true;
    }

    return false;
  }
}