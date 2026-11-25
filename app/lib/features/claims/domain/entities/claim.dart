import 'package:equatable/equatable.dart';

class Claim extends Equatable {
  const Claim({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.claimantId,
    required this.claimantName,
    required this.status,
    required this.createdAt,
    this.itemType = 'FOUND',
    this.proofQuestion,
    this.proofAnswer = '',
  });
  final String id,
      itemId,
      itemTitle,
      claimantId,
      claimantName,
      status,
      itemType;
  final String? proofQuestion;
  final String proofAnswer;
  final DateTime createdAt;

  Claim copyWith({String? status}) => Claim(
    id: id,
    itemId: itemId,
    itemTitle: itemTitle,
    claimantId: claimantId,
    claimantName: claimantName,
    status: status ?? this.status,
    createdAt: createdAt,
    itemType: itemType,
    proofQuestion: proofQuestion,
    proofAnswer: proofAnswer,
  );

  @override
  List<Object?> get props => [
    id,
    itemId,
    itemTitle,
    claimantId,
    claimantName,
    status,
    createdAt,
    itemType,
    proofQuestion,
    proofAnswer,
  ];
}
