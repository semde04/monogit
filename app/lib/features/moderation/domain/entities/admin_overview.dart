import 'package:equatable/equatable.dart';

class AdminOverview extends Equatable {
  const AdminOverview({
    required this.userCount,
    required this.itemCount,
    required this.claimCount,
    required this.pendingClaimCount,
    required this.users,
    required this.items,
    this.newUsersToday = 0,
    this.actionsToday = 0,
  });

  final int userCount, itemCount, claimCount, pendingClaimCount;
  final int newUsersToday, actionsToday;
  final List<AdminUserSummary> users;
  final List<AdminItemSummary> items;

  @override
  List<Object?> get props => [
    userCount,
    itemCount,
    claimCount,
    pendingClaimCount,
    newUsersToday,
    actionsToday,
    users,
    items,
  ];
}

class AdminUserSummary extends Equatable {
  const AdminUserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.matricule,
    required this.role,
    this.createdAt,
  });

  final String id, name, email, matricule, role;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, name, email, matricule, role, createdAt];
}

class AdminItemSummary extends Equatable {
  const AdminItemSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.ownerName,
    required this.ownerMatricule,
    required this.isRemoved,
    this.moderationReason,
    this.imageData,
  });

  final String id,
      title,
      description,
      location,
      type,
      ownerName,
      ownerMatricule;
  final bool isRemoved;
  final String? moderationReason, imageData;

  AdminItemSummary copyWith({bool? isRemoved, String? moderationReason}) =>
      AdminItemSummary(
        id: id,
        title: title,
        description: description,
        location: location,
        type: type,
        ownerName: ownerName,
        ownerMatricule: ownerMatricule,
        isRemoved: isRemoved ?? this.isRemoved,
        moderationReason: moderationReason,
        imageData: imageData,
      );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    location,
    type,
    ownerName,
    ownerMatricule,
    isRemoved,
    moderationReason,
    imageData,
  ];
}
