import '../../../../core/error/result.dart';
import '../entities/claim.dart';

abstract interface class ClaimRepository {
  Future<Result<List<Claim>>> getClaims();
  Future<Result<Claim>> createClaim(String itemId, String proofAnswer);
  Future<Result<Claim>> updateStatus(String claimId, String status);
  Future<Result<Claim>> confirmReturn(String claimId);
}
