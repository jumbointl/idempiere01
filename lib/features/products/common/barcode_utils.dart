

import 'package:flutter/material.dart';
import 'package:mofilo_barcode_verifier/mofilo_barcode_verifier.dart';
bool isAllDigits(String s) => RegExp(r'^\d+$').hasMatch(s);
bool isValidEAN13(String ean) {
  // 1. Validar longitud
  debugPrint('isValidEAN13: $ean');
  if (ean.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(ean)) {
    return false;
  }
  final verifier = BarcodeVerifier();
  final result = verifier.verify(ean);
  if(result.isValid && result.barcodeType ==  BarcodeType.ean13){
    debugPrint('isValidEAN13: true => $ean');
    return true;
  }


  return false;
}
bool isValidEAN8(String ean) {
  if (ean.length != 8 || !isAllDigits(ean)) return false;
  debugPrint('isValidEAN8: $ean');
  if (ean.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(ean)) {
    return false;
  }
  final verifier = BarcodeVerifier();
  final result = verifier.verify(ean);
  if(result.isValid && result.barcodeType ==  BarcodeType.ean8){
    debugPrint('isValidEAN8: true => $ean');
    return true;
  }


  return false;
}

List<String> getTypeOfBarcodeTspl(String barcodesToPrint) {

  if (barcodesToPrint.length == 12) {
    String newBarcodesToPrint = '0$barcodesToPrint';
    if (isValidEAN13(newBarcodesToPrint)) {
      return ['EAN13', newBarcodesToPrint];
    }
  } else if (barcodesToPrint.length == 13) {
    if (isValidEAN13(barcodesToPrint)) {
      return ['EAN13', barcodesToPrint];
    }
  }
  return ['128', barcodesToPrint]; // Default or fallback
}