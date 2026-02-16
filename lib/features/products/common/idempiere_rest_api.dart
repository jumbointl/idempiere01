import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/http/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../shared/infrastructure/errors/custom_error.dart';

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
    final response = await dio.delete(url,data: data);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return response;
    }

    throw Exception('REST delete failed ($modelName/$id): ${response.statusCode}');
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
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


