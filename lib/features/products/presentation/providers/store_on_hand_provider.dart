

import 'package:flutter_riverpod/legacy.dart';

import '../../domain/idempiere/idempiere_storage_on_hande.dart';

final scrollToUpProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});



final storeOnHandProgressProvider =
StateProvider.autoDispose<double>((ref) => 0.0);

final resultOfSameWarehouseProvider = StateProvider<List<String>>((ref) {
  return [];
});

final unsortedStoreOnHandListProvider = StateProvider<List<IdempiereStorageOnHande>>((ref) {
  return [];
});


final showResultCardProvider = StateProvider.autoDispose<bool>((ref) {
  return true;
});

final searchByMOLIConfigurableSKUProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

final scannedSKUCodeProvider = StateProvider.autoDispose<String?>((ref) {
  return '';
});







