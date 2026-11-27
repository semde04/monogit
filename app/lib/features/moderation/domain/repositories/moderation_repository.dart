import '../../../../core/error/result.dart';
import '../entities/admin_activity.dart';
import '../entities/admin_overview.dart';

abstract interface class ModerationRepository {
  Future<Result<AdminOverview>> getOverview();
  Future<Result<AdminActivityPage>> getActivity({
    int page = 1,
    int limit = 20,
    String? type,
  });
  Future<Result<AdminItemPage>> getAdminItems({
    int page = 1,
    String? search,
    String? type,
    bool? isClosed,
    bool? isRemoved,
    bool? isReturned,
  });
  Future<Result<void>> setItemRemoved(
    String itemId, {
    required bool isRemoved,
    String? reason,
  });
  Future<Result<AdminUserSummary>> setUserSuspension(
    String userId, {
    required bool isSuspended,
    String? reason,
  });
}
