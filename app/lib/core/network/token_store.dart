import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore(this._storage);
  final FlutterSecureStorage _storage;
  static const _accessKey = 'lostfound.accessToken';
  static const _refreshKey = 'lostfound.refreshToken';

  String? _accessMemory;
  String? _refreshMemory;

  Future<String?> get accessToken async {
    if (_accessMemory != null) return _accessMemory;
    try {
      _accessMemory = await _storage.read(key: _accessKey);
    } catch (_) {
      _accessMemory = null;
    }
    return _accessMemory;
  }

  Future<String?> get refreshToken async {
    if (_refreshMemory != null) return _refreshMemory;
    try {
      _refreshMemory = await _storage.read(key: _refreshKey);
    } catch (_) {
      _refreshMemory = null;
    }
    return _refreshMemory;
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessMemory = accessToken;
    _refreshMemory = refreshToken;
    try {
      await Future.wait([
        _storage.write(key: _accessKey, value: accessToken),
        _storage.write(key: _refreshKey, value: refreshToken),
      ]);
    } catch (_) {
      return;
    }
  }

  Future<void> clear() async {
    _accessMemory = null;
    _refreshMemory = null;
    try {
      await Future.wait([
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
      ]);
    } catch (_) {
      return;
    }
  }
}
