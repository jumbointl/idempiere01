class IdempiereQueryResult {
  int? pageCount;
  int? recordsSize;
  int? skipRecords;
  int? rowCount;
  int? arrayCount;
  List<Map<String, dynamic>>? records;

  IdempiereQueryResult(
      {this.pageCount,
        this.recordsSize,
        this.skipRecords,
        this.rowCount,
        this.arrayCount,
        this.records});

  IdempiereQueryResult.fromJson(Map<String, dynamic> json) {
    pageCount = json['page-count'];
    recordsSize = json['records-size'];
    skipRecords = json['skip-records'];
    rowCount = json['row-count'];
    arrayCount = json['array-count'];
    if (json['records'] != null) {
      records = <Map<String, dynamic>>[];
      json['records'].forEach((v) {
        records!.add(v);
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['page-count'] = pageCount;
    data['records-size'] = recordsSize;
    data['skip-records'] = skipRecords;
    data['row-count'] = rowCount;
    data['array-count'] = arrayCount;
    if (records != null) {
      data['records'] = records!;
    }
    return data;
  }
}