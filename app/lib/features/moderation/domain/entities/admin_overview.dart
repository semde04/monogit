import 'package:equatable/equatable.dart';

const _unset = Object();

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
    this.foundReportsToday = 0,
    this.returnedItems = 0,
  });

  final int userCount, itemCount, claimCount, pendingClaimCount;
  final int newUsersToday, actionsToday, foundReportsToday, returnedItems;
  final List<AdminUserSummary> users;
  final List<AdminItemSummary> items;

  AdminOverview copyWith({
    int? userCount,
    int? itemCount,
    int? claimCount,
    int? pendingClaimCount,
    int? newUsersToday,
    int? actionsToday,
    int? foundReportsToday,
    int? returnedItems,
    List<AdminUserSummary>? users,
    List<AdminItemSummary>? items,
  }) => AdminOverview(
    userCount: userCount ?? this.userCount,
    itemCount: itemCount ?? this.itemCount,
    claimCount: claimCount ?? this.claimCount,
    pendingClaimCount: pendingClaimCount ?? this.pendingClaimCount,
    newUsersToday: newUsersToday ?? this.newUsersToday,
    actionsToday: actionsToday ?? this.actionsToday,
    foundReportsToday: foundReportsToday ?? this.foundReportsToday,
    returnedItems: returnedItems ?? this.returnedItems,
    users: users ?? this.users,
    items: items ?? this.items,
  );

  @override
  List<Object?> get props => [
    userCount,
    itemCount,
    claimCount,
    pendingClaimCount,
    newUsersToday,
    actionsToday,
    foundReportsToday,
    returnedItems,
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
    this.isSuspended = false,
  });

  final String id, name, email, matricule, role;
  final DateTime? createdAt;
  final bool isSuspended;

  AdminUserSummary copyWith({
    String? id,
    String? name,
    String? email,
    String? matricule,
    String? role,
    Object? createdAt = _unset,
    bool? isSuspended,
  }) => AdminUserSummary(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    matricule: matricule ?? this.matricule,
    role: role ?? this.role,
    createdAt: identical(createdAt, _unset)
        ? this.createdAt
        : createdAt as DateTime?,
    isSuspended: isSuspended ?? this.isSuspended,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    matricule,
    role,
    createdAt,
    isSuspended,
  ];
}

class AdminItemSummary extends Equatable {
  const AdminItemSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.ownerId,
    required this.category,
    required this.ownerName,
    required this.ownerMatricule,
    required this.createdAt,
    required this.isRemoved,
    this.isClosed = false,
    this.isReturned = false,
    this.moderationReason,
    this.imageData,
  });

  final String id,
      title,
      description,
      location,
      type,
      ownerId,
      category,
      ownerName,
      ownerMatricule;
  final DateTime createdAt;
  final bool isRemoved, isClosed, isReturned;
  final String? moderationReason, imageData;

  AdminItemSummary copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? type,
    String? ownerId,
    String? category,
    String? ownerName,
    String? ownerMatricule,
    DateTime? createdAt,
    bool? isRemoved,
    bool? isClosed,
    bool? isReturned,
    Object? moderationReason = _unset,
    Object? imageData = _unset,
  }) => AdminItemSummary(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    location: location ?? this.location,
    type: type ?? this.type,
    ownerId: ownerId ?? this.ownerId,
    category: category ?? this.category,
    ownerName: ownerName ?? this.ownerName,
    ownerMatricule: ownerMatricule ?? this.ownerMatricule,
    createdAt: createdAt ?? this.createdAt,
    isRemoved: isRemoved ?? this.isRemoved,
    isClosed: isClosed ?? this.isClosed,
    isReturned: isReturned ?? this.isReturned,
    moderationReason: identical(moderationReason, _unset)
        ? this.moderationReason
        : moderationReason as String?,
    imageData: identical(imageData, _unset)
        ? this.imageData
        : imageData as String?,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    location,
    type,
    ownerId,
    category,
    ownerName,
    ownerMatricule,
    createdAt,
    isRemoved,
    isClosed,
    isReturned,
    moderationReason,
    imageData,
  ];
}

class AdminItemPage extends Equatable {
  const AdminItemPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<AdminItemSummary> items;
  final int page, totalPages;

  @override
  List<Object?> get props => [items, page, totalPages];
}

class AdminItemsFilters extends Equatable {
  const AdminItemsFilters({
    this.search,
    this.type,
    this.isClosed,
    this.isRemoved,
    this.isReturned,
  });

  final String? search;
  final String? type;
  final bool? isClosed;
  final bool? isRemoved;
  final bool? isReturned;

  AdminItemsFilters copyWith({
    Object? search = _unset,
    Object? type = _unset,
    Object? isClosed = _unset,
    Object? isRemoved = _unset,
    Object? isReturned = _unset,
  }) => AdminItemsFilters(
    search: identical(search, _unset) ? this.search : search as String?,
    type: identical(type, _unset) ? this.type : type as String?,
    isClosed: identical(isClosed, _unset) ? this.isClosed : isClosed as bool?,
    isRemoved: identical(isRemoved, _unset)
        ? this.isRemoved
        : isRemoved as bool?,
    isReturned: identical(isReturned, _unset)
        ? this.isReturned
        : isReturned as bool?,
  );

  @override
  List<Object?> get props => [search, type, isClosed, isRemoved, isReturned];
}
