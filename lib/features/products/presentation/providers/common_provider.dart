import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/config/constants/roles_app.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_printer/riverpod_printer.dart';
import '../../../m_inout/presentation/providers/m_in_out_providers.dart';
import '../../../printer/models/mo_printer.dart';
import '../../../printer/models/printer_select_models.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_locator.dart';
import '../../domain/idempiere/inventory_and_lines.dart';
import '../../domain/idempiere/movement_and_lines.dart';
import '../../domain/idempiere/response_async_value.dart';
import '../../domain/models/ftpconfig.dart';
import '../screens/movement/provider/new_movement_provider.dart';
import 'actions/find_locator_to_action_provider.dart';
import 'locator_provider.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
      (ref) => throw UnimplementedError(),
);
// El Notifier que gestiona el estado del String
class SharedStringNotifier extends StateNotifier<String?> {
  final SharedPreferences sharedPreferences;
  static const String key = 'username';

  SharedStringNotifier(this.sharedPreferences) : super(sharedPreferences.getString(key));

  // Método para guardar el String
  Future<void> saveString(String value) async {
    await sharedPreferences.setString(key, value);
    state = value; // Actualiza el estado para notificar a los oyentes
  }

  // Método para eliminar el String
  Future<void> deleteString() async {
    await sharedPreferences.remove(key);
    state = null; // Actualiza el estado para notificar a los oyentes
  }
}

// El StateNotifierProvider que expone el Notifier y el estado
final usernameProvider = StateNotifierProvider<SharedStringNotifier, String?>(
      (ref) {
    final sharedPrefs = ref.watch(sharedPreferencesProvider);
    return SharedStringNotifier(sharedPrefs);
  },
);

final inputStringProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});



final lastPrinterProvider = StateProvider<MOPrinter?>((ref) {
  return null;
});

final directPrintWithLastPrinterProvider = StateProvider<bool>((ref) {
  return false;
});

final isPrintingProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final isCupsPrintingProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final initializingProvider = StateProvider<bool>((ref) => false);
/// 'ALL', 'IN', 'OUT', 'SWAP'
final inOutFilterProvider = StateProvider<String>((ref) => 'ALL');

final colorMovementDocumentTypeProvider = StateProvider.autoDispose<Color?>((ref) {
  return null;
});

final allowScrollFabProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final canShowCreateLineBottomBarForInventoryProvider = Provider.autoDispose<bool>((ref) {
  bool b = RolesApp.appInventoryComplete;
  if(!b) return false;

  final qty = ref.watch(quantityToMoveProvider);          // double

  final isDialogShowed = ref.watch(isDialogShowedProvider);
  final isScanning = ref.watch(isScanningProvider);

  final hasQuantity = qty >= 0;
  //final locatorTo = ref.watch(selectedLocatorToProvider); // IdempiereLocator
  //final hasLocatorTo = locatorTo.id != null && locatorTo.id! > 0;
  bool result = hasQuantity && !isDialogShowed && !isScanning; //&& hasLocatorTo
  return result;
  //return hasQuantity;
});

final canShowCreateLineBottomBarProvider = Provider.autoDispose<bool>((ref) {
  bool b = RolesApp.appMovementComplete || RolesApp.appMovementconfirmComplete;
  if(!b) return false;

  final qty = ref.watch(quantityToMoveProvider);          // double
  final locatorTo = ref.watch(selectedLocatorToProvider); // IdempiereLocator
  final isDialogShowed = ref.watch(isDialogShowedProvider);
  final isScanning = ref.watch(isScanningProvider);

  final hasQuantity = qty > 0;
  final hasLocatorTo = locatorTo.id != null && locatorTo.id! > 0;
  bool result = hasQuantity && hasLocatorTo && !isDialogShowed && !isScanning;
  return result;
  //return hasQuantity;
});

