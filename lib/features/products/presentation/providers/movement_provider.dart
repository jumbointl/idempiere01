


import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/sql/sql_data_movement_line.dart';
import '../screens/store_on_hand/memory_products.dart';

final  startedCreateNewPutAwayMovementProvider = StateProvider.autoDispose<bool?>((ref) {
  return null;
});

final newSqlDataMovementProvider = StateProvider.autoDispose<SqlDataMovement>((ref) {
  return SqlDataMovement(id:-1,name: Messages.EMPTY);
});

final sqlDataMovementResultProvider = StateProvider.autoDispose<SqlDataMovement>((ref) {
  return SqlDataMovement(id:-1,name: Messages.EMPTY);
});


final sqlDataMovementLinesResultProvider = StateProvider.autoDispose<List<SqlDataMovementLine>>((ref) {
  return [];
});

final newPutAwayMovementProvider = FutureProvider.autoDispose<bool?>((ref) async {
  SqlDataMovement newMovement = ref.watch(newSqlDataMovementProvider);
  if(newMovement.id!=null) return null;

  //ref.watch(sqlDataMovementResultProvider.notifier).update((state) => SqlDataMovement(id:-1,name: Messages.EMPTY));
  //print('--------------------------------------0');
  //ref.watch(sqlDataMovementLinesResultProvider.notifier).update((state) => []);
  print('--------------------------------------1');
  Dio dio = await DioClient.create();
  try {
    String url = newMovement.getInsertUrl();
    final response = await dio.post(url, data: newMovement.getInsertJson());
    if (response.statusCode == 201) {

      SqlDataMovement movement =  SqlDataMovement.fromJson(response.data);
      if (movement.id != null && movement.id! > 0) {
       
        MemoryProducts.newSqlDataMovement = movement;
        print(movement.toJson());
        for(int i=0; i<MemoryProducts.newSqlDataMovementLines.length; i++){
          /*if(MemoryProducts.newSqlDataMovementLines[i].mMovementID == null || MemoryProducts.newSqlDataMovementLines[i].mMovementID!.id == null){
          }

           */
          MemoryProducts.newSqlDataMovementLines[i].mMovementID = movement;
          MemoryProducts.newSqlDataMovementLines[i].line = (i+1)*10;
          var creteDataJsonEncode2 = MemoryProducts.newSqlDataMovementLines[i].getInsertJson();
          url = MemoryProducts.newSqlDataMovementLines[i].getInsertUrl();
          print('-----------$i---------start create line');
          final responseLine = await dio.post(url, data: creteDataJsonEncode2);
          if (responseLine.statusCode == 201) {
            final SqlDataMovementLine movementLine =  SqlDataMovementLine.fromJson(responseLine.data);
            MemoryProducts.newSqlDataMovementLines[i] = movementLine;
            print('-----------$i----------${MemoryProducts.newSqlDataMovementLines[i].toJson()}');

            ref.read(sqlDataMovementLinesResultProvider.notifier).state = MemoryProducts.newSqlDataMovementLines;
            return true;
          } else {
            return false;
          }


        }

        /*url =movement.getUpdateUrl();
        final responseLine = await dio.put(url, data: movement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));

        if (responseLine.statusCode == 200) {
          movement =  SqlDataMovement.fromJson(responseLine.data);
          MemoryProducts.newSqlDataMovement = movement;
          print(MemoryProducts.newSqlDataMovement.toJson());
          ref.read(sqlDataMovementResultProvider.notifier).state = movement;
          print('----------state---${ref.read(sqlDataMovementResultProvider.notifier).state.toJson()}');
          print('--------------------------state-------${ref.read(sqlDataMovementLinesResultProvider.notifier).state.length}');
          print('--------------------------------------${MemoryProducts.newSqlDataMovementLines.length}');
          return true;
        } else {
          return false;
        }*/

      } else {

        return false;
      }
    } else {
      throw Exception(
          'Error al obtener la lista de $url: ${response.statusCode}');
    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }
  return null;

});