import 'idempiere_object_id_string.dart';

class IdempiereMaterialPolicy extends IdempiereObjectIdString {

  IdempiereMaterialPolicy({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName,
  });

  IdempiereMaterialPolicy.fromJson(Map<String, dynamic> json) {
    propertyLabel = json['propertyLabel'];
    id = json['id'];
    identifier = json['identifier'];
    modelName = json['model-name'];
    name = json['name'];
    active = json['active'];
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
    return data;
  }
}