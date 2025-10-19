import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_search_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_update_notifier.dart';
import 'package:monalisa_app_001/features/shared/data/memory.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_product.dart';

final newUPCToUpdateProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final dataToUpdateUPCProvider = StateProvider.autoDispose<List<String>>((ref) {
  return [];
});

final productUpdateStateNotifierProvider = StateNotifierProvider.autoDispose<ProductsUpdateNotifier, List<IdempiereProduct>>((ref) {
  return ProductsUpdateNotifier(ref);

});



final updateProductUPCProvider = FutureProvider.autoDispose<IdempiereProduct>((ref) async {
  List<String> dataToUpdate = ref.watch(dataToUpdateUPCProvider);

  if(dataToUpdate.isEmpty || dataToUpdate.length!=2){
    return IdempiereProduct(name: Messages.NO_DATA_INPUTED,id:0);
  }

  String id = dataToUpdate[0];
  final String newUPC = dataToUpdate[1] ;
  if(id == '' || int.tryParse(id)==null || int.tryParse(id) == 0) {
    return IdempiereProduct(name: Messages.ERROR_ID, uPC: newUPC, id:0);
  }
  if(newUPC=='') return IdempiereProduct(id:0);
  int? aux = int.tryParse(newUPC);
  if(aux==null){
    return IdempiereProduct(name: Messages.ERROR_UPC , uPC: newUPC,id:0);
  }
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/m_product?\$filter=upc eq '$newUPC'";
    url = url.replaceAll(' ', '%20');
    final responseAux = await dio.get(url);
    if (responseAux.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereProduct>.fromJson(responseAux.data, IdempiereProduct.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        return IdempiereProduct(name: Messages.UPC_ALREADY_EXISTS, uPC: newUPC,id: Memory.UPC_EXITS);
      }
    }

    url =
        "/api/v1/models/m_product/$id";
    final body = {'UPC': newUPC};
    final response = await dio.put(url, data: body);
    if (response.statusCode == 200) {
      if (response.data != null) {
        IdempiereProduct product = IdempiereProduct.fromJson(response.data);
        ref.watch(productForUpcUpdateProvider.notifier).state = product;
        return product;

      } else {
        return IdempiereProduct(name: Messages.ERROR_UPDATE_PRODUCT_UPC, uPC: newUPC,id: 0);
      }
    } else {
      throw Exception(
          '${Messages.ERROR_UPDATE_PRODUCT_UPC} $newUPC: ${response.statusCode}');

    }
  } on DioException catch (e) {
    final authDataNotifier = ref.read(authProvider.notifier);
    throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    throw Exception(e.toString());
  }

});