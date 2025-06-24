class ModelCrud {
  String? serviceType;
  String? tableName;
  int? recordId;
  String? action;
  Map<String, dynamic>? dataRow;

  ModelCrud({
    this.serviceType,
    this.tableName,
    this.recordId,
    this.action,
    this.dataRow,
  });

  Map<String, dynamic> toJson() => {
        "serviceType": serviceType,
        "TableName": tableName,
        "RecordID": recordId,
        "Action": action,
        "DataRow": dataRow,
      };

  ModelCrud copyWith({
    String? serviceType,
    String? tableName,
    int? recordId,
    String? action,
    Map<String, dynamic>? dataRow,
  }) =>
      ModelCrud(
        serviceType: serviceType ?? this.serviceType,
        tableName: tableName ?? this.tableName,
        recordId: recordId ?? this.recordId,
        action: action ?? this.action,
        dataRow: dataRow ?? this.dataRow,
      );
}
