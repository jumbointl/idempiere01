import 'dart:ui';


import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../domain/idempiere/idempiere_storage_on_hande.dart';
import '../../../domain/sql/sql_data_movement.dart';
import '../../../domain/sql/sql_data_movement_line.dart';

class MemoryProducts {
  static IdempiereStorageOnHande storage =IdempiereStorageOnHande();
  static int index=-1;
  static final Color colorSameWarehouse = themeColorSuccessfulLight;
  static final Color colorDifferentWarehouse = themeColorGrayLight;
  static final double fontSizeMedium = 16;
  static final double fontSizeLarge = 22;
  static double width = double.infinity;
  static int listLength = 0;
  static List<SqlDataMovementLine> newSqlDataMovementLinesToCreate = <SqlDataMovementLine>[];
  static SqlDataMovementLine newSqlDataMovementLineToCreate = SqlDataMovementLine();
  static SqlDataMovement newSqlDataMovementToCreate = SqlDataMovement();

  static bool createNewMovement = true;
  static IdempiereLocator locatorFrom = IdempiereLocator(id: Memory.INITIAL_STATE_ID);
  static IdempiereLocator locatorTo = IdempiereLocator(id: Memory.INITIAL_STATE_ID);
  static SqlDataMovementLine lastMovementLine =SqlDataMovementLine();
  static SqlDataMovement lastMovement = SqlDataMovement();
  static List<SqlDataMovementLine> createdSqlDataMovementLines = <SqlDataMovementLine>[];

  static int actionScan = 0;


}