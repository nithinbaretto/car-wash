import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultProductionUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://asia-south1-car-wash-5d9ce.cloudfunctions.net/api',
  );

  static const String emulatorHostAndroid =
      'http://10.0.2.2:5002/car-wash-5d9ce/asia-south1/api';
  static const String emulatorHostLocal =
      'http://127.0.0.1:5002/car-wash-5d9ce/asia-south1/api';

  static const String firebaseApiKey =
      'AIzaSyDCNoy0nebG4tpaO01bO4pnjot0eqtfWDM';
  static const String firebaseProjectId = 'car-wash-5d9ce';
  static const String firebaseAuthDomain = 'car-wash-5d9ce.firebaseapp.com';

  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyUseEmulator = 'api_use_emulator';

  static String _currentBaseUrl = defaultProductionUrl;
  static bool _useEmulator = false;

  static String get baseUrl => _currentBaseUrl;
  static bool get useEmulator => _useEmulator;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useEmulator = prefs.getBool(_keyUseEmulator) ?? false;
      final savedUrl = prefs.getString(_keyBaseUrl);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _currentBaseUrl = savedUrl;
      } else if (_useEmulator) {
        _currentBaseUrl = defaultTargetPlatform == TargetPlatform.android
            ? emulatorHostAndroid
            : emulatorHostLocal;
      } else {
        _currentBaseUrl = defaultProductionUrl;
      }
    } catch (_) {
      _currentBaseUrl = defaultProductionUrl;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    _currentBaseUrl = url.endsWith('/')
        ? url.substring(0, url.length - 1)
        : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _currentBaseUrl);
  }

  static Future<void> setUseEmulator(bool enable) async {
    _useEmulator = enable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseEmulator, enable);
    if (enable) {
      _currentBaseUrl = defaultTargetPlatform == TargetPlatform.android
          ? emulatorHostAndroid
          : emulatorHostLocal;
    } else {
      _currentBaseUrl = defaultProductionUrl;
    }
    await prefs.setString(_keyBaseUrl, _currentBaseUrl);
  }
}
