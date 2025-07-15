import 'dart:ui';


import '../../../../../config/theme/app_theme.dart';
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
  static double width = 0;
  static int listLength = 0;
  static List<SqlDataMovementLine> newSqlDataMovementLines = <SqlDataMovementLine>[];
  static SqlDataMovement newSqlDataMovement = SqlDataMovement();

  static bool createNewMovement = true;

}