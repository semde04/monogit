import '../../../../core/error/result.dart';
import '../entities/admin_overview.dart';
import '../repositories/moderation_repository.dart';

class SetUserSuspension {
  const SetUserSuspension(this.repository);
  final ModerationRepository repository;

  Future<Result<AdminUserSummary>> call(
    String userId, {
    required bool isSuspended,
    String? reason,
  }) => repository.setUserSuspension(
    userId,
    isSuspended: isSuspended,
    reason: reason,
  );
}
