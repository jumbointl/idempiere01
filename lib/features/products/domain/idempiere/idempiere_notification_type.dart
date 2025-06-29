import 'idempiere_object_id_string.dart';

class IdempiereNotificationType extends IdempiereObjectIdString {


  IdempiereNotificationType(
      {
        super.propertyLabel,
        super.id,
        super.identifier,
        super.modelName});

  IdempiereNotificationType.fromJson(Map<String, dynamic> json) {
    propertyLabel = json['propertyLabel'];
    id = json['id'];
    identifier = json['identifier'];
    modelName = json['model-name'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['propertyLabel'] = propertyLabel;
    data['id'] = id;
    data['identifier'] = identifier;
    data['model-name'] = modelName;
    return data;
  }
}