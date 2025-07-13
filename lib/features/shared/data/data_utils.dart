
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../products/domain/idempiere/idempiere_product.dart';
import 'memory.dart';

class DataUtils {

  static Future<void> saveIdempiereProduct(IdempiereProduct product) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Memory.KEY_PRODUCT, json.encode(product.toJson()));
  }

  static Future<IdempiereProduct> getSavedIdempiereProduct() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String result = prefs.getString(Memory.KEY_PRODUCT) ?? '';
    if (result.isEmpty) {
      return IdempiereProduct();
    }
    return IdempiereProduct.fromJson(json.decode(result));
  }

  static Future<void> removeIdempiereProduct() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(Memory.KEY_PRODUCT);
  }

  static Future<void> saveScanAction(int action) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Memory.KEY_SCAN_ACTION, action);
  }

  static Future<int> getSavedScanAction() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int result = prefs.getInt(Memory.KEY_SCAN_ACTION) ?? 0;
    return result;
  }

  static Future<void> removeScanAction() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(Memory.KEY_SCAN_ACTION);
  }

  static scanLocatorToDialog(BuildContext context){

  }
}