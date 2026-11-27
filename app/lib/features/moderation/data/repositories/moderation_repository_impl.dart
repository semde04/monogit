import '../../../../core/error/result.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/admin_activity.dart';
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
  Future<Result<AdminActivityPage>> getActivity({
    int page = 1,
    int limit = 20,
    String? type,
  }) => captureApi(
    () => _remote.getActivity(page: page, limit: limit, type: type),
  );

  @override
  Future<Result<AdminItemPage>> getAdminItems({
    int page = 1,
    String? search,
    String? type,
    bool? isClosed,
    bool? isRemoved,
    bool? isReturned,
  }) => captureApi(
    () => _remote.getAdminItems(
      page: page,
      search: search,
      type: type,
      isClosed: isClosed,
      isRemoved: isRemoved,
      isReturned: isReturned,
    ),
  );

  @override
  Future<Result<void>> setItemRemoved(
    String itemId, {
    required bool isRemoved,
    String? reason,
  }) => captureApi(
    () => _remote.setItemRemoved(itemId, isRemoved: isRemoved, reason: reason),
  );

  @override
  Future<Result<AdminUserSummary>> setUserSuspension(
    String userId, {
    required bool isSuspended,
    String? reason,
  }) => captureApi(
    () => _remote.setUserSuspension(
      userId,
      isSuspended: isSuspended,
      reason: reason,
    ),
  );
}
