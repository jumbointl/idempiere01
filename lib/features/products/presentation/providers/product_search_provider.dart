import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_product.dart';


final productForUpcUpdateProvider = StateProvider.autoDispose<IdempiereProduct>((ref) {
  return IdempiereProduct(id:0);
});

final scannedCodeForSearchByUPCOrSKUProvider = StateProvider.autoDispose<String?>((ref) {
  return '';
});
final findProductByUPCOrSKUProvider = FutureProvider.autoDispose<IdempiereProduct>((ref) async {
  final String? scannedCode = ref.watch(scannedCodeForSearchByUPCOrSKUProvider)?.toUpperCase();
  print('-----------------------------------search addBarcodeByUPCOrSKUForSearch $scannedCode');
  if(scannedCode==null || scannedCode=='') return IdempiereProduct(id:0);
  int? aux = int.tryParse(scannedCode);
  String searchField ='upc';
  if(aux==null){
    searchField = 'sku';
  }

  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/m_product?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);
    print(response.statusCode);
    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereProduct>.fromJson(response.data, IdempiereProduct.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        print(responseApi.records![0].toJson());
        if(productsList.length==1){
          ref.read(productIdProvider.notifier).state = productsList[0].id ?? 0;
        } else {
          ref.read(productIdProvider.notifier).state = productsList[0].id ?? 0;
        }
        print(ref.read(productIdProvider.notifier).state);

        return productsList[0];

      } else {
        ref.read(productIdProvider.notifier).state =  0;
        return IdempiereProduct(name: Messages.NOT_FOUND, uPC: scannedCode,id: 0);
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