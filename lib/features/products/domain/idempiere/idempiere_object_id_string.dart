import 'object_with_name_and_id.dart';

class IdempiereObjectIdString{
  String? id;
  String?name;
  int? active ;
  String? propertyLabel;
  String? identifier;
  String? modelName;
  String? image;
  ObjectWithNameAndId? category;
  IdempiereObjectIdString({
    this.id,
    this.name,
    this.active,
    this.identifier,
    this.modelName,
    this.propertyLabel,
    this.category,
    this.image
  });

  IdempiereObjectIdString.fromJson(Map<String, dynamic> json) {
    propertyLabel = json['propertyLabel'];
    id = json['id'];
    identifier = json['identifier'];
    modelName = json['model-name'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['propertyLabel'] = propertyLabel;
    data['id'] = id;
    data['identifier'] = identifier;
    data['model-name'] = modelName;
    data['image'] = image;
    data['category'] = category;
    return data;
  }
  Map<String, dynamic> toJsonForIdempiereSqlUse() {
    final Map<String, dynamic> data = {};
    if(propertyLabel !=null) data['propertyLabel'] = propertyLabel;
    if(id !=null) data['id'] = id;
    if(identifier !=null) data['identifier'] = identifier;
    if(modelName !=null) data['model-name'] = modelName;
    return data;
  }
  static List<IdempiereObjectIdString> fromJsonList(List<dynamic> list){
    List<IdempiereObjectIdString> newList =[];
    for (var item in list) {
      if(item is IdempiereObjectIdString){
        newList.add(item);
      } else {
        IdempiereObjectIdString object = IdempiereObjectIdString.fromJson(item);
        newList.add(object);
      }

    }
    return newList;
  }
  //To display in the list
  List<String> getOtherDataToDisplay() {
    List<String> list = [];
    if(id != null){
      list.add(id!);
    }
    if(name != null){
      list.add(name!);
    }
    if(identifier != null){
      list.add(identifier!);
    }
    if(propertyLabel != null){
      list.add(propertyLabel!);
    }
    if(modelName != null){
      list.add(modelName!);
    }
    return list;
  }

  bool isDisplayImage() {
    if(image != null){
      return true;
    }
    return false;
  }
}