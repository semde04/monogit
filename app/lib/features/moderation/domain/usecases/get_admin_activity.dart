import '../../../../core/error/result.dart';
import '../entities/admin_activity.dart';
import '../repositories/moderation_repository.dart';

class GetAdminActivity {
  const GetAdminActivity(this.repository);
  final ModerationRepository repository;

  Future<Result<AdminActivityPage>> call({
    int page = 1,
    int limit = 20,
    String? type,
  }) => repository.getActivity(page: page, limit: limit, type: type);
}
