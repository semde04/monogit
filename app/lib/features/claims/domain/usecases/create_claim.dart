import '../../../../core/error/result.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';

class CreateClaim {
  const CreateClaim(this.repository);
  final ClaimRepository repository;
  Future<Result<Claim>> call(String itemId, String proofAnswer) =>
      repository.createClaim(itemId, proofAnswer);
}
