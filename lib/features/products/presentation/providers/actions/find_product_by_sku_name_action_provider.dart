import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/common/idempiere_rest_api.dart';

import '../../../../../config/http/dio_client.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../../shared/domain/entities/response_api.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../../domain/idempiere/response_async_value.dart';

enum ProductSearchMode { upc, sku, name }

final productSearchModeProvider =
StateProvider<ProductSearchMode>((ref) => ProductSearchMode.upc);



final fireSearchBySKUNameProvider = StateProvider<int>((ref) {
  return 0;
});

final scannedCodeForSearchBySKUNameProvider = StateProvider<String>((ref) {
  return '';
});
final findProductBySKUNameProvider = FutureProvider.autoDispose<ResponseAsyncValue>((ref) async {
  final int counter = ref.watch(fireSearchBySKUNameProvider);
  if(counter<=0) return ResponseAsyncValue() ;
  final String scannedCode = ref.read(scannedCodeForSearchBySKUNameProvider).toUpperCase();
  if(scannedCode=='') return ResponseAsyncValue();

  final searchMode = ref.read(productSearchModeProvider);
  String searchField ='sku';
  if (searchMode == ProductSearchMode.upc) {
    return ResponseAsyncValue(isInitiated: true,success: false,message: Messages.ERROR_SEARCH_BY_UPC);
  } else if (searchMode == ProductSearchMode.sku) {
    searchField = 'sku';
  } else if (searchMode == ProductSearchMode.name) {
    searchField = 'name';
  }
  Memory.lastSearch = scannedCode;

  Dio dio = await DioClient.create();
  ResponseAsyncValue asyncValue=ResponseAsyncValue(
    isInitiated: true,
  );
  final filter = makeFilterWithContains(searchField: searchField, searchValue: scannedCode);
  debugPrint('findProductBySKUNameProvider filter: $filter');
  
  try {
    String url =
        "/api/v1/models/m_product?\$filter=$filter&\$top=20";
    debugPrint(url);
    url = url.replaceAll(' ', '%20');
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereProduct>.fromJson(response.data, IdempiereProduct.fromJson);

      asyncValue.success = true;
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        asyncValue.data = productsList;


      }
      return asyncValue;
    } else {
      asyncValue.message = 'Error al obtener la lista de $scannedCode: ${response.statusCode}';
      asyncValue.success = false;
      return asyncValue;

    }
  } on DioException catch (e) {
    asyncValue.message = 'Error al obtener la lista de $scannedCode: ${e.toString()}';
    asyncValue.success = false;
    return asyncValue;
  } catch (e) {
    asyncValue.message = e.toString();
    asyncValue.success = false;
    return asyncValue;
  } finally{

  }

});