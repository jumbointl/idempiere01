class ModelSetDocAction {
  String? serviceType;
  String? tableName;
  int? recordId;
  String? docAction;

  ModelSetDocAction({
    this.serviceType,
    this.tableName,
    this.recordId,
    this.docAction,
  });

  Map<String, dynamic> toJson() => {
        "serviceType": serviceType,
        "tableName": tableName,
        "recordID": recordId,
        "docAction": docAction,
      };

  ModelSetDocAction copyWith({
    String? serviceType,
    String? tableName,
    int? recordId,
    String? docAction,
  }) =>
      ModelSetDocAction(
        serviceType: serviceType ?? this.serviceType,
        tableName: tableName ?? this.tableName,
        recordId: recordId ?? this.recordId,
        docAction: docAction ?? this.docAction,
      );
}
