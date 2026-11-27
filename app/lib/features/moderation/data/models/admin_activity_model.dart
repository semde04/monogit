import '../../domain/entities/admin_activity.dart';

class AdminActivityModel {
  const AdminActivityModel(this.entity);

  final AdminActivity entity;

  static AdminActivityPage fromList(
    Map<String, dynamic> body, {
    required int page,
  }) {
    final rows = body['data'] as List<dynamic>? ?? const [];
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    return AdminActivityPage(
      items: rows.whereType<Map<String, dynamic>>().map(_activity).toList(),
      page: page,
      totalPages: meta['totalPages'] is num
          ? (meta['totalPages'] as num).toInt()
          : 1,
    );
  }

  static AdminActivity _activity(Map<String, dynamic> json) => AdminActivity(
    id: (json['_id'] ?? '').toString(),
    type: json['type']?.toString() ?? 'unknown',
    actorName: json['actorName']?.toString() ?? 'Utilisateur',
    summary: json['summary']?.toString() ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    targetId: json['targetId']?.toString(),
    targetType: json['targetType']?.toString(),
  );
}
