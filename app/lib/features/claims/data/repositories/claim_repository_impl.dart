import '../../../../core/error/result.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/claim.dart';
import '../../domain/repositories/claim_repository.dart';
import '../datasources/claim_remote_data_source.dart';

class ClaimRepositoryImpl implements ClaimRepository {
  ClaimRepositoryImpl(this._remote);
  final ClaimRemoteDataSource _remote;
  @override
  Future<Result<List<Claim>>> getClaims() => captureApi(
    () async => (await _remote.list()).map((e) => e.entity).toList(),
  );
  @override
  Future<Result<Claim>> createClaim(String itemId, String proofAnswer) =>
      captureApi(
        () async => (await _remote.create(itemId, proofAnswer)).entity,
      );
  @override
  Future<Result<Claim>> updateStatus(String claimId, String status) =>
      captureApi(() async => (await _remote.update(claimId, status)).entity);
  @override
  Future<Result<Claim>> confirmReturn(String claimId) =>
      captureApi(() async => (await _remote.confirmReturn(claimId)).entity);
}
