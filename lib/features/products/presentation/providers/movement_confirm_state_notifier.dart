

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/idempiere/idempiere_product.dart';
import 'movement_provider_old.dart';

class MovementConfirmStateNotifier  extends StateNotifier<List<IdempiereProduct>>{
  static const int SQL_QUERY_CREATE =1;
  static const int SQL_QUERY_UPDATE =2;
  static const int SQL_QUERY_DELETE =3;
  static const int SQL_QUERY_SELECT =4;

  MovementConfirmStateNotifier(this.ref) : super([]);
  final Ref ref;

  void confirmMovement(int? id) {
    print('MovementConfirmStateNotifier confirmMovement $id');
    ref.read(movementIdForConfirmProvider.notifier).update((state) => id ?? -1);
  }


}


