import '../../../../core/error/result.dart';
import '../entities/admin_overview.dart';
import '../repositories/moderation_repository.dart';

class GetAdminOverview {
  const GetAdminOverview(this.repository);
  final ModerationRepository repository;
  Future<Result<AdminOverview>> call() => repository.getOverview();
}
