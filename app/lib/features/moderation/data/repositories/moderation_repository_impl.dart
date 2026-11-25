import '../../../../core/error/result.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/admin_overview.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../datasources/moderation_remote_data_source.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  const ModerationRepositoryImpl(this._remote);
  final ModerationRemoteDataSource _remote;

  @override
  Future<Result<AdminOverview>> getOverview() =>
      captureApi(() async => (await _remote.getOverview()).entity);

  @override
  Future<Result<void>> setItemRemoved(
    String itemId, {
    required bool isRemoved,
    String? reason,
  }) => captureApi(
    () => _remote.setItemRemoved(
      itemId,
      isRemoved: isRemoved,
      reason: reason,
    ),
  );
}
