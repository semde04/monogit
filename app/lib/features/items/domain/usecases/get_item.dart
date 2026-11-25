import '../../../../core/error/result.dart';
import '../entities/item.dart';
import '../repositories/item_repository.dart';

class GetItem {
  const GetItem(this.repository);
  final ItemRepository repository;
  Future<Result<Item>> call(String id) => repository.getItem(id);
}