final showScanFixedButtonProvider = Provider.family<bool, int>((ref, int actionScanTypeInt) {
  final currentAction = ref.watch(actionScanProvider);
  final result = currentAction == actionScanTypeInt;
  return result;
});

final movementLinesProvider = StateProvider.autoDispose
    .family<double, MovementAndLines>((ref, movement) {
  final length = movement.movementLines?.length ?? 0;
  final base = (length + 1) * 10;
  double base2 = (movement.movementLines?.isNotEmpty ?? false)
      ? movement.movementLines!
      .map((e) => e.line ?? 0)
      .reduce((a, b) => a > b ? a : b)
      : 0;
  base2 = base2 + 10;
  final result = base > base2 ? base : base2;

  return result.toDouble();
});

final inventoryLinesProvider = StateProvider.autoDispose
    .family<double, InventoryAndLines>((ref, inventory) {
      final length = inventory.inventoryLines?.length ?? 0;
      final base = (length + 1) * 10;
      double base2 = (inventory.inventoryLines?.isNotEmpty ?? false)
          ? inventory.inventoryLines!
          .map((e) => e.line ?? 0)
          .reduce((a, b) => a > b ? a : b)
          : 0;
      base2 = base2 + 10;
      final result = base > base2 ? base : base2;
      return result.toDouble();
    });





final quantityOfMovementAndScannedToAllowInputScannedQuantityProvider =
StateProvider<int>((ref) {
  final box = GetStorage();
  // Lê GetStorage — se não existir, devolve 3

  return box.read(KEY_QTY_ALLOW_INPUT) ?? 3;
});


final showBottomBarProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final movementDocumentProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final useNumberKeyboardProvider = StateProvider<bool>((ref) {
  return true;
});

final useScreenKeyboardProvider = StateProvider<bool>((ref) {
  return false;
});

final movementColorProvider =
Provider.family<Color, IdempiereLocator?>((ref, locatorFrom) {
  final asyncResult = ref.watch(findLocatorToProvider); // AsyncValue<ResponseAsyncValue>
  final selectedLocatorTo = ref.watch(selectedLocatorToProvider);

  // English: Default color while loading / invalid state
  final Color defaultColor = Colors.grey.shade200;

  return asyncResult.when(
    loading: () => defaultColor,
    error: (_, _) => defaultColor,
    data: (ResponseAsyncValue r) {
      // English: Resolve locatorTo with priority:
      // 1) user-selected locatorTo (if not initial)
      // 2) auto locator from async result (if success && data != null)
      // 3) fallback: initial (no valid locator)
      IdempiereLocator locatorToResolved;

      if (selectedLocatorTo.id != Memory.INITIAL_STATE_ID) {
        locatorToResolved = selectedLocatorTo;
      } else {
        // English: Only use auto data if provider succeeded and returned a locator
        final dynamic auto = (r.success == true) ? r.data : null;
        if (auto is IdempiereLocator) {
          locatorToResolved = auto;
        } else {
          // English: Not found / error => no locatorTo to compare
          locatorToResolved =
              IdempiereLocator(id: Memory.INITIAL_STATE_ID, value: Messages.FIND);
        }
      }

      final warehouseFrom = locatorFrom?.mWarehouseID;
      final warehouseTo = locatorToResolved.mWarehouseID;

      final warehouseID = warehouseFrom?.id ?? 0;
      final warehouseToID = warehouseTo?.id ?? 0;
      final org = locatorFrom?.aDOrgID?.id ?? 0;
      final orgTo = locatorToResolved.aDOrgID?.id ?? 0;

      // English: If we don't have both sides resolved, keep neutral
      if (warehouseID <= 0 || warehouseToID <= 0 || org <= 0 || orgTo <= 0) {
        return defaultColor;
      } else if (warehouseID == warehouseToID) {
        return Colors.green.shade200;
      } else if (org == orgTo) {
        return Colors.cyan.shade200;
      } else if (orgTo > 0) {
        return Colors.amber.shade200;
      }

      return Colors.white;
    },
  );
});

