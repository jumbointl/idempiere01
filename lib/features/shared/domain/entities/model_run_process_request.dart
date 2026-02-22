import 'package:monalisa_app_001/features/products/domain/idempiere/sales_order_and_lines.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/model_create_pick_confirm_run_process_action.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/model_run_process_action.dart';

import 'ad_login_request.dart';
import 'auth_data.dart';
import 'model_create_shipment_confirm_run_process_action.dart';
import 'model_create_shipment_run_process_action.dart';

class ModelRunProcessRequest {
  ModelRunProcessAction? modelRunProcessAction;
  AdLoginRequest? adLoginRequest;

  ModelRunProcessRequest({
    this.modelRunProcessAction,
    this.adLoginRequest,
  });

  static String get runProcessRequestUrl => "/ADInterface/services/rest/model_adservice/run_process";

  Map<String, dynamic> toJson() => {

    'ModelRunProcess': modelRunProcessAction?.toJson(),
    'ADLoginRequest': adLoginRequest?.toJson(),
  };


  ModelRunProcessRequest copyWith({
    ModelRunProcessAction? modelRunProcessAction,
    AdLoginRequest? adLoginRequest,
  }) =>
      ModelRunProcessRequest(
        modelRunProcessAction: modelRunProcessAction ?? this.modelRunProcessAction,
        adLoginRequest: adLoginRequest ?? this.adLoginRequest,
      );

  static Map<String, dynamic> runProcessCreatePickConfirmRequestJson({
    //required String serviceType,
    required dynamic columnValue,
    required AuthData authData,
  }) {
    final action  =ModelCreatePickConfirmRunProcessAction(
      columnValue: columnValue,
    );
    final request = {
      "ModelRunProcessRequest": {
        "ModelRunProcess": action.toJson(),
        "ADLoginRequest": {
          "user": authData.userName,
          "pass": authData.password,
          "lang": "es_PY",
          "ClientID": authData.selectedClient.id,
          "RoleID": authData.selectedRole.id,
          "OrgID": authData.selectedOrganization.id,
          "WarehouseID": authData.selectedWarehouse.id,
          "stage": 9,
        }
      }
    };

    return request;

  }
  static Map<String, dynamic> runProcessCreateShipmentConfirmRequestJson({
    //required String serviceType,
    required dynamic columnValue,
    required AuthData authData,
  }) {
    final action  =ModelCreateShipmentConfirmRunProcessAction(
      columnValue: columnValue,
    );
    final request = {
      "ModelRunProcessRequest": {
        "ModelRunProcess": action.toJson(),
        "ADLoginRequest": {
          "user": authData.userName,
          "pass": authData.password,
          "lang": "es_PY",
          "ClientID": authData.selectedClient.id,
          "RoleID": authData.selectedRole.id,
          "OrgID": authData.selectedOrganization.id,
          "WarehouseID": authData.selectedWarehouse.id,
          "stage": 9,
        }
      }
    };

    return request;

  }

  static AdLoginRequest? loginFromAuth(AuthData authData) {
     return AdLoginRequest(
       user: authData.userName,
       pass: authData.password,
       lang: 'es_PY',
       clientId: authData.selectedClient.id,
       roleId: authData.selectedRole.id,
       orgId: authData.selectedOrganization.id,
       warehouseId: authData.selectedWarehouse.id,
       stage: 9,
     );
  }

  static Map<String, dynamic> runProcessCreateShipmentRequestJson({
    required dynamic columnValue,
    required AuthData authData, required SalesOrderAndLines salesOrder,
  }) {
    final action  =ModelCreateShipmentRunProcessAction(
      salesOrder: salesOrder,
      columnValue: columnValue,
    );
    final request = {
      "ModelRunProcessRequest": {
        "ModelRunProcess": action.toJson(),
        "ADLoginRequest": {
          "user": authData.userName,
          "pass": authData.password,
          "lang": "es_PY",
          "ClientID": authData.selectedClient.id,
          "RoleID": authData.selectedRole.id,
          "OrgID": authData.selectedOrganization.id,
          "WarehouseID": authData.selectedWarehouse.id,
          "stage": 9,
        }
      }
    };

    return request;

  }
}
