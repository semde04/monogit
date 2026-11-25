import '../../domain/entities/item.dart';

class ItemModel {
  const ItemModel(this.entity);
  final Item entity;

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    return ItemModel(
      Item(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Autre',
        location: json['location']?.toString() ?? '',
        type: json['type']?.toString() ?? 'FOUND',
        ownerId: owner is Map<String, dynamic>
            ? (owner['_id'] ?? owner['id'] ?? '').toString()
            : owner?.toString() ?? '',
        proofQuestion: json['proofQuestion']?.toString(),
        imageData: json['imageData']?.toString(),
        isClosed: json['isClosed'] == true,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      ),
    );
  }

  factory ItemModel.fromEntity(Item entity) => ItemModel(entity);
  factory ItemModel.fromJsonCache(Map<String, dynamic> json) =>
      ItemModel.fromJson(json);
  Map<String, dynamic> toJson() => {
    '_id': entity.id,
    'title': entity.title,
    'description': entity.description,
    'category': entity.category,
    'location': entity.location,
    'type': entity.type,
    'owner': entity.ownerId,
    'proofQuestion': entity.proofQuestion,
    'imageData': entity.imageData,
    'isClosed': entity.isClosed,
    'createdAt': entity.createdAt.toIso8601String(),
  };
}
