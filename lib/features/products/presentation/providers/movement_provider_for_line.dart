

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/presentation/screens/movement/provider/new_movement_provider.dart';

import '../../../../config/http/dio_client.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_movement_line.dart';
import '../../domain/sql/sql_data_movement_line.dart';

final fireCreateMovementLineProvider = StateProvider<int>((ref) {
  return 0;
});

final newSqlDataMovementLineProvider = StateProvider<SqlDataMovementLine>((ref) {
  return SqlDataMovementLine(id:Memory.INITIAL_STATE_ID,name: Messages.EMPTY);
});


final createNewMovementLineProvider = FutureProvider.autoDispose<IdempiereMovementLine?>((ref) async {
  int counter = ref.watch(fireCreateMovementLineProvider);
  if(counter==0){
    return null;
  }


  SqlDataMovementLine newMovementLine = ref.read(newSqlDataMovementLineProvider);

  if(newMovementLine.id!=null && newMovementLine.id!>0){
    return null;
  }
  if(newMovementLine.mMovementID==null || newMovementLine.mMovementID!.id!<=0) {
    return null;}
  if(newMovementLine.mLocatorID ==null || newMovementLine.mLocatorID!.id==null || newMovementLine.mLocatorID!.id!<=0){
    return null;
  }
  if(newMovementLine.mLocatorToID==null || newMovementLine.mLocatorToID!.id==null || newMovementLine.mLocatorToID!.id!<=0){
    return null;
  }



  Dio dio = await DioClient.create();
  try {
    String url = newMovementLine.getInsertUrl();
    final response = await dio.post(url, data: newMovementLine.getInsertJson());
    if (response.statusCode == 201) {

      IdempiereMovementLine result =  IdempiereMovementLine.fromJson(response.data);
      if (result.id != null && result.id! > 0) {
        newMovementLine.id = result.id;
        MovementAndLines m = ref.read(movementAndLinesProvider);
        m.movementLines ??= [];
        m.movementLines!.add(result);
        ref.read(movementAndLinesProvider.notifier).state = m;

        return result;

      } else {
        return null;
      }
    } else {
      return null;
    }
  } on DioException {
    debugPrint('DioException');
    return null;
  } catch (e) {
    debugPrint('Exception : ${e.toString()}');
    return null;
  }

});