import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this.repository);
  final AuthRepository repository;
  Future<Result<AuthSession>> call(String email, String password) =>
      repository.login(email, password);
}
