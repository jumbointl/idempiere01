import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/auth_data.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/model_run_process_request.dart';
import 'package:monalisa_app_001/features/shared/domain/entities/run_process_response.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/domain/idempiere/response_async_value.dart';

final idForCreatePickConfirmProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
final createPickConfirmProvider = FutureProvider.autoDispose<ResponseAsyncValue?>((ref) async {
  final String mInOutId = ref.watch(idForCreatePickConfirmProvider).toUpperCase();

  ResponseAsyncValue responseAsyncValue = ResponseAsyncValue();
  if(mInOutId=='') {
    return null;
  }
  print('--------------------------------provider--start findSearchConfirmProvider $mInOutId');
  responseAsyncValue.isInitiated = true;

  try {
    final dio = await DioClient.create();
    final String url = ModelRunProcessRequest.runProcessRequestUrl ;
    final authState = ref.read(authProvider);
    final authData = authState.toAuthData();


    //final serviceType = 'RunGeneratePickupConfirm';
    //final columnName =  'AD_Record_ID';
    final request = ModelRunProcessRequest.runProcessCreatePickConfirmRequestJson(
      columnValue: mInOutId,
      authData: authData,
    );
    print(request);
    print(url);
    final response = await dio.post(url, data: request);
    if (response.statusCode == 200) {
      print(response.statusCode);
      print(response.data);
      final runProcessResponseFieldNameInJson = RunProcessResponse.runProcessResponseFieldNameInJson;
      final runProcessResponse =
      RunProcessResponse.fromJson(response.data[runProcessResponseFieldNameInJson]);
      print(runProcessResponse.toJson() );
      if (runProcessResponse.isError == false) {
        responseAsyncValue.success = true;
        responseAsyncValue.data = runProcessResponse.summary ;
        return responseAsyncValue;
      } else {
        responseAsyncValue.success = false;
        responseAsyncValue.data = null ;
        String message = 'Error al crear los datos del pick confirm: http status code 200,peron sin exito';
        responseAsyncValue.message = runProcessResponse.error ?? message;
        print(responseAsyncValue.message);
        return responseAsyncValue;
      }
    } else {
      print(response.statusCode);
      responseAsyncValue.success = false;
      responseAsyncValue.data = null ;
      responseAsyncValue.message = 'Error al crear los datos del pick confirm: http status ${response.statusCode}';
      print(responseAsyncValue.message);
      return responseAsyncValue;
      //throw Exception(standardResponse.error ?? 'Unknown error');
    }

  } on DioException catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.data = null ;
    responseAsyncValue.message = e.message;
    print(responseAsyncValue.message);
    return responseAsyncValue;

  } catch (e) {
    responseAsyncValue.success = false;
    responseAsyncValue.data = null ;
    responseAsyncValue.message = e.toString();
    print(responseAsyncValue.message);
    return responseAsyncValue;
  }

});