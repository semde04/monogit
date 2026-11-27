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
  Future<Result<void>> setItemRemoved(
    String itemId, {
    required bool isRemoved,
    String? reason,
  });
}
