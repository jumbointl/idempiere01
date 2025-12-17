abstract class CommonSqlData {
  static const String DOC_COMPLETE_STATUS ='CO';
  static const String DOC_DRAFT_STATUS ='DR';
  static const String DOC_DELETE_STATUS ='VO';
  String getInsertUrl();
  String getSelectUrl();
  String getUpdateUrl();
  String getDeleteUrl();
  Map<String, dynamic>  getDeleteJson();
  Map<String, dynamic>  getUpdateDocStatusJson(String status);
}