import '../../../../core/error/result.dart';
import '../entities/admin_overview.dart';

abstract interface class ModerationRepository {
  Future<Result<AdminOverview>> getOverview();
  Future<Result<void>> setItemRemoved(
    String itemId, {
    required bool isRemoved,
    String? reason,
  });
}
