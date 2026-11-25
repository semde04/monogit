import '../../../../core/error/result.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';

class UpdateClaimStatus {
  const UpdateClaimStatus(this.repository);
  final ClaimRepository repository;
  Future<Result<Claim>> call(String claimId, String status) =>
      repository.updateStatus(claimId, status);
}
