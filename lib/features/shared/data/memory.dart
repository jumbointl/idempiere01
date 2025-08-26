import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';
import 'package:monalisa_app_001/features/products/domain/sql/sql_users_data.dart';

import '../../products/domain/idempiere/idempiere_movement.dart';
import 'messages.dart';

class Memory {
  static int DELAY_TO_REFRESH_PROVIDER_MILLISECOND = 1500;
  static const int  TOKEN_EXPIRE_MINUTES = 720;
  static const int REFRESH_TOKEN_EXPIRE_MINUTES = 1200;
  static const String APP_ENDPOINT_MODELS = '/api/v1/models';
  static bool isUseCameraToScan = false ;
  static String userName ='';
  static SqlUsersData sqlUsersData = SqlUsersData();

  //HANDLING SQL QUERY RESULT
  //RETURN IDEMPIERE OBJECT(id: x, name: Messages.y)
  //CAN DO SWITCH(resultObject.id)
  //INITIAL PROVIDER, THE STATE OBSERVER DOES NOTHING
  static const int INITIAL_STATE_ID = -1;
  //NOT FOUND, SUCCESSFUL SQL QUERY BUT NO DATA FOUND,
  static const int NOT_FOUND_ID = 0;
  //ERROR, SUCCESSFUL SQL QUERY BUT HTTP RESPONSE UNSUCCESSFUL, LIKE UNAUTHORIZED,
  static const int ERROR_ID = -2;
  //FOUND MORE THAN 1, SUCCESSFUL SQL QUERY BUT TOO MUCH RECORDS,
  static var TOO_MUCH_RECORDS_ID=-3;


  static final numberFormatter2Digit = NumberFormat.decimalPatternDigits
    (locale: 'es_PY',decimalDigits: 2);
  static final numberFormatter0Digit = NumberFormat.decimalPatternDigits
    (locale: 'es_PY',decimalDigits: 0);

  static String IMAGE_NO_IMAGE='assets/images/no_image.png';
  static String IMAGE_LOADING='assets/images/loading.png';
  static String IMAGE_SAMPLE_1='assets/images/sample_1_512.jpg';
  static String IMAGE_SAMPLE_2='assets/images/sample_2_512.jpg';
  static String IMAGE_HTTP_SAMPLE_1='https://firebasestorage.googleapis.com/v0/b/girasol-udemy-delivery-01.firebasestorage.app/o/assets%2Fsample%2Fhttp_sample_1_512.jpg?alt=media&token=c1612688-0e4b-45d7-a7a4-4dc7f85a72ae';
  static String IMAGE_HTTP_SAMPLE_2='https://firebasestorage.googleapis.com/v0/b/girasol-udemy-delivery-01.firebasestorage.app/o/assets%2Fsample%2Fhttp_sample_2_512.jpg?alt=media&token=5b9a2190-ff34-4ae9-85ee-187a9ec4588a';
  static bool isTestMode = true;

  static double SIZE_PRODUCT_IMAGE_WIDTH =140;
  static double SIZE_PRODUCT_IMAGE_HEIGHT =140;
  static const int SCAN_TO_FIND_BY_UPC =1;
  static const int SCAN_TO_INPUT_UPC =2;

  static IdempiereProduct idempiereProduct = IdempiereProduct(id:0);
  static String lastSearch = '';
  static String lastLocator = '';
  static AwesomeDialog? awesomeDialog;

  static const int ACTION_NO_ACTION =0;
  static const int ACTION_FIND_BY_UPC_SKU =1;
  static const int ACTION_UPDATE_UPC =2;
  static const int ACTION_CALL_UPDATE_PRODUCT_UPC_PAGE =3;
  static const int ACTION_FIND_BY_UPC_SKU_FOR_STORE_ON_HAND = 4;
  static const int ACTION_GET_LOCATOR_TO_VALUE = 5;
  static const int ACTION_FIND_MOVEMENT_BY_ID=6;
  static const int ACTION_GET_LOCATOR_FROM_VALUE=7;



  static const int UPC_EXITS = -1;



  static const String KEY_PRODUCT_FROM_SEARCH = 'product_from_search';
  static const String KEY_PRODUCT_FROM_UPDATE = 'product_from_update';
  static const String KEY_PRODUCT = 'product';

  static String KEY_SCAN_ACTION='scan_action';

  static const String IDEMPIERE_DOC_TYPE_DRAFT = 'DR';

  static const int TYPE_DIALOG_SEARCH = 1;
  static const int TYPE_DIALOG_HISTOY = 2;

  static const String COMMAND_TO_GET_ALL_WAREHOUSES='0';

  static const int PAGE_INDEX_MULTIPLE =201;
  static const int PAGE_INDEX_SEARCH=2;
  static const int PAGE_INDEX_HEARDER_VIEW=1;
  static const int PAGE_INDEX_STORE_ON_HAND=0;

  static const int PAGE_INDEX_CREATE_STORE_ON_HAND = 13;
  static const int PAGE_INDEX_STORE_ON_HAND_2=14;
  static const int PAGE_INDEX_MOVEMENTE_CREATE_SCREEN=15;
  static const int PAGE_INDEX_FIND_LOCATOR_SCREEN=16;
  static const int PAGE_INDEX_FIEND_LOCATOR_BY_DEFAULT_WAREHOUSE_SCREEN=17;
  static const int PAGE_INDEX_UPDATE_UPC_SCREEN = 18;
  static const int PAGE_INDEX_MOVEMENTE_SCREEN=0;
  static const int PAGE_INDEX_NO_REQUERED_SCAN_SCREEN=200;
  static const int PAGE_INDEX_UNSORTED_STORAGE_ON_HAND=20;




  static int pageFromIndex =0;


















  static bool canConformMovement(IdempiereMovement movement){
    if(movement.docStatus!= null && movement.docStatus!.id !=null
        && movement.docStatus!.id?.toUpperCase() == Memory.IDEMPIERE_DOC_TYPE_DRAFT){
      return true ;
    }
    return false;
  }








  static void setImageSize(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    double parameter = 300;
    double originalSize = 140;
    double r0 = h/parameter;
    double r1 = w/parameter;
    double r = r0 > r1 ? r1 : r0;
    SIZE_PRODUCT_IMAGE_WIDTH = originalSize*r;
    SIZE_PRODUCT_IMAGE_HEIGHT = originalSize*r;

  }


  static String getDescriptionFromApp(){
    String description = '${Messages.APP_DESCRIPTION} $userName';
    return description;
  }








}