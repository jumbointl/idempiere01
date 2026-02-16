

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/actions/find_locator_to_action.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/actions/find_movement_by_id_action.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/actions/find_product_by_sku_name_action.dart';

import '../actions/create_movement_and_lines_action.dart';
import '../actions/create_movement_line_action.dart';
import '../actions/find_store_on_hand_by_upc_sku_action.dart';


final createMovementAndLinesActionProvider =
Provider.autoDispose<CrateMovementAndLinesAction>((ref) {
  return CrateMovementAndLinesAction(ref: ref);
});

final createMovementLineActionProvider =
Provider.autoDispose<CrateMovementLineAction>((ref) {
  return CrateMovementLineAction(ref: ref);
});

final findLocatorToActionProvider =
Provider.autoDispose<FindLocatorToAction>((ref) {
  return FindLocatorToAction(ref: ref);
});

final findMovementByIdActionProvider =
Provider.autoDispose<FindMovementByIdAction>((ref) {
  return FindMovementByIdAction(ref: ref);
});

final actionFindStoreOnHandByUpcSkuProvider =
Provider.autoDispose<FindStoreOnHandByUpcSkuAction>(
      (ref) => FindStoreOnHandByUpcSkuAction(ref: ref),
);

final actionFindProductBySkuNameProvider =
Provider.autoDispose<FindProductBySkuNameAction>(
      (ref) => FindProductBySkuNameAction(ref: ref),
);