import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../config/http/dio_client.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../../shared/domain/entities/response_api.dart';
import '../../../domain/idempiere/idempiere_locator.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../common_provider.dart';
import '../locator_provider.dart';
import '../product_provider_common.dart';

final fireFindLocatorProvider = StateProvider<int>((ref) {
  return 0;
});

final scannedLocatorToProvider = StateProvider<String>((ref) {
  return '';
});
final findLocatorToProvider = FutureProvider<ResponseAsyncValue>((ref) async {
  final int counter = ref.watch(fireFindLocatorProvider);
  if(counter==0) return ResponseAsyncValue(success: false, isInitiated: false, data: null);

  final String scannedCode =
  ref.read(scannedLocatorToProvider).toUpperCase().trim();

  // English: Base result object
  final result = ResponseAsyncValue(
    success: false,
    isInitiated: false,
    data: null,
  );

  // English: If empty scan, return idle state
  if (scannedCode.isEmpty) {
    return result;
  }

  result.isInitiated = true;

  final int allowedDocumentTypeId =
  ref.read(allowedMovementDocumentTypeProvider);

  const String searchField = 'Value';
  const String idempiereModelName = 'm_locator';

  final int excludedLocatorId = ref.watch(actualLocatorFromProvider);
  final int allowedWarehouseId = ref.watch(allowedWarehouseToProvider);

  final int excludedWarehouseId = ref.read(excludedWarehouseToProvider);

  int allowedOrganizationId = 0;
  if (allowedDocumentTypeId == Memory.NO_MM_ELECTRONIC_DELIVERY_NOTE_ID) {
    allowedOrganizationId = Memory.sqlUsersData.aDOrgID?.id ?? 0;
  }

  // English: Helper to append searched value
  String withValue(String msg) => '$msg\n${Messages.VALUE} : $scannedCode';

  // English: Build "not found" message following requested rules
  String notFoundMessage() {
    print('notFoundMessage ');
    print('excludedLocatorId $excludedLocatorId');
    print('allowedWarehouseId $allowedWarehouseId');
    print('excludedWarehouseId $excludedWarehouseId');

    if (allowedWarehouseId > 0) {
      return '${Messages.NOT_FOUND}\n'
          '${Messages.FILETRED_BY_WAREHOUSE_TO}\n'
          '${Messages.VALUE} : $scannedCode';
    }
    if (excludedWarehouseId > 0) {
      return '${Messages.NOT_FOUND}\n'
          '${Messages.FILETRED_BY_WAREHOUSE_EXLUDED}\n'
          '${Messages.VALUE} :$scannedCode';
    }
    if (allowedOrganizationId > 0) {
      return '${Messages.NOT_FOUND}\n'
          '${Messages.FILETRED_BY_ORGANIZATION_TO}\n'
          '${Messages.VALUE} :$scannedCode';
    }
    return '${Messages.NOT_FOUND} : $scannedCode';
  }

  Dio dio = await DioClient.create();

  try {
    String url =
        "/api/v1/models/$idempiereModelName?\$expand=M_Warehouse_ID&\$filter=$searchField eq '$scannedCode'";

    // English: Exclude current locator (from)
    url = '$url AND M_Locator_ID neq $excludedLocatorId';

    // English: Apply filters (same logic as original)
    if (allowedWarehouseId > 0) {
      url = '$url AND M_Warehouse_ID eq $allowedWarehouseId';
    } else {
      if (excludedWarehouseId > 0) {
        url = '$url AND M_Warehouse_ID neq $excludedWarehouseId';
      }
      if (allowedOrganizationId > 0) {
        url = '$url AND AD_Org_ID eq $allowedOrganizationId';
      }
    }
    print(url);
    url = url.replaceAll(' ', '%20');
    print(url);
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      final responseApi = ResponseApi<IdempiereLocator>.fromJson(
        response.data,
        IdempiereLocator.fromJson,
      );

      // -------------------------
      // Found
      // -------------------------
      if (responseApi.records != null && responseApi.records!.isNotEmpty) {
        final IdempiereLocator locator = responseApi.records!.first;

        // English: Keep your delayed side effects
        ref.read(selectedLocatorToProvider.notifier).state = locator;
        ref.read(isScanningProvider.notifier).state = false;
        ref.read(isScanningLocatorToProvider.notifier).state = false;

        result.success = true;
        result.data = locator;
        result.message = withValue(Messages.OK);
        return result;
      }

      // -------------------------
      // Not found (requested: success=true, data=null)
      // -------------------------
      final msg = notFoundMessage();

      Future.delayed(const Duration(seconds: 1), () {
        ref.read(selectedLocatorToProvider.notifier).state = IdempiereLocator(
          id: Memory.NOT_FOUND_ID,
          value: msg,
        );
        ref.read(isScanningProvider.notifier).state = false;
        ref.read(isScanningLocatorToProvider.notifier).state = false;
      });

      result.success = true;
      result.data = null;
      result.message = msg;
      return result;
    }

    // -------------------------
    // Non-200 response => error (success=false)
    // -------------------------
    Future.delayed(const Duration(seconds: 1), () {
      ref.read(isScanningProvider.notifier).state = false;
      ref.read(isScanningLocatorToProvider.notifier).state = false;
      ref.read(selectedLocatorToProvider.notifier).state = IdempiereLocator(
        id: Memory.ERROR_ID,
        value: '${Messages.ERROR} $scannedCode 2',
      );
    });

    result.success = false;
    result.data = null;
    result.message = withValue('${Messages.ERROR} 2');
    return result;
  } on DioException catch (e) {
    // English: No throw, return ResponseAsyncValue error payload
    Future.delayed(const Duration(seconds: 1), () {
      ref.read(isScanningProvider.notifier).state = false;
      ref.read(isScanningLocatorToProvider.notifier).state = false;
      ref.read(selectedLocatorToProvider.notifier).state = IdempiereLocator(
        id: Memory.ERROR_ID,
        value: '${Messages.ERROR} $scannedCode 3',
      );
    });

    result.success = false;
    result.data = null;
    result.message = withValue('${Messages.ERROR} ${e.toString()}');
    return result;
  } catch (e) {
    Future.delayed(const Duration(seconds: 1), () {
      ref.read(isScanningProvider.notifier).state = false;
      ref.read(isScanningLocatorToProvider.notifier).state = false;
      ref.read(selectedLocatorToProvider.notifier).state = IdempiereLocator(
        id: Memory.ERROR_ID,
        value: '${Messages.ERROR} $scannedCode 4',
      );
    });

    result.success = false;
    result.data = null;
    result.message = withValue('${Messages.ERROR} 4');
    return result;
  }
});
