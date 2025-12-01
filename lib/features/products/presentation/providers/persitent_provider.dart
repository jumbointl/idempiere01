import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../domain/idempiere/idempiere_locator.dart';

final persistentLocatorToProvider = StateProvider<IdempiereLocator>((ref) {
  return IdempiereLocator(id:Memory.INITIAL_STATE_ID,value: Messages.FIND);
});


