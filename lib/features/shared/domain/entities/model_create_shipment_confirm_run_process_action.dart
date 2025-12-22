import 'model_run_process_action.dart';

class ModelCreateShipmentConfirmRunProcessAction
    extends ModelRunProcessAction {
  String confirmType ='PC';
  ModelCreateShipmentConfirmRunProcessAction({
    super.columnValue,
  }) : super(
      processId: 281,
      columnName: 'AD_Record_ID',
      serviceType: 'RunGenerateShipmentConfirm',
  );
  @override
  Map<String, dynamic> toJson() {
    return {
      "serviceType": "RunGenerateShipmentConfirm",
      "ParamValues": {
        "field": [
          {
            "@column": "AD_Record_ID",
            "val": columnValue,
          },
          {
            "@column": "ConfirmType",
            "val": "SC",
          },
        ],
      },
    };
  }

}
