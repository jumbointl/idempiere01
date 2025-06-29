import 'object_with_name_and_id.dart';

class IdempiereFilter extends ObjectWithNameAndId{
  String field;
  String operator;
  String value;
  String? image;
  String? conjunction;
  IdempiereFilter({
    super.id,
    super.name,
    super.active,
    this.image,
    this.conjunction,
    required this.field,
    required this.operator,
    required this.value,
});
  factory IdempiereFilter.fromJson(Map<String, dynamic> json) => IdempiereFilter(
    active: json["active"],
    id: json["id"],
    name: json["name"],
    field: json["field"],
    operator: json["operator"],
    value: json["value"],
    image: json["image"],
    conjunction: json["conjunction"],
  );
  static List<IdempiereFilter> fromJsonList(List<dynamic> list){
    List<IdempiereFilter> newList =[];
    for (var item in list) {
      if(item is IdempiereFilter){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        IdempiereFilter idempiereFilter = IdempiereFilter.fromJson(item);
        newList.add(idempiereFilter);
      }

    }
    return newList;
  }
  @override
  Map<String, dynamic> toJson() => {
    "active": active,
    "id": id,
    "name": name,
    "field": field,
    "operator": operator,
    "value": value,
    "image": image,
  };

  String getSentence() {
    String filter = '';
    conjunction ??= '';
    if(operator =='contains' || operator =='startswith' || operator =='endswith' || operator =='tolower' || operator =='toupper'){
      filter = "$filter $operator($field,'$value')";
    } else if(operator =='in'){
      filter = "$filter $field $operator($value)";
    } else {
      if(value=='null' || value=='true' || value=='false'){
        filter = "$filter $conjunction $field $operator $value";
      } else {
        filter = "$filter $conjunction $field $operator '$value'";
      }

    }
    filter = filter.replaceAll('  ', ' ');
    print('-------------------------------------$filter');

    return filter;
  }

}