import '../../../../core/error/result.dart';
import '../entities/item.dart';
import '../repositories/item_repository.dart';

class GetItems {
  const GetItems(this.repository);
  final ItemRepository repository;
  Future<Result<List<Item>>> call({
    String? search,
    String? category,
    String? type,
  }) => repository.getItems(search: search, category: category, type: type);
}
