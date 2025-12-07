import 'dart:ui';


import 'package:monalisa_app_001/features/products/domain/idempiere/movement_and_lines.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/product_with_stock.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
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

  //for put away movement
  static SqlDataMovementLine newSqlDataMovementLineToCreate = SqlDataMovementLine();
  static SqlDataMovement newSqlDataMovementToCreate = SqlDataMovement();
  //for movementline and print
  static MovementAndLines movementAndLines = MovementAndLines(user: Memory.sqlUsersData);
  //static IdempiereLocator lastSavedLocatorFrom = movementAndLines.lastLocatorFrom ?? IdempiereLocator(id: Memory.INITIAL_STATE_ID);

  // to do  delete this variables -- begin

  static SqlDataMovementLine lastSqlDataMovementLine =SqlDataMovementLine();
  static SqlDataMovement lastSqlDataMovement = SqlDataMovement();


  //static bool isMovementSearched=false;
  static int delayOnSwitchPageInSeconds=2;
  static String lastSearchMovementText ='';

  static bool lastUsePhoneCameraState =false;

  static ProductWithStock? productWithStock;

  static String getDocumentStatusById(String documentStatus) {
    if (documentStatus == 'CO') {
      return Messages.COMPLETED;
    } else if (documentStatus == 'CA') {
      return Messages.CANCELED;
    } else if (documentStatus == 'RE') {
      return Messages.RETURNED;
    } else if (documentStatus == 'DE') {
      return Messages.DELIVERED;
    } else if (documentStatus == 'DR') {
      return Messages.DRAF;
    } else if (documentStatus == 'IP') {
      return Messages.IN_PROGRESS;

    } else {
      return documentStatus;
    }

  }



}