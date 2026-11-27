import '../../domain/entities/admin_overview.dart';

class AdminOverviewModel {
  const AdminOverviewModel(this.entity);
  final AdminOverview entity;

  factory AdminOverviewModel.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    final users = json['recentUsers'] as List<dynamic>? ?? const [];
    final items = json['recentItems'] as List<dynamic>? ?? const [];
    return AdminOverviewModel(
      AdminOverview(
        userCount: _integer(stats['users']),
        itemCount: _integer(stats['items']),
        claimCount: _integer(stats['claims']),
        pendingClaimCount: _integer(stats['pendingClaims']),
        newUsersToday: _integer(stats['newUsersToday']),
        actionsToday: _integer(stats['actionsToday']),
        foundReportsToday: _integer(stats['foundReportsToday']),
        returnedItems: _integer(stats['returnedItems']),
        users: users
            .whereType<Map<String, dynamic>>()
            .map(userFromJson)
            .toList(),
        items: items.whereType<Map<String, dynamic>>().map(_item).toList(),
      ),
    );
  }

  static int _integer(dynamic value) => value is num ? value.toInt() : 0;

  static AdminUserSummary userFromJson(Map<String, dynamic> json) =>
      AdminUserSummary(
        id: (json['_id'] ?? '').toString(),
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        matricule: json['matricule']?.toString() ?? '—',
        role: json['role']?.toString() ?? 'user',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        isSuspended: json['isSuspended'] == true,
      );

  static AdminItemSummary _item(Map<String, dynamic> json) {
    final owner = json['owner'];
    final ownerMap = owner is Map<String, dynamic>
        ? owner
        : const <String, dynamic>{};
    return AdminItemSummary(
      id: (json['_id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      type: json['type']?.toString() ?? 'FOUND',
      ownerId: ownerMap['_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      ownerName: ownerMap['name']?.toString() ?? 'Membre',
      ownerMatricule: ownerMap['matricule']?.toString() ?? '—',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRemoved: json['isRemoved'] == true,
      isClosed: json['isClosed'] == true,
      isReturned: json['isReturned'] == true,
      moderationReason: json['moderationReason']?.toString(),
      imageData: json['imageData']?.toString(),
    );
  }
}