final movementCreateScreenTitleProvider = StateProvider<String>((ref) {
  final documentType = ref.watch(allowedMovementDocumentTypeProvider);
  if(documentType==Memory.MM_ELECTRONIC_DELIVERY_NOTE_ID){
    return Messages.MM_DELIVERY_NOTE;
  }
  int allowedWarehouseId = ref.watch(allowedWarehouseToProvider);
  int excludedWarehouseId = ref.watch(excludedWarehouseToProvider);
  if(allowedWarehouseId>0 && excludedWarehouseId==0){
    //same warehouse
    return Messages.MATERIAL_MOVEMENT;
  }
  if(allowedWarehouseId==0 && excludedWarehouseId>0){
    return Messages.MATERIAL_MOVEMENT_WITH_CONFIRM;

  }
  return Messages.MM_DELIVERY_NOTE;
});

final movementTypeProvider =
Provider.family<String, IdempiereLocator?>((ref, locatorFrom) {


  final locatorTo = ref.watch(selectedLocatorToProvider);
  final documentType = ref.watch(allowedMovementDocumentTypeProvider);
  if(documentType==Memory.MM_ELECTRONIC_DELIVERY_NOTE_ID){
    return Messages.MM_DELIVERY_NOTE;
  }



  final warehouseFrom = locatorFrom?.mWarehouseID;
  final warehouseTo   = locatorTo.mWarehouseID;

  final warehouseID   = warehouseFrom?.id ?? 0;
  final warehouseToID = warehouseTo?.id ?? 0;
  final org           = locatorFrom?.aDOrgID?.id ?? 0;
  final orgTo         = locatorTo.aDOrgID?.id ?? 0;




  String title = Messages.MOVEMENT_CREATE;

  if (warehouseID <= 0 || warehouseToID <= 0 || org <= 0 || orgTo <= 0) {
  } else if (warehouseID == warehouseToID) {
    title = Messages.MATERIAL_MOVEMENT;
  } else if (org == orgTo) {
    title = Messages.MATERIAL_MOVEMENT_WITH_CONFIRM;
  } else if (orgTo > 0) {
    title = Messages.MM_DELIVERY_NOTE;
  }

  return title;
});

final colorLocatorProvider = Provider<Color>((ref) {
  final locatorTo = ref.watch(selectedLocatorToProvider);

  final id = locatorTo.id ?? 0;

  if (id > 0) {
    return Colors.green.shade200;
  } else {
    return Colors.grey.shade200;
  }
});

final allowedMovementDocumentTypeProvider = StateProvider<int>((ref) {
  return -1;
});


final pageFromProvider = StateProvider<int>((ref) {
  return 0;
});

class NumButtonData {
  final String label;
  final int value;

  NumButtonData({required this.label, required this.value});
}

final enableScannerKeyboardProvider =  StateProvider<bool>((ref) => true);

final movementInSameWarehouseProvider =  StateProvider<bool>((ref) => false);
final labelProfilesProvider = StateProvider<List<LabelProfile>>((ref) => []);
final selectedLabelProfileIdProvider = StateProvider<String?>((ref) => null);
enum PrinterInputMode { scan, manual }

final printerInputModeProvider =
StateProvider<PrinterInputMode>((ref) => PrinterInputMode.scan);

final locatorScreenInputModeProvider =
StateProvider<PrinterInputMode>((ref) => PrinterInputMode.manual);

final selectedPrinterConfigProvider = StateProvider<PrinterConnConfig?>((ref) => null);
// Importa tu clase Memory aquí

final ftpConfigProvider = Provider<FtpConfig>((ref) {
  // Accedemos a tus variables estáticas de Memory
  return FtpConfig(
    host: Memory.printerFileFtpServer,
    user: Memory.printerFileFtpServerUserName,
    pass: Memory.printerFileFtpServerPassword,
    port: Memory.printerFileFtpServerPort,
  );
});
