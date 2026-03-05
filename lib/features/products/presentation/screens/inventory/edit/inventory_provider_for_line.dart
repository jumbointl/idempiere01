import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../config/http/dio_client.dart';
import '../../../../../shared/data/memory.dart';
import '../../../../domain/idempiere/idempiere_inventory_line.dart';
import '../../../../domain/sql/sql_data_inventory_line.dart';
import '../../../providers/actions/find_inventory_by_id_action_provider.dart';
import '../../../../../shared/data/messages.dart';

final fireCreateInventoryLineProvider = StateProvider<int>((ref) {
  return 0;
});

final newSqlDataInventoryLineProvider =
StateProvider<SqlDataInventoryLine>((ref) {
  return SqlDataInventoryLine(
    id: Memory.INITIAL_STATE_ID,
    name: Messages.EMPTY,
  );
});

final createNewInventoryLineProvider =
FutureProvider.autoDispose<IdempiereInventoryLine?>((ref) async {
  final counter = ref.watch(fireCreateInventoryLineProvider);
  if (counter == 0) return null;

  final newInventoryLine = ref.read(newSqlDataInventoryLineProvider);

  if (newInventoryLine.id != null && newInventoryLine.id! > 0) return null;
  if (newInventoryLine.mInventoryID == null ||
      newInventoryLine.mInventoryID!.id == null ||
      newInventoryLine.mInventoryID!.id! <= 0) {
    return null;
  }
  if (newInventoryLine.mLocatorID == null ||
      newInventoryLine.mLocatorID!.id == null ||
      newInventoryLine.mLocatorID!.id! <= 0) {
    return null;
  }
  if (newInventoryLine.mProductID == null ||
      newInventoryLine.mProductID!.id == null ||
      newInventoryLine.mProductID!.id! <= 0) {
    return null;
  }

  final dio = await DioClient.create();

  try {
    final String url = newInventoryLine.getInsertUrl();
    final response = await dio.post(url, data: newInventoryLine.getInsertJson());

    if (response.statusCode == 201) {
      final result = IdempiereInventoryLine.fromJson(response.data);

      if (result.id != null && result.id! > 0) {
        newInventoryLine.id = result.id;

        final inventory = ref.read(inventoryAndLinesProvider);
        inventory.inventoryLines ??= [];
        inventory.inventoryLines!.add(result);
        ref.read(inventoryAndLinesProvider.notifier).state = inventory;

        return result;
      }

      return null;
    }

    return null;
  } on DioException {
    debugPrint('DioException on create inventory line');
    return null;
  } catch (e) {
    debugPrint('Exception: ${e.toString()}');
    return null;
  }
});