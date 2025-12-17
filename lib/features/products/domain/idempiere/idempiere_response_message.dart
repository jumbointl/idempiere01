
class IdempiereResponseMessage {
  String? msg;
  static const String DELETED ='Deleted';
  static const String DELETED_ES ='Borrado';
  IdempiereResponseMessage({
    this.msg,
  });

  factory IdempiereResponseMessage.fromJson(Map<String, dynamic> json) {
    return IdempiereResponseMessage(
      msg: json['msg'],
    );
  }
  bool get deleted => msg == DELETED || msg == DELETED_ES;


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataInJsonIn = {};
    dataInJsonIn['msd'] = msg;
    return dataInJsonIn;
  }
  
  
  static List<IdempiereResponseMessage> fromJsonList(List<dynamic> list){
    List<IdempiereResponseMessage> newList =[];
    for (var item in list) {
      if(item is IdempiereResponseMessage){
        newList.add(item);
      } else {
        IdempiereResponseMessage object = IdempiereResponseMessage.fromJson(item);
        newList.add(object);
      }

    }
    return newList;
  }


 
}