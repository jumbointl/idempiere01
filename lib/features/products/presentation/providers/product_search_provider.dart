import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/common/idempiere_rest_api.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/actions/find_product_by_sku_name_action_provider.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_product.dart';


final productForUpcUpdateProvider = StateProvider<IdempiereProduct>((ref) {
  return IdempiereProduct(id:0);
});

final fireSearchByUPCOrSKUProvider = StateProvider<int>((ref) {
  return 0;
});

final scannedCodeForSearchByUPCOrSKUProvider = StateProvider<String?>((ref) {
  return '';
});
final findProductByUPCOrSKUProvider = FutureProvider.autoDispose<List<IdempiereProduct>>((ref) async {
  final int counter = ref.watch(fireSearchByUPCOrSKUProvider);
  if(counter==0) return [];
  final String? scannedCode = ref.read(scannedCodeForSearchByUPCOrSKUProvider)?.toUpperCase();
  if(scannedCode==null || scannedCode=='') return [];
  final searchMode = ref.read(productSearchModeProvider);

  String searchField ='upc';
  String url =
      "/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'";
  switch(searchMode){

    case ProductSearchMode.upc:
      searchField ='upc';
      url ="/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'";
      break;
    case ProductSearchMode.sku:
      searchField ='sku';
      String filter = makeFilterWithContains(searchField: searchField, searchValue: scannedCode);
      url =  "/api/v1/models/m_product?\$filter=$filter&top=20";
      break;
    case ProductSearchMode.name:
      searchField ='name';
      String filter = makeFilterWithContains(searchField: searchField, searchValue: scannedCode);
      url =  "/api/v1/models/m_product?\$filter=$filter&top=20";
      break;
  }
  print(url);

  Memory.lastSearch = scannedCode;
  Dio dio = await DioClient.create();
  try {

    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereProduct>.fromJson(response.data, IdempiereProduct.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        if(productsList.length==1){
          ref.read(productForUpcUpdateProvider.notifier).state = productsList[0];
        } else {
          ref.invalidate(productForUpcUpdateProvider);
        }

        return productsList;

      } else {
        return [];
      }
    } else {
      throw Exception(
          'Error al obtener la lista de $scannedCode: ${response.statusCode}');
    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }

});




