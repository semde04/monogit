import '../../../../core/error/result.dart';
import '../repositories/moderation_repository.dart';

class SetItemModeration {
  const SetItemModeration(this.repository);
  final ModerationRepository repository;
  Future<Result<void>> call(
    String itemId, {
    required bool isRemoved,
    String? reason,
  }) => repository.setItemRemoved(itemId, isRemoved: isRemoved, reason: reason);
}
