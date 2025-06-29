

class IdempiereProductType{
  String? propertyLabel;
  String? id;
  String? identifier;
  String? modelName;

  IdempiereProductType({this.propertyLabel, this.id, this.identifier, this.modelName});

  IdempiereProductType.fromJson(Map<String, dynamic> json) {
    propertyLabel = json['propertyLabel'];
    id = json['id'];
    identifier = json['identifier'];
    modelName = json['model-name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['propertyLabel'] = propertyLabel;
    data['id'] = id;
    data['identifier'] = identifier;
    data['model-name'] = modelName;
    return data;
  }

  static List<IdempiereProductType> fromJsonList(List<dynamic> list){
    List<IdempiereProductType> newList =[];
    for (var item in list) {
      if(item is IdempiereProductType){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereProductType idempiereProductType = IdempiereProductType.fromJson(item);
        newList.add(idempiereProductType);
      }

    }
    return newList;
  }


}