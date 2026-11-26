import '../../../../core/error/result.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';

class ConfirmClaimReturn {
  const ConfirmClaimReturn(this.repository);
  final ClaimRepository repository;

  Future<Result<Claim>> call(String claimId) =>
      repository.confirmReturn(claimId);
}
