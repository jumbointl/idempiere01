class ResponseApi<T> {
  int? pageCount;
  int? recordsSize;
  int? skipRecords;
  int? rowCount;
  int? arrayCount;
  List<T>? records;

  ResponseApi({
    this.pageCount,
    this.recordsSize,
    this.skipRecords,
    this.rowCount,
    this.arrayCount,
    this.records,
  });

  factory ResponseApi.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) => ResponseApi(
    pageCount: json["page-count"],
    recordsSize: json["records-size"],
    skipRecords: json["skip-records"],
    rowCount: json["row-count"],
    arrayCount: json["array-count"],
    records: List<T>.from(json["records"].map((x) => fromJsonT(x))),        
  );
}