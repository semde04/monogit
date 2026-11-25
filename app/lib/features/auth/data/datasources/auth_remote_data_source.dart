import 'package:dio/dio.dart';

import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> login(String email, String password) async =>
      (await _dio.post<Map<String, dynamic>>(
            '/auth/login',
            data: {'email': email, 'password': password},
          )).data!['data']
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String matricule,
    String password,
  ) async =>
      (await _dio.post<Map<String, dynamic>>(
            '/auth/register',
            data: {
              'name': name,
              'email': email,
              'matricule': matricule,
              'password': password,
            },
          )).data!['data']
          as Map<String, dynamic>;

  Future<UserModel> me() async {
    final data =
        (await _dio.get<Map<String, dynamic>>('/auth/me')).data!['data']
            as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>('/auth/logout', data: {'refreshToken': refreshToken});
  }
}
