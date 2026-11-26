import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_configuredUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL est obligatoire : utilisez --dart-define=API_BASE_URL=... '
        'ou --dart-define-from-file=dart_defines/dev.json (voir README).',
      );
    }
    final uri = Uri.tryParse(_configuredUrl);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && !(kDebugMode && uri.scheme == 'http'))) {
      throw StateError('API_BASE_URL invalide : $_configuredUrl');
    }
    return _configuredUrl;
  }
}
