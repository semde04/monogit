import 'package:dio/dio.dart';

import 'token_store.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._tokens);
  final Dio _dio;
  final TokenStore _tokens;
  Future<String?>? _refreshInFlight;

  bool _isPublic(String path) =>
      path.endsWith('/auth/login') ||
      path.endsWith('/auth/register') ||
      path.endsWith('/auth/refresh') ||
      path.endsWith('/auth/logout');

  Future<String?> _refreshShared() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final future = _refresh();
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) _refreshInFlight = null;
    });
    return future;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        _isPublic(request.path) ||
        request.extra['retried'] == true) {
      handler.next(err);
      return;
    }

    try {
      var token = await _tokens.accessToken;
      final failedWith = request.headers['Authorization']
          ?.toString()
          .replaceFirst('Bearer ', '');
      if (token == null || token == failedWith) {
        token = await _refreshShared();
      }
      if (token == null) {
        await _tokens.clear();
        handler.next(err);
        return;
      }
      request
        ..extra['retried'] = true
        ..headers['Authorization'] = 'Bearer $token';
      handler.resolve(await _dio.fetch<dynamic>(request));
    } catch (_) {
      await _tokens.clear();
      handler.next(err);
    }
  }

  Future<String?> _refresh() async {
    final refreshToken = await _tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        sendTimeout: _dio.options.sendTimeout,
      ),
    );
    final response = await refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    final access = data?['accessToken'] as String?;
    final refresh = data?['refreshToken'] as String?;
    if (access == null || refresh == null) return null;
    await _tokens.save(accessToken: access, refreshToken: refresh);
    return access;
  }
}
