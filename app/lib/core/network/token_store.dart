import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  TokenStore(this._storage);
  final FlutterSecureStorage _storage;
  static const _accessKey = 'lostfound.accessToken';
  static const _refreshKey = 'lostfound.refreshToken';

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}
