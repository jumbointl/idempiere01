import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_product.dart';

class Memory {
  static int DELAY_TO_REFRESH_PROVIDER_MILLISECOND = 1500;
  static const int  TOKEN_EXPIRE_MINUTES = 720;
  static const int REFRESH_TOKEN_EXPIRE_MINUTES = 1200;
  static bool isUseCameraToScan = false ;

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
/*  // app routes
  static const String PAGE_UPDATE_PRODUCT_UPC = '/product/updateProductUPC';
  static const String PAGE_HOME = '/home';
  static const String PAGE_PRODUCT_SEARCH = '/product/search';
  static const String PAGE_PRODUCT_STORE_ON_HAND = '/product/storeOnHand';
  static const String PAGE_PRODUCT_SEARCH_UPDATE_UPC = '/product/searchUpdateProductUPC';*/
  //
  static const int UPC_EXITS = -1;



  static const String KEY_PRODUCT_FROM_SEARCH = 'product_from_search';
  static const String KEY_PRODUCT_FROM_UPDATE = 'product_from_update';
  static const String KEY_PRODUCT = 'product';

  static String KEY_SCAN_ACTION='scan_action';

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











}