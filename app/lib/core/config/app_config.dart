import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    if (kIsWeb) return 'http://localhost:5000/api/v1';
    return 'http://10.0.2.2:5000/api/v1';
  }
}
