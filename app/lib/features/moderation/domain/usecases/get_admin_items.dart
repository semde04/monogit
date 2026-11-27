import '../../../../core/error/result.dart';
import '../entities/admin_overview.dart';
import '../repositories/moderation_repository.dart';

class GetAdminItems {
  const GetAdminItems(this.repository);
  final ModerationRepository repository;

  Future<Result<AdminItemPage>> call({
    int page = 1,
    String? search,
    String? type,
    bool? isClosed,
    bool? isRemoved,
    bool? isReturned,
  }) => repository.getAdminItems(
    page: page,
    search: search,
    type: type,
    isClosed: isClosed,
    isRemoved: isRemoved,
    isReturned: isReturned,
  );
}
