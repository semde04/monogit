import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class Register {
  const Register(this.repository);
  final AuthRepository repository;
  Future<Result<AuthSession>> call(
    String name,
    String email,
    String matricule,
    String password,
  ) => repository.register(name, email, matricule, password);
}
