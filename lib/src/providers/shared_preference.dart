import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service class to manage key-value data using SharedPreferences.
class SharedPrefsService {
  static SharedPreferences? _prefs;

  /// Initializes the SharedPreferences instance if not already initialized.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensures SharedPreferences is ready for use.
  Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Stores a [String] value.
  Future<bool> setString(String key, String value) async {
    final prefs = await _ensurePrefs();
    return prefs.setString(key, value);
  }

  /// Stores a [bool] value.
  Future<bool> setBool(String key, bool value) async {
    final prefs = await _ensurePrefs();
    return prefs.setBool(key, value);
  }

  /// Stores an [int] value.
  Future<bool> setInt(String key, int value) async {
    final prefs = await _ensurePrefs();
    return prefs.setInt(key, value);
  }

  /// Retrieves a [String] value.
  Future<String?> getString(String key) async {
    final prefs = await _ensurePrefs();
    return prefs.getString(key);
  }

  /// Retrieves a [bool] value.
  Future<bool?> getBool(String key) async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(key);
  }

  /// Retrieves an [int] value.
  Future<int?> getInt(String key) async {
    final prefs = await _ensurePrefs();
    return prefs.getInt(key);
  }

  /// Checks if the given [key] exists.
  Future<bool> containsKey(String key) async {
    final prefs = await _ensurePrefs();
    return prefs.containsKey(key);
  }

  /// Gets all stored keys.
  Future<Set<String>> getKeys() async {
    final prefs = await _ensurePrefs();
    return prefs.getKeys();
  }

  /// Removes a stored value by [key].
  Future<bool> remove(String key) async {
    final prefs = await _ensurePrefs();
    return prefs.remove(key);
  }

  /// Clears all stored values.
  Future<bool> clear() async {
    final prefs = await _ensurePrefs();
    return prefs.clear();
  }
}

/// Riverpod provider for the SharedPrefsService.
final sharedPrefsProvider = Provider<SharedPrefsService>((ref) {
  return SharedPrefsService();
});
