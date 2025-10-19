


import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_data_movement.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_movement.dart';
import '../../domain/idempiere/idempiere_movement_line.dart';
import '../../domain/sql/common_sql_data.dart';
import '../../domain/sql/sql_data_movement_line.dart';
import '../screens/store_on_hand/memory_products.dart';


final movementIdForConfirmProvider = StateProvider.autoDispose<int?>((ref) {
  return null;
});

final isMovementShowedProvider = StateProvider<bool>((ref) {
  return false;
});
final isMovementCreateScreenShowedProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final stringForSearchProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

// pasa usar en confirm
final movementDocumentStatusProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});




final resultOfMovementLineCreateProvider = StateProvider.autoDispose<List<IdempiereMovementLine>?>((ref) {
  return null;
});

final resultOfCreateMovementLinesProvider = StateProvider.autoDispose<List<IdempiereMovementLine>?>((ref) {
  return null;
});

final movementSqlQueryTypeProvider = StateProvider.autoDispose<int>((ref) {
  return ProductsScanNotifier.SQL_QUERY_SELECT;
});

final movementIdForMovementLineSearchProvider = StateProvider.autoDispose<int?>((ref) {
  return null;
});



final resultOfSearchMovementsProvider = StateProvider.autoDispose<List<IdempiereMovement>?>((ref) {
  return null;
});




final movementLineScrollAtEndProvider = Provider.autoDispose<bool>((ref) {
  return false;
});

final  startedCreateNewPutAwayMovementProvider = StateProvider.autoDispose<bool?>((ref) {
  return null;
});
final  startedCreateNewMovementLineProvider = StateProvider.autoDispose<bool?>((ref) {
  return null;
});

final newSqlDataMovementProvider = StateProvider.autoDispose<SqlDataMovement>((ref) {
  return SqlDataMovement(id:Memory.INITIAL_STATE_ID,name: Messages.EMPTY);
});
final newSqlDataMovementLineProvider = StateProvider.autoDispose<SqlDataMovementLine>((ref) {
  return SqlDataMovementLine(id:Memory.INITIAL_STATE_ID,name: Messages.EMPTY);
});
final newSqlDataPutAwayMovementProvider = StateProvider.autoDispose<SqlDataMovement>((ref) {
  return SqlDataMovement(id:-1,name: Messages.EMPTY);
});

/*final allowedLocatorFromIdProvider = StateProvider.autoDispose<IdempiereLocator?>((ref) {
  return null;
});
final allowedLocatorToMoveIdProvider = StateProvider<IdempiereLocator?>((ref) {
  return null;
});*/



final createNewMovementProvider = FutureProvider.autoDispose<IdempiereMovement?>((ref) async {
  SqlDataMovement newMovement = ref.watch(newSqlDataMovementProvider);
  if(newMovement.id!=null && newMovement.id!>0) return null;
  if(newMovement.mWarehouseID==null || newMovement.mWarehouseID!.id==null || newMovement.mWarehouseID!.id!<=0){
    return null;
  }
  if(newMovement.mWarehouseToID==null || newMovement.mWarehouseToID!.id==null || newMovement.mWarehouseToID!.id!<=0){
    return null;
  }

  Dio dio = await DioClient.create();
  try {
    String url = newMovement.getInsertUrl();
    final response = await dio.post(url, data: newMovement.getInsertJson());
    ref.read(movementIdForMovementLineSearchProvider.notifier).state = null;
    if (response.statusCode == 201) {

      SqlDataMovement movement =  SqlDataMovement.fromJson(response.data);
      if (movement.id != null && movement.id! > 0) {
        MemoryProducts.movementAndLines.cloneMovement(movement);
        return movement;
      } else {
        return IdempiereMovement(id:Memory.ERROR_ID,name: Messages.ERROR);
      }
    } else {
      return IdempiereMovement(id:Memory.ERROR_ID,name: Messages.ERROR);
     /* throw Exception(
          'Error al obtener la lista de $url: ${response.statusCode}');*/
    }

  } on DioException {
    final authDataNotifier = ref.read(authProvider.notifier);
    return IdempiereMovement(id:Memory.ERROR_ID,name: Messages.ERROR);
    //throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    return IdempiereMovement(id:Memory.ERROR_ID,name: Messages.ERROR);
    //throw Exception(e.toString());
  }

});


final scannedConfirmMovementProvider = StateProvider.autoDispose<int>((ref) {
  return -1;
});

final confirmMovementProvider = FutureProvider.autoDispose<MovementAndLines?>((ref) async {

  int id = ref.watch(movementIdForConfirmProvider) ?? -1;
  if(id <=0) return null;
  Dio dio = await DioClient.create();
  try {
    SqlDataMovement movement = SqlDataMovement(id:id);
    Memory.sqlUsersData.copyToSqlData(movement);

    String url =movement.getUpdateUrl();
    print(url);
    print(movement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));
    print('---start-------------confirmMovementProvider');
    final response = await dio.put(url, data: movement.getUpdateDocStatusJson(CommonSqlData.DOC_COMPLETE_STATUS));
    print('---result-------------confirmMovementProvider ${response.statusCode}');

    if (response.statusCode == 200) {
      movement =  SqlDataMovement.fromJson(response.data);
      MovementAndLines movementAndLines = MovementAndLines();
      movementAndLines.cloneMovement(movement);
      MemoryProducts.movementAndLines = movementAndLines;
      print('---result-------------confirmMovementProvider ${movement.docStatus?.id ?? 'doc null'}');

      return movementAndLines;
    } else {
      return MovementAndLines(id: Memory.ERROR_ID,
          name: '${Messages.ERROR }${response.statusCode} : ${response.statusMessage}' );
      throw Exception(
          'Error al obtener la lista de $url: ${response.statusCode}');
    }



  } on DioException catch (e) {
    ref.invalidate(movementIdForConfirmProvider);
    return MovementAndLines(id: Memory.ERROR_ID,
        name: '${Messages.ERROR } ${e.toString()}' );
    //final authDataNotifier = ref.read(authProvider.notifier);
    //throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    ref.invalidate(movementIdForConfirmProvider);
    return MovementAndLines(id: Memory.ERROR_ID,
        name: '${Messages.ERROR } ${e.toString()}' );
    //throw Exception(e.toString());
  }

});




