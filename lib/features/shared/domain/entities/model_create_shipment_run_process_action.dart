import 'package:monalisa_app_001/features/products/domain/idempiere/sales_order_and_lines.dart';

import 'model_run_process_action.dart';

class ModelCreateShipmentRunProcessAction
    extends ModelRunProcessAction {
  final SalesOrderAndLines salesOrder;
  ModelCreateShipmentRunProcessAction({
    super.columnValue, required this.salesOrder,
  }) : super(
      processId: 199,
      columnName: 'AD_Record_ID',
      serviceType: 'RunGenerateShipment',
  );
  @override
  Map<String, dynamic> toJson() {
    final date = DateTime.now().toIso8601String();
    return {
      "serviceType": "RunGenerateShipment",
      "ParamValues": {
        "field": [
          {
            "@column": "AD_Record_ID",
            "val": columnValue,
          },
          {
            "@column": "M_Warehouse_ID",
            "val": '${salesOrder.mWarehouseID?.id ?? ''}',
          },
          {
            "@column": "C_BPartner_ID",
            "val": '${salesOrder.cBPartnerID?.id ?? ''}',
          },
          {
            "@column": "MovementDate",
            "val": date,
          },
          {
            "@column": "DocAction",
            "val": "DR",
          },
        ],
      },
    };
  }

}
