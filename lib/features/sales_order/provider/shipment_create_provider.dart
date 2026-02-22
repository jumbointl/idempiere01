import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/sales_order_and_lines.dart';
import 'package:monalisa_app_001/features/sales_order/provider/shipment_action_result.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/auth_data.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/model_run_process_request.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/run_process_response.dart';

import '../../../../config/http/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../products/domain/idempiere/response_async_value.dart';
import '../../products/domain/idempiere/response_async_value_ui_model.dart';
import '../../products/presentation/widget/response_async_value_messages_card.dart';
import '../../shared/data/messages.dart';



final fireCreateShipmentProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final ordersForCreateShipmentProvider = StateProvider.autoDispose<List<SalesOrderAndLines>>((ref) {
  return [];
});
final createShipmentProvider = FutureProvider.autoDispose<ResponseAsyncValue?>((ref) async {
  final int count = ref.watch(fireCreateShipmentProvider);
  if (count == 0) return null;
  debugPrint('fireCreateShipmentProvider: $count');


  final List<SalesOrderAndLines> orderIds = ref.read(ordersForCreateShipmentProvider);
  if (orderIds.isEmpty) return null;
  debugPrint('idForCreateShipmentProvider: $orderIds');


  final responseAsyncValue = ResponseAsyncValue()
    ..isInitiated = true
    ..success = true; // asumimos OK hasta que falle alguno

  final results = <ShipmentActionItemResult>[];

  try {
    final dio = await DioClient.create();
    final String url = ModelRunProcessRequest.runProcessRequestUrl;

    final authState = ref.read(authProvider);
    final authData = authState.toAuthData();

    for (final order in orderIds) {
      try {
        final request = ModelRunProcessRequest.runProcessCreateShipmentRequestJson(
          salesOrder : order,
          columnValue: order.id?.toString() ?? '',
          authData: authData,
        );
        debugPrint('url: $url');
        debugPrint('request: $request');

        final response = await dio.post(url, data: request);

        if (response.statusCode == 200) {
          final runField = RunProcessResponse.runProcessResponseFieldNameInJson;
          final runProcessResponse =
          RunProcessResponse.fromJson(response.data[runField]);

          if (runProcessResponse.isError == false) {
            results.add(
              ShipmentActionItemResult(
                orderId: order.id?.toString() ?? '',
                success: true,
                summary: runProcessResponse.summary,
              ),
            );
          } else {
            // fallo lógico (200 pero isError)
            responseAsyncValue.success = false;

            final messageDefault =
                'Error al crear shipment (HTTP 200 pero sin éxito)';
            final errMsg = runProcessResponse.error ?? messageDefault;
            debugPrint('errMsg: $errMsg');


            results.add(
              ShipmentActionItemResult(
                orderId: order.id?.toString() ?? '',
                success: false,
                error: errMsg,
              ),
            );
          }
        } else {
          // fallo HTTP
          responseAsyncValue.success = false;
          final errMsg =
              'Error HTTP ${response.statusCode} al crear shipment';

          results.add(
            ShipmentActionItemResult(
              orderId: order.id?.toString() ?? '',
              success: false,
              error: errMsg,
            ),
          );
        }
      } catch (e) {
        // fallo por orden (network/parsing/etc.)
        responseAsyncValue.success = false;
        results.add(
          ShipmentActionItemResult(
            orderId: order.id?.toString() ?? '',
            success: false,
            error: e.toString(),
          ),
        );
      }
    }

    // ✅ construir mensaje global
    final okCount = results.where((r) => r.success).length;
    final failCount = results.length - okCount;

    responseAsyncValue.data = results; // 👈 lista para UI
    responseAsyncValue.message = responseAsyncValue.success == true
        ? '✅ Shipments creados: $okCount/${results.length}'
        : '⚠️ Resultado parcial: OK $okCount / FAIL $failCount';

    return responseAsyncValue;
  } on DioException catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.data = results; // opcional: deja lo que alcanzó
    responseAsyncValue.message = e.message ?? e.toString();
    return responseAsyncValue;
  } catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.data = results; // opcional
    responseAsyncValue.message = e.toString();
    return responseAsyncValue;
  }
});


Widget shipmentCreateAsyncValueErrorHandle(WidgetRef ref, {required ResponseAsyncValue result}) {
  final uiModel = mapResponseAsyncValueToUi(
    result: result,
    title: Messages.SHIPMENT_CREATE,
    subtitle: Messages.ERROR_SHIPMENT_CREATE,
  );
  return   ResponseAsyncValueMessagesCardAnimated(
    ui: uiModel,);

}