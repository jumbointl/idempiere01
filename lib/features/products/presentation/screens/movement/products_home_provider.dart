import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/http/dio_client.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../domain/idempiere/idempiere_product.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../../shared/domain/entities/response_api.dart';
import '../../../../shared/infrastructure/errors/custom_error.dart';



final productsHomeCurrentIndexProvider = StateProvider<int>((ref) => 0);

final movementsHomeCurrentIndexProvider = StateProvider<int>((ref) => 0);

final productsHomeIsLoadingProvider = StateProvider<bool>((ref) => false);

final productsHomeScannedCodeForSearchProvider = StateProvider.autoDispose<String?>((ref) {
  return '';
});

final productsHomeScannerActionProvider = StateProvider<int>((ref) => 0);


// for upc update
final productsHomeProductForUpcUpdateProvider = StateProvider.autoDispose<IdempiereProduct>((ref) {
  return IdempiereProduct(id:Memory.INITIAL_STATE_ID);
});

// for upc update
final productsHomeFindProductByUPCOrSKUProvider = FutureProvider.autoDispose<IdempiereProduct>((ref) async {
  final String? scannedCode = ref.watch(productsHomeScannedCodeForSearchProvider)?.toUpperCase();

  if(scannedCode==null || scannedCode=='') return IdempiereProduct(id:Memory.INITIAL_STATE_ID);
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

    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereProduct>.fromJson(response.data, IdempiereProduct.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        if(productsList.length==1){
          ref.read(productsHomeProductForUpcUpdateProvider.notifier).state = productsList[0];
        } else {
          ref.read(productsHomeProductForUpcUpdateProvider.notifier).state = IdempiereProduct(id:0);
        }


        return productsList[0];

      } else {
        ref.read(productsHomeProductForUpcUpdateProvider.notifier).state = IdempiereProduct(id:0);
        return IdempiereProduct(name: Messages.NOT_FOUND, uPC: scannedCode,id: Memory.NOT_FOUND_ID);
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