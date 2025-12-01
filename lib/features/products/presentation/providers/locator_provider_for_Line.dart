import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/persitent_provider.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';

import '../../../../config/http/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/domain/entities/response_api.dart';
import '../../domain/idempiere/idempiere_locator.dart';


final isScanningLocatorToForLineProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final isLocatorScreenShowedForLineProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final scannedLocatorToForLineProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final scannedLocatorFromForLineProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final findLocatorToForLineProvider = FutureProvider<IdempiereLocator>((ref) async {
  final String scannedCode = ref.watch(scannedLocatorToForLineProvider).toUpperCase().trim();
  if(scannedCode=='') {
    ref.read(isScanningForLineProvider.notifier).state =false;
    ref.read(isScanningLocatorToForLineProvider.notifier).state =false;
    return IdempiereLocator(id:Memory.INITIAL_STATE_ID,value: Messages.FIND);
  }

  String searchField ='Value';
  String idempiereModelName ='m_locator';
  Dio dio = await DioClient.create();
  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$filter=$searchField eq '$scannedCode'";
    url = url.replaceAll(' ', '%20');
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      final responseApi =
      ResponseApi<IdempiereLocator>.fromJson(response.data, IdempiereLocator.fromJson);
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final productsList = responseApi.records!;
        ref.read(persistentLocatorToProvider.notifier).state = productsList[0];
        ref.read(isScanningForLineProvider.notifier).state =false;

        ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
        return productsList[0];
      } else {
        ref.read(isScanningProvider.notifier).state =false;
        ref.read(persistentLocatorToProvider.notifier).state = IdempiereLocator(id:Memory.NOT_FOUND_ID,value: '${Messages.NOT_FOUND} $scannedCode'  );
        ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
        return IdempiereLocator(value: Messages.NOT_FOUND, name: scannedCode,id: Memory.NOT_FOUND_ID);

      }
    } else {
      ref.read(isScanningProvider.notifier).state =false;
      ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
      ref.read(persistentLocatorToProvider.notifier).state =
          IdempiereLocator(id:Memory.ERROR_ID,
          value: '${Messages.ERROR} $scannedCode');
      return IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);

    }
  } on DioException {
    final authDataNotifier = ref.read(authProvider.notifier);
    ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
    ref.read(isScanningProvider.notifier).state =false;
    ref.read(persistentLocatorToProvider.notifier).state =
        IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);
    return IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);
    //throw CustomErrorDioException(e, authDataNotifier);
  } catch (e) {
    //throw Exception(e.toString());
    ref.read(isScanningLocatorToForLineProvider.notifier).state = false;
    ref.read(isScanningProvider.notifier).state =false;
    ref.read(persistentLocatorToProvider.notifier).state =IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);
    return IdempiereLocator(id:Memory.ERROR_ID,value: Messages.ERROR);
  }

});







