import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../config/http/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../m_inout/domain/entities/line.dart';
import '../../m_inout/domain/entities/line_confirm.dart';
import '../../m_inout/domain/entities/m_in_out.dart';
import '../../m_inout/presentation/providers/m_in_out_providers.dart';
import '../../shared/infrastructure/errors/custom_error.dart';
import '../domain/idempiere/response_async_value.dart';

/// Generic REST partial update for iDempiere models.
/// Uses PATCH /api/v1/models/{model}/{id}
Future<Response<dynamic>> updateDataByRESTAPI({
  required String modelName,
  required int id,
  required Map<String, dynamic> data,
  required WidgetRef ref,
}) async {
  final dio = await DioClient.create();

  try {
    final String url = "/api/v1/models/$modelName/$id";
    debugPrint('updateDataByRESTAPI $url');
    debugPrint('updateDataByRESTAPI data $data');

    // PATCH is preferred for partial updates; switch to PUT if your server requires it
    final response = await dio.put(url, data: data);

    if (response.statusCode == 200) {
      return response;
    }

    throw Exception('REST update failed ($modelName/$id): ${response.statusCode}');
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }
}

Future<Response<dynamic>> updateDocumentStatusByRESTAPI({
  required String modelName,
  required int id,
  required WidgetRef ref,
  required String status,
}) async {
  return updateDataByRESTAPI(
    modelName: modelName,
    id: id,
    data: {"doc-action": status},
    ref: ref,
  );

}
/// Generic REST insert for iDempiere models.
/// Uses POST /api/v1/models/{model}
Future<Response<dynamic>> insertDataByRESTAPI({
  required String modelName,
  required Map<String, dynamic> data,
  required WidgetRef ref,
}) async {
  final dio = await DioClient.create();

  try {
    final String url = "/api/v1/models/$modelName";
    debugPrint('insertDataByRESTAPI $url');
    debugPrint('insertDataByRESTAPI data $data');
    final response = await dio.post(url, data: data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response;
    }

    throw Exception('REST insert failed ($modelName): ${response.statusCode}');
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }
}


/// Generic REST delete for iDempiere models.
/// Uses DELETE /api/v1/models/{model}/{id}
Future<Response<dynamic>> deleteDataByRESTAPI({
  required String modelName,
  required int id,
  required WidgetRef ref,
}) async {
  final dio = await DioClient.create();

  try {
    final String url = "/api/v1/models/$modelName/$id";
    final data = {
      "msg": "Deleted"
    };
    debugPrint('deleteDataByRESTAPI $url');
    debugPrint('deleteDataByRESTAPI id $id');
    debugPrint('deleteDataByRESTAPI data $data');
    final response = await dio.delete(url,data: data);
    debugPrint('deleteDataByRESTAPI response $response');
    if (response.statusCode == 200 || response.statusCode == 204) {
      return response;
    }

    throw Exception('REST delete failed ($modelName/$id): ${response.statusCode}');
  } on DioException catch (e) {
    debugPrint('deleteDataByRESTAPI DioException ${e.toString()}');
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    debugPrint('deleteDataByRESTAPI e ${e.toString()}');
    throw Exception(e.toString());
  }
}
Future<ResponseAsyncValue> deleteDataByRESTAPIResponseAsyncValue({
  required String modelName,
  required int? id,
  required WidgetRef ref,
  String successMessage = 'Deleted successfully',
}) async {

  /// English comment:
  /// "Validate ID before calling REST API"
  if (id == null || id <= 0) {
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'Invalid ID for delete ($modelName)',
    );
  }

  try {
    final response = await deleteDataByRESTAPI(
      modelName: modelName,
      id: id,
      ref: ref,
    );

    final code = response.statusCode;

    if (code != null && code >= 200 && code < 300) {
      return ResponseAsyncValue(
        success: true,
        isInitiated: true,
        data: null,
        message: successMessage,
      );
    }

    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'Delete failed ($modelName/$id) status: $code',
    );

  } catch (e) {
    debugPrint('deleteDataByRESTAPIResponseAsyncValue error: $e');

    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: e.toString(),
    );
  }
}
Future<ResponseAsyncValue> updateDataByRESTAPIResponseAsyncValue({
  required String modelName,
  required int? id,
  required Map<String, dynamic> data,
  required WidgetRef ref,
  String successMessage = 'Updated successfully',
}) async {

  /// English comment:
  /// "Validate ID before calling REST API"
  if (id == null || id <= 0) {
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'Invalid ID for update ($modelName)',
    );
  }

  try {
    final response = await updateDataByRESTAPI(
      modelName: modelName,
      id: id,
      data: data,
      ref: ref,
    );

    final code = response.statusCode;

    if (code != null && code >= 200 && code < 300) {
      return ResponseAsyncValue(
        success: true,
        isInitiated: true,
        data: response.data,
        message: successMessage,
      );
    }

    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'Update failed ($modelName/$id) status: $code',
    );

  } catch (e) {
    debugPrint('updateDataByRESTAPIResponseAsyncValue error: $e');

    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: e.toString(),
    );
  }
}
String makeFilterWithContains({
  required String searchField,
  required String searchValue,
  String operator = 'and', // 'and' or 'or'
}) {
  final tokens = searchValue
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  if (tokens.isEmpty) return '';


  String escapeOData(String s) {
    String t = s.replaceAll("'", '');
    t = t.replaceAll('"', '');
    t = t.replaceAll('(', '');
    t = t.replaceAll(')', '');
    return t;
  }



  return tokens
      .map((t) => "contains($searchField,'${escapeOData(t)}')")
      .join(' $operator ');
}



ResponseAsyncValue mapDioResponseToAsyncValue({
  required Response response,
  required String successMessage,
  String? failureMessagePrefix,
}) {
  final code = response.statusCode;

  // English comment: "Some Dio responses can have null statusCode in edge cases"
  if (code == null) {
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'HTTP status code is null',
    );
  }

  if (code >= 200 && code < 300) {
    return ResponseAsyncValue(
      success: true,
      isInitiated: true,
      data: null,
      message: successMessage,
    );
  }

  return ResponseAsyncValue(
    success: false,
    isInitiated: true,
    data: null,
    message: '${failureMessagePrefix ?? 'Request failed'} ($code)',
  );
}

ResponseAsyncValue mapExceptionToAsyncValue(Object e, {String? prefix}) {
  debugPrint('REST adapter error: $e');
  return ResponseAsyncValue(
    success: false,
    isInitiated: true,
    data: null,
    message: prefix == null ? e.toString() : '$prefix: $e',
  );
}

/// Generic REST batch executor for iDempiere.
/// POST /api/v1/batch?transaction=true
Future<Response<dynamic>> batchDataByRESTAPI({
  required List<Map<String, dynamic>> operations,
  required WidgetRef ref,
  bool transaction = true,
}) async {
  final dio = await DioClient.create();

  try {
    final String url = "/api/v1/batch?transaction=${transaction ? 'true' : 'false'}";
    debugPrint('batchDataByRESTAPI $url');
    debugPrint('batchDataByRESTAPI ops=${operations.length}');

    final response = await dio.post(url, data: operations);

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      return response;
    }

    throw Exception('REST batch failed: ${response.statusCode}');
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }
}



Future<ResponseAsyncValue> updateDataByRESTAPIBatchResponseAsyncValue({
  required String modelName,
  required List<int?> ids,
  required List<Map<String, dynamic>> dataList,
  required WidgetRef ref,
  String successMessage = 'Updated successfully',

  // ---- Optional second batch group ----
  String? modelName2,
  List<int?>? ids2,
  List<Map<String, dynamic>>? dataList2,
  String? successMessage2,
}) async {
  // English comment: "Validate first group"
  if (ids.isEmpty) {
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'No IDs provided for batch update ($modelName)',
    );
  }

  if (ids.length != dataList.length) {
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'IDs count does not match dataList count ($modelName)',
    );
  }

  for (final id in ids) {
    if (id == null || id <= 0) {
      return ResponseAsyncValue(
        success: false,
        isInitiated: true,
        data: null,
        message: 'Invalid ID for batch update ($modelName): $id',
      );
    }
  }

  // English comment: "Validate second group only if provided"
  final bool hasSecondGroup =
      modelName2 != null || ids2 != null || dataList2 != null;

  if (hasSecondGroup) {
    if (modelName2 == null || ids2 == null || dataList2 == null) {
      return ResponseAsyncValue(
        success: false,
        isInitiated: true,
        data: null,
        message: 'Second batch group is incomplete (modelName2/ids2/dataList2 required)',
      );
    }

    if (ids2.isEmpty) {
      return ResponseAsyncValue(
        success: false,
        isInitiated: true,
        data: null,
        message: 'No IDs provided for batch update ($modelName2)',
      );
    }

    if (ids2.length != dataList2.length) {
      return ResponseAsyncValue(
        success: false,
        isInitiated: true,
        data: null,
        message: 'IDs count does not match dataList count ($modelName2)',
      );
    }

    for (final id in ids2) {
      if (id == null || id <= 0) {
        return ResponseAsyncValue(
          success: false,
          isInitiated: true,
          data: null,
          message: 'Invalid ID for batch update ($modelName2): $id',
        );
      }
    }
  }

  try {
    // English comment: "Build iDempiere batch operations"
    final ops = <Map<String, dynamic>>[];

    // ----- Group 1 -----
    for (var i = 0; i < ids.length; i++) {
      final id = ids[i]!;
      final body = dataList[i];

      final op = {
        "method": "PUT",
        // According to batch manual: use singular "model"
        "path": "v1/model/$modelName/$id",
        "body": body,
      };

      debugPrint('Batch[1] op $i -> $op');
      ops.add(op);
    }

    // ----- Group 2 (optional) -----
    if (hasSecondGroup) {
      for (var i = 0; i < ids2!.length; i++) {
        final id = ids2[i]!;
        final body = dataList2![i];

        final op = {
          "method": "PUT",
          "path": "v1/model/$modelName2/$id",
          "body": body,
        };

        debugPrint('Batch[2] op $i -> $op');
        ops.add(op);
      }
    }

    debugPrint('Batch payload total ops=${ops.length}');
    debugPrint('Batch payload: $ops');

    final Response response = await batchDataByRESTAPI(
      operations: ops,
      ref: ref,
      transaction: true,
    );

    final code = response.statusCode;

    if (code != null && code >= 200 && code < 300) {
      // English comment: "Single success response for both groups (transaction=true)"
      final msg2 = hasSecondGroup ? (successMessage2 ?? ' + Group2 updated') : '';
      return ResponseAsyncValue(
        success: true,
        isInitiated: true,
        data: response.data,
        message: '$successMessage$msg2',
      );
    }

    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'Batch update failed (code: $code)',
    );
  } catch (e) {
    debugPrint('updateDataByRESTAPIBatchResponseAsyncValue error: $e');
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: e.toString(),
    );
  }
}


Future<ResponseAsyncValue> executeBatchOpsResponseAsyncValue({
  required List<Map<String, dynamic>> ops,
  required WidgetRef ref,
  String successMessage = 'Batch executed',
}) async {
  try {
    // English comment: "Debug entire payload"
    debugPrint('Batch total ops=${ops.length}');
    debugPrint('Batch payload: $ops');

    final response = await batchDataByRESTAPI(
      operations: ops,
      ref: ref,
      transaction: true,
    );

    final code = response.statusCode;
    if (code != null && code >= 200 && code < 300) {
      return ResponseAsyncValue(
        success: true,
        isInitiated: true,
        data: response.data,
        message: successMessage,
      );
    }

    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: 'Batch failed status=$code',
    );
  } catch (e) {
    debugPrint('executeBatchOpsResponseAsyncValue error: $e');
    return ResponseAsyncValue(
      success: false,
      isInitiated: true,
      data: null,
      message: e.toString(),
    );
  }
}

