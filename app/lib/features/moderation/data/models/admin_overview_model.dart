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
        users: users.whereType<Map<String, dynamic>>().map(_user).toList(),
        items: items.whereType<Map<String, dynamic>>().map(_item).toList(),
      ),
    );
  }

  static int _integer(dynamic value) => value is num ? value.toInt() : 0;

  static AdminUserSummary _user(Map<String, dynamic> json) => AdminUserSummary(
    id: (json['_id'] ?? '').toString(),
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    matricule: json['matricule']?.toString() ?? '—',
    role: json['role']?.toString() ?? 'user',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );

  static AdminItemSummary _item(Map<String, dynamic> json) {
    final owner = json['owner'];
    return AdminItemSummary(
      id: (json['_id'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      type: json['type']?.toString() ?? 'FOUND',
      ownerName: owner is Map<String, dynamic>
          ? owner['name']?.toString() ?? 'Membre'
          : 'Membre',
      ownerMatricule: owner is Map<String, dynamic>
          ? owner['matricule']?.toString() ?? '—'
          : '—',
      isRemoved: json['isRemoved'] == true,
      moderationReason: json['moderationReason']?.toString(),
      imageData: json['imageData']?.toString(),
    );
  }
}
