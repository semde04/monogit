import '../../../../core/error/result.dart';
import '../entities/item.dart';

abstract interface class ItemRepository {
  Future<List<Item>> cachedItems();
  Future<Result<List<Item>>> getItems({
    String? search,
    String? category,
    String? type,
  });
  Future<Result<Item>> getItem(String id);
  Future<Result<Item>> createItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required String type,
    String? proofQuestion,
    String? imageData,
  });
  Future<Result<Item>> closeItem(String id);
}
