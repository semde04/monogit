import '../../../../core/error/result.dart';
import '../entities/app_user.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<Result<AuthSession>> login(String email, String password);
  Future<Result<AuthSession>> register(
    String name,
    String email,
    String matricule,
    String password,
  );
  Future<Result<AppUser>> currentUser();
  Future<void> logout();
}
