import 'package:equatable/equatable.dart';

class AdminActivity extends Equatable {
  const AdminActivity({
    required this.id,
    required this.type,
    required this.actorName,
    required this.summary,
    required this.createdAt,
    this.targetId,
    this.targetType,
  });

  final String id, type, actorName, summary;
  final DateTime createdAt;
  final String? targetId, targetType;

  @override
  List<Object?> get props => [
    id,
    type,
    actorName,
    summary,
    createdAt,
    targetId,
    targetType,
  ];
}

class AdminActivityPage extends Equatable {
  const AdminActivityPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<AdminActivity> items;
  final int page, totalPages;

  @override
  List<Object?> get props => [items, page, totalPages];
}
