import '../../domain/entities/claim.dart';

class ClaimModel {
  const ClaimModel(this.entity);
  final Claim entity;

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    final claimant = json['claimant'];
    final itemMap = item is Map<String, dynamic>
        ? item
        : const <String, dynamic>{};
    final claimantMap = claimant is Map<String, dynamic>
        ? claimant
        : const <String, dynamic>{};
    return ClaimModel(
      Claim(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        itemId: (itemMap['_id'] ?? itemMap['id'] ?? item ?? '').toString(),
        itemTitle: itemMap['title']?.toString() ?? 'Objet',
        itemType: itemMap['type']?.toString() ?? 'FOUND',
        proofQuestion: itemMap['proofQuestion']?.toString(),
        claimantId: (claimantMap['_id'] ?? claimantMap['id'] ?? claimant ?? '')
            .toString(),
        claimantName: claimantMap['name']?.toString() ?? 'Utilisateur',
        status: json['status']?.toString() ?? 'pending',
        proofAnswer: json['proofAnswer']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      ),
    );
  }
}
