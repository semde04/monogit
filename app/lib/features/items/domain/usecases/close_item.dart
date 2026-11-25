import '../../../../core/error/result.dart';
import '../entities/item.dart';
import '../repositories/item_repository.dart';

class CloseItem {
  const CloseItem(this.repository);
  final ItemRepository repository;
  Future<Result<Item>> call(String id) => repository.closeItem(id);
}
