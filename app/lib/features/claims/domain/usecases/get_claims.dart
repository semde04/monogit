import '../../../../core/error/result.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';

class GetClaims {
  const GetClaims(this.repository);
  final ClaimRepository repository;
  Future<Result<List<Claim>>> call() => repository.getClaims();
}
