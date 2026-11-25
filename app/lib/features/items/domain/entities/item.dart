import 'package:equatable/equatable.dart';

class Item extends Equatable {
  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.type,
    required this.ownerId,
    required this.createdAt,
    this.proofQuestion,
    this.imageData,
    this.isClosed = false,
  });
  final String id, title, description, category, location, type, ownerId;
  final String? proofQuestion;
  final String? imageData;
  final bool isClosed;
  final DateTime createdAt;

  Item copyWith({bool? isClosed}) => Item(
    id: id,
    title: title,
    description: description,
    category: category,
    location: location,
    type: type,
    ownerId: ownerId,
    createdAt: createdAt,
    proofQuestion: proofQuestion,
    imageData: imageData,
    isClosed: isClosed ?? this.isClosed,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    location,
    type,
    ownerId,
    createdAt,
    proofQuestion,
    imageData,
    isClosed,
  ];
}
