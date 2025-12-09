import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/product_provider_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../m_inout/presentation/providers/m_in_out_providers.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_locator.dart';
import '../../domain/idempiere/movement_and_lines.dart';
import '../screens/movement/printer/mo_printer.dart';
import '../screens/movement/provider/new_movement_provider.dart';
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

// Un StateProvider para almacenar el texto del TextField
final textProvider = StateProvider<String>((ref) => '');

// Un StateProvider para el resultado de la acción
final resultProvider = StateProvider<String>((ref) => 'Esperando...');

final scannerFocusNodeProvider = Provider<FocusNode>((ref) {
  final focusNode = FocusNode();
  // Limpia el FocusNode cuando el proveedor ya no se use
  ref.onDispose(focusNode.dispose);
  return focusNode;
});
final textControllerProvider = StateProvider<TextEditingController>((ref) {
  return TextEditingController();
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

final initializingProvider = StateProvider<bool>((ref) => false);
/// null = ALL, true = IN, false = OUT
//final inOutProvider = StateProvider<bool?>((ref) => null);
/// 'ALL', 'IN', 'OUT', 'SWAP'
final inOutFilterProvider = StateProvider<String>((ref) => 'ALL');



final colorMovementDocumentTypeProvider = StateProvider.autoDispose<Color?>((ref) {
  return null;
});

final allowScrollFabProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final canShowUnsortedBottomBarProvider = Provider.autoDispose<bool>((ref) {
  final qty = ref.watch(quantityToMoveProvider);          // double
  final locatorTo = ref.watch(selectedLocatorToProvider); // IdempiereLocator
  final isDialogShowed = ref.watch(isDialogShowedProvider);
  final isScanning = ref.watch(isScanningProvider);

  final hasQuantity = qty > 0;
  final hasLocatorTo = locatorTo.id != null && locatorTo.id! > 0;
  // ✅ Solo mostramos el bottomBar si:
  // - hay cantidad > 0
  // - hay locatorTo válido
  print('--------------canShowUnsortedBottomBa: $hasLocatorTo');
  bool result = hasQuantity && hasLocatorTo && !isDialogShowed && !isScanning;
  print('---------------result: $result');

  return result;
  //return hasQuantity;
});

final showScanFixedButtonProvider = Provider.family<bool, int>((ref, int actionScanTypeInt) {
  //final isDialogShowed = ref.watch(isDialogShowedProvider);
  //final isScanning = ref.watch(isScanningProvider);
  final currentAction = ref.watch(actionScanProvider);
  final result = currentAction == actionScanTypeInt;
  print('showScanFixedButtonProvider: $result');
  return result;
});

final movementLinesProvider = StateProvider.autoDispose
    .family<double, MovementAndLines>((ref, movement) {
  final length = movement.movementLines?.length ?? 0;
  final base = (length + 1) * 10;
  return base.toDouble();
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


final movementColorProvider =
Provider.family<Color, IdempiereLocator?>((ref, locatorFrom) {
  final asyncLocatorTo = ref.watch(findLocatorToProvider);
  final selectedLocatorTo = ref.watch(selectedLocatorToProvider);

  // Valor por defecto mientras carga / error
  Color defaultColor = Colors.grey.shade200;

  return asyncLocatorTo.when(
    loading: () {
      // mientras busca el locatorTo sugerido → gris clarito
      return defaultColor;
    },
    error: (error, stack) {
      // en error también algo neutro
      return defaultColor;
    },
    data: (autoLocatorTo) {
      // MISMA lógica que en getLocatorTo:
      final IdempiereLocator locatorTo =
      selectedLocatorTo.id != Memory.INITIAL_STATE_ID
          ? selectedLocatorTo
          : autoLocatorTo;

      final warehouseFrom = locatorFrom?.mWarehouseID;
      final warehouseTo   = locatorTo.mWarehouseID;

      final warehouseID   = warehouseFrom?.id ?? 0;
      final warehouseToID = warehouseTo?.id ?? 0;
      final org           = locatorFrom?.aDOrgID?.id ?? 0;
      final orgTo         = locatorTo.aDOrgID?.id ?? 0;

      if (warehouseID <= 0 || warehouseToID <= 0 || org <= 0 || orgTo <= 0) {
        return Colors.grey.shade200;
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

/*final movementColorProvider =
Provider.family<Color, IdempiereLocator?>((ref, locatorFrom) {
  final locatorTo = ref.watch(selectedLocatorToProvider);

  // locatorFrom é fixo — veio do widget
  final warehouseFrom = locatorFrom?.mWarehouseID;
  final warehouseTo   = locatorTo.mWarehouseID;

  final warehouseID   = warehouseFrom?.id ?? 0;
  final warehouseToID = warehouseTo?.id ?? 0;
  final org           = locatorFrom?.aDOrgID?.id ?? 0;
  final orgTo         = locatorTo.aDOrgID?.id ?? 0;

  Color color = Colors.white;

  if (warehouseID <= 0 || warehouseToID <= 0 || org <= 0 || orgTo <= 0) {
    color = Colors.grey.shade200;
  } else if (warehouseID == warehouseToID) {
    color = Colors.green.shade200;
  } else if (org == orgTo) {
    color = Colors.cyan.shade200;
  } else if (orgTo > 0) {
    color = Colors.amber.shade200;
  }

  return color;
});*/

final movementTypeProvider =
Provider.family<String, IdempiereLocator?>((ref, locatorFrom) {
  final locatorTo = ref.watch(selectedLocatorToProvider);

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
    title = Messages.MM_ELECTROCIC_REMITTANCE;
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