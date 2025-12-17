
class ResponseAsyncValue {
  String? message;
  bool isInitiated = false;
  bool success = false;
  dynamic data;
  ResponseAsyncValue({
    this.message,
    this.isInitiated = false,
    this.data,
    this.success = false,
  });

  ResponseAsyncValue.fromJson(Map<String, dynamic> json) {
    success = json['success'] ?? false;
    data = json['data'];
    message = json['name'];
    isInitiated = json['is_initiated'] ?? false;
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> dataInJsonIn = {};
    dataInJsonIn['success'] = success;
    dataInJsonIn['data'] = data?.toJson();
    dataInJsonIn['name'] = message;
    dataInJsonIn['is_initiated'] = isInitiated;
    return dataInJsonIn;
  }
  
  
  static List<ResponseAsyncValue> fromJsonList(List<dynamic> list){
    List<ResponseAsyncValue> newList =[];
    for (var item in list) {
      if(item is ResponseAsyncValue){
        newList.add(item);
      } else {
        ResponseAsyncValue object = ResponseAsyncValue.fromJson(item);
        newList.add(object);
      }

    }
    return newList;
  }
 
}