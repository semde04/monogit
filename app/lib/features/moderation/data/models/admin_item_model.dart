import '../../domain/entities/admin_overview.dart';

class AdminItemModel {
  const AdminItemModel(this.entity);
  final AdminItemPage entity;

  static AdminItemPage fromList(
    Map<String, dynamic> body, {
    required int page,
  }) {
    final rows = body['data'] as List<dynamic>? ?? const [];
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    final pages = meta['pages'] ?? meta['totalPages'];
    return AdminItemPage(
      items: rows.whereType<Map<String, dynamic>>().map(_item).toList(),
      page: page,
      totalPages: pages is num ? pages.toInt() : 1,
    );
  }

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
