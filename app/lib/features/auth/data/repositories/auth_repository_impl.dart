import '../../../../core/error/result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/token_store.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokens);
  final AuthRemoteDataSource _remote;
  final TokenStore _tokens;

  AuthSession _session(Map<String, dynamic> json) {
    final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: user.toEntity(),
    );
  }

  @override
  Future<Result<AuthSession>> login(String email, String password) =>
      captureApi(() async {
        final session = _session(await _remote.login(email, password));
        await _tokens.save(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
        return session;
      });

  @override
  Future<Result<AuthSession>> register(
    String name,
    String email,
    String matricule,
    String password,
  ) => captureApi(() async {
    final session = _session(
      await _remote.register(name, email, matricule, password),
    );
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  });

  @override
  Future<Result<AppUser>> currentUser() async {
    if (await _tokens.accessToken == null) {
      return const Err(ServerFailure('Session absente.', code: 'NO_SESSION'));
    }
    return captureApi(() async => (await _remote.me()).toEntity());
  }

  @override
  Future<void> logout() async {
    final refresh = await _tokens.refreshToken;
    try {
      if (refresh != null) await _remote.logout(refresh);
    } finally {
      await _tokens.clear();
    }
  }
}
