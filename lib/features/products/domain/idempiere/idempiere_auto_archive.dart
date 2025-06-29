
import '../../../shared/data/messages.dart';
import 'idempiere_object_id_string.dart';

class IdempiereAutoArchive extends IdempiereObjectIdString {

  IdempiereAutoArchive({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
    super.image,
    super.category,
  });

  IdempiereAutoArchive.fromJson(Map<String, dynamic> json) {
    propertyLabel = json['propertyLabel'];
    id = json['id'];
    identifier = json['identifier'];
    modelName = json['model-name'];
    name = json['name'];
    active = json['active'];
    image = json['image'];
    category = json['category'];
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
    data['category'] = category;
    return data;
  }
  static List<IdempiereAutoArchive> fromJsonList(dynamic json) {
    if (json is Map<String, dynamic>) {
      return [IdempiereAutoArchive.fromJson(json)];
    } else if (json is List) {
      return json.map((item) => IdempiereAutoArchive.fromJson(item)).toList();
    }

    List<IdempiereAutoArchive> newList =[];
    for (var item in json) {
      if(item is IdempiereAutoArchive){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereAutoArchive idempiereAutoArchive = IdempiereAutoArchive.fromJson(item);
        newList.add(idempiereAutoArchive);
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