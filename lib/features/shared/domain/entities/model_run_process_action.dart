abstract class ModelRunProcessAction {
  final String? serviceType;
  final String? columnName;
  final dynamic columnValue;
  final int processId;

  const ModelRunProcessAction({
    this.serviceType,
    this.columnName,
    this.columnValue,
    required this.processId,
  });

  Map<String, dynamic> toJson();
}












/*
class ModelRunProcessAction {
  String? serviceType;
  String? columnName;
  dynamic columnValue;
  int processId ;

  ModelRunProcessAction({
    this.serviceType,
    this.columnName,
    this.columnValue,
    required this.processId,
  });

  Map<String, dynamic> toJson() => {
        "@AD_Process_ID": 281,
        "@AD_Record_ID": columnValue,
        "@DocAction": "PC",
        "serviceType": serviceType,
        "ParamValues": '{field: [ {@column: $columnName, val: $columnValue },{@column: ID_Process_ID, val: 281 }]}'
      };

  ModelRunProcessAction copyWith({
    String? serviceType,
    String? columnName,
    dynamic columnValue,
    int? processId,
  }) =>
      ModelRunProcessAction(
        serviceType: serviceType ?? this.serviceType,
        columnName: columnName ?? this.columnName,
        columnValue: columnValue ?? columnValue,
        processId: processId ?? this.processId,
      );
}
*/
