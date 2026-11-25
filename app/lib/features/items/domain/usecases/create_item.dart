import '../../../../core/error/result.dart';
import '../entities/item.dart';
import '../repositories/item_repository.dart';

class CreateItem {
  const CreateItem(this.repository);
  final ItemRepository repository;
  Future<Result<Item>> call({
    required String title,
    required String description,
    required String category,
    required String location,
    required String type,
    String? proofQuestion,
    String? imageData,
  }) => repository.createItem(
    title: title,
    description: description,
    category: category,
    location: location,
    type: type,
    proofQuestion: proofQuestion,
    imageData: imageData,
  );
}
