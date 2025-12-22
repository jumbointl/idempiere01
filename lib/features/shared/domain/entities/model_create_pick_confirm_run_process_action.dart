import 'model_run_process_action.dart';

class ModelCreatePickConfirmRunProcessAction
    extends ModelRunProcessAction {
  String confirmType ='PC';
  ModelCreatePickConfirmRunProcessAction({
    super.columnValue,
  }) : super(
      processId: 281,
      columnName: 'AD_Record_ID',
      serviceType: 'RunGeneratePickupConfirm',
  );
  @override
  Map<String, dynamic> toJson() {
    return {
      "serviceType": "RunGeneratePickupConfirm",
      "ParamValues": {
        "field": [
          {
            "@column": "AD_Record_ID",
            "val": columnValue,
          },
          {
            "@column": "ConfirmType",
            "val": "PC",
          },
        ],
      },
    };
  }

}
