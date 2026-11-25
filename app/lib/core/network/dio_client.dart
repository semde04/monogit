import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'token_store.dart';

Dio createDioClient(TokenStore tokens) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 18),
      sendTimeout: const Duration(seconds: 18),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  dio.interceptors.add(AuthInterceptor(dio, tokens));
  return dio;
}
