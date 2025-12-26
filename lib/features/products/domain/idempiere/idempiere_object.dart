import '../../../shared/data/memory.dart';
import '../sql/common_sql_data.dart';
import 'object_with_name_and_id.dart';

class IdempiereObject implements CommonSqlData {
  int? id;
  String? name;
  bool? active;
  String? propertyLabel;
  String? identifier;
  String? modelName;
  String? image;
  ObjectWithNameAndId? category;
  final String appEndpointModel = Memory.APP_ENDPOINT_MODELS;
  IdempiereObject({
    this.id,
    this.name,
    this.active,
    this.identifier,
    this.modelName,
    this.propertyLabel,
    this.category,
    this.image
  });

  IdempiereObject.fromJson(Map<String, dynamic> json) {
    propertyLabel = json['propertyLabel'];
    id = json['id'];
    identifier = json['identifier'];
    modelName = json['model-name'];
    image = json['image'];
    name = json['name'];
    active = json['active'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null; 
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['propertyLabel'] = propertyLabel;
    data['id'] = id;
    data['identifier'] = identifier;
    data['model-name'] = modelName;
    data['image'] = image;
    data['category'] = category?.toJson();
    data['name'] = name;
    data['active'] = active;
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
  static List<IdempiereObject> fromJsonList(List<dynamic> list){
    List<IdempiereObject> newList =[];
    for (var item in list) {
      if(item is IdempiereObject){
        newList.add(item);
      } else {
        IdempiereObject object = IdempiereObject.fromJson(item);
        newList.add(object);
      }

    }
    return newList;
  }
  //To display in the list
  List<String> getOtherDataToDisplay() {
    List<String> list = [];
    if(id != null){
      list.add(id!.toString());
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
  @override
  String getInsertUrl(){
    String url = '$appEndpointModel/$modelName';
    return url;
  }
  @override
  String getDeleteUrl() {
    return getUpdateUrl();
  }

  @override
  String getSelectUrl() {
    return getUpdateUrl();
  }
  @override
  String getUpdateUrl(){
    String url = '$appEndpointModel/$modelName/$id';
    return url;
  }

  @override
  Map<String, dynamic> getDeleteJson() {
    return {"msg": "Deleted"};
  }

  @override
  Map<String, dynamic> getUpdateDocStatusJson(String status) {
    return {"doc-action": status};
  }

  bool? getBoolFromJson(var data){
    if(data==null) return null;
    if(data is bool) return data;
    if(data is String) {
      if(data.toLowerCase()=='true') return true;
      if(data.toLowerCase()=='false') return false;
    }

    return null;
  }
}