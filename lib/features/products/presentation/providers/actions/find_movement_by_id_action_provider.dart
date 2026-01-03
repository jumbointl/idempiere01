import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../config/http/dio_client.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../../shared/domain/entities/response_api.dart';
import '../../../domain/idempiere/idempiere_movement.dart';
import '../../../domain/idempiere/idempiere_movement_confirm.dart';
import '../../../domain/idempiere/idempiere_movement_line.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../screens/movement/provider/new_movement_provider.dart';
import '../../screens/store_on_hand/memory_products.dart';

final fireFindMovementByIdProvider = StateProvider<int>((ref) {
  return 0;
});
final newScannedMovementIdForSearchProvider = StateProvider<String>((ref) {
  return '';
});



final newFindMovementByIdOrDocumentNOProvider = FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();
  final int count = ref.watch(fireFindMovementByIdProvider);
  if(count==0) {
    MemoryProducts.movementAndLines.clearData();
    responseAsyncValue.data = MemoryProducts.movementAndLines;
    return responseAsyncValue;
  }

  final String scannedCode = ref.read(newScannedMovementIdForSearchProvider).toUpperCase();

  if(scannedCode=='') {
    MemoryProducts.movementAndLines.clearData();
    responseAsyncValue.data = MemoryProducts.movementAndLines;
    return responseAsyncValue;
  }
  responseAsyncValue.isInitiated = true;
  String idempiereModelName ='m_movement';
  Dio dio = await DioClient.create();
  try {
    String url =  "/api/v1/models/$idempiereModelName";
    int? aux = int.tryParse(scannedCode);
    if(aux==null || scannedCode.startsWith('0')){
      url = "/api/v1/models/$idempiereModelName?\$filter=DocumentNo eq '$scannedCode'";
    } else{
      url = "/api/v1/models/$idempiereModelName?\$filter=M_Movement_ID eq $scannedCode";
    }
    url = url.replaceAll(' ', '%20');
    final response = await dio.get(url);

    if (response.statusCode == 200) {

      responseAsyncValue.success = true;
      final responseApi =
      ResponseApi<IdempiereMovement>.fromJson(response.data, IdempiereMovement.fromJson);
      late IdempiereMovement m;
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        m = responseApi.records![0];
        if(m.id==null || m.id==Memory.INITIAL_STATE_ID || m.id!<=0) {
          responseAsyncValue.data = null;
          return responseAsyncValue;
        } else {
          MemoryProducts.movementAndLines.cloneMovement(m);
          final String searchField ='M_Movement_ID';
          String idempiereModelName ='m_movementline';
          Dio dio = await DioClient.create();
          String url =
              "/api/v1/models/$idempiereModelName?\$expand=M_Product_ID&\$filter=$searchField eq ${m.id!}&\$orderby=Line";
          url = url.replaceAll(' ', '%20');
          final response = await dio.get(url);

          if (response.statusCode == 200) {
            responseAsyncValue.success = true;
            final responseApi =
            ResponseApi<IdempiereMovementLine>.fromJson(response.data, IdempiereMovementLine.fromJson);
            if (responseApi.records != null && responseApi.records!.isNotEmpty) {
              final dataList = responseApi.records!;
              MemoryProducts.movementAndLines.movementLines = dataList;
            } else {
              MemoryProducts.movementAndLines.movementLines = [];
            }

          }
          idempiereModelName ='m_movementconfirm';
          url =
          "/api/v1/models/$idempiereModelName?\$filter=$searchField eq ${m.id!}&\$orderby=Line";
          url = url.replaceAll(' ', '%20');
          final response2 = await dio.get(url);
          if (response2.statusCode == 200) {
            final responseApi =
            ResponseApi<IdempiereMovementConfirm>.fromJson(response2.data, IdempiereMovementConfirm.fromJson);
            if (responseApi.records != null && responseApi.records!.isNotEmpty) {
              final dataList = responseApi.records!;
              MemoryProducts.movementAndLines.movementConfirms = dataList;

            } else {
              MemoryProducts.movementAndLines.movementConfirms  = [];
            }
          }

        }

      }

      responseAsyncValue.data = MemoryProducts.movementAndLines;
    } else {
      responseAsyncValue.success = false;
      responseAsyncValue.message = '${Messages.VALUE} : $scannedCode : ${response.statusCode} ${response.statusMessage!}';
      responseAsyncValue.data = null;

    }
    ref.invalidate(movementAndLinesProvider);
    return responseAsyncValue;
  } on DioException {

    responseAsyncValue.success = false;
    responseAsyncValue.message = '${Messages.VALUE} : $scannedCode : ${Messages.ERROR} DioException';
    ref.invalidate(movementAndLinesProvider);
    responseAsyncValue.data = null ;
    return responseAsyncValue;

  } catch (e) {
    ref.invalidate(movementAndLinesProvider);
    responseAsyncValue.success = false ;
    responseAsyncValue.message = '${Messages.VALUE} : $scannedCode : ${Messages.ERROR +e.toString()}';
    responseAsyncValue.data =null;
    return responseAsyncValue;
  }

});