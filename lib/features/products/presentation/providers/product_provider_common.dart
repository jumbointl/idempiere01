import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_providers.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/products_scan_notifier.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../../shared/infrastructure/errors/custom_error.dart';
import '../../domain/idempiere/idempiere_product.dart';

final scanStateNotifierProvider = StateNotifierProvider.autoDispose<ProductsScanNotifier, List<IdempiereProduct>>((ref) {
  return ProductsScanNotifier(ref);

});


final scannedCodeTimesProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final isScanningProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final isScanningFromDialogProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final usePhoneCameraToScanProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final usePhoneCameraToScanProvider2 = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final productSKUProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});


final productIdProvider = StateProvider.autoDispose<int>((ref) {
  return 0;
});

final cameraScanBarcodeDataProvider = StateProvider<String?>((ref) => null);
final isDialogShowedProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final idempiereLocatorToProvider = StateProvider.autoDispose<IdempiereLocator>((ref) {
  return IdempiereLocator(id:-1,value: Messages.EMPTY);
});

final findLocatorToProvider = FutureProvider.autoDispose<IdempiereLocator>((ref) async {
  final String? scannedCode = ref.watch(scannedLocatorToProvider).toUpperCase();
  if(scannedCode==null || scannedCode=='') return IdempiereLocator(id:-1,value: Messages.EMPTY);

  String searchField ='Value';


  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/m_locator?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');

    final response = await dio.get(url);
    ref.read(isDialogShowedProvider.notifier).update((state) => false);
    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereLocator>.fromJson(response.data, IdempiereLocator.fromJson);

      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        if(productsList.length==1){
          ref.watch(idempiereLocatorToProvider.notifier).state = productsList[0];
        } else {
          ref.watch(idempiereLocatorToProvider.notifier).state = IdempiereLocator(id:0);
        }


        return productsList[0];

      } else {
        ref.watch(idempiereLocatorToProvider.notifier).state = IdempiereLocator(id:0);
        return IdempiereLocator(value: Messages.NOT_FOUND, name: scannedCode,id: 0);
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