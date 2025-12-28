

import '../../../shared/data/messages.dart';
import 'idempiere_object_id_string.dart';
import 'object_with_name_and_id.dart';

class IdempiereAuthenticationType extends IdempiereObjectIdString {

  IdempiereAuthenticationType({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  });

  IdempiereAuthenticationType.fromJson(Map<String, dynamic> json) {
    propertyLabel = json['propertyLabel'];
    id = json['id'];
    identifier = json['identifier'];
    modelName = json['model-name'];
    name = json['name'];
    active = json['active'];
    image = json['image'];
    category = json['category'] != null ? ObjectWithNameAndId.fromJson(json['category']) : null;
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['propertyLabel'] = propertyLabel;
    data['id'] = id;
    data['identifier'] = identifier;
    data['model-name'] = modelName;
    data['name'] = name;
    data['active'] = active;
    data['image'] = image;
    data['category'] = category?.toJson();
    return data;
  }
  static List<IdempiereAuthenticationType> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereAuthenticationType.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereAuthenticationType.fromJson(item)).toList();
    }

    List<IdempiereAuthenticationType> newList =[];
    for (var item in json) {
      if(item is IdempiereAuthenticationType){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereAuthenticationType idempiereAutenticationType = IdempiereAuthenticationType.fromJson(item);
        newList.add(idempiereAutenticationType);
      }
    }

    return newList;
  }
  @override
  List<String> getOtherDataToDisplay() {
    List<String> list = [];
    if(id != null){
      list.add('${Messages.ID}: ${id ?? '--'}');
    }
    if(identifier != null){
      list.add('${Messages.NAME}: ${identifier?? '--'}');
    }
    if( propertyLabel != null){
      list.add(propertyLabel ?? '--');
    }
    return list;
  }
}