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
    this.ownerConfirmedReturn = false,
    this.claimantConfirmedReturn = false,
    this.returnedAt,
    this.finderName,
    this.recipientName,
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
  final bool ownerConfirmedReturn, claimantConfirmedReturn;
  final DateTime? returnedAt;
  final String? finderName, recipientName;

  Claim copyWith({
    String? status,
    bool? ownerConfirmedReturn,
    bool? claimantConfirmedReturn,
    DateTime? returnedAt,
    String? finderName,
    String? recipientName,
  }) => Claim(
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
    ownerConfirmedReturn: ownerConfirmedReturn ?? this.ownerConfirmedReturn,
    claimantConfirmedReturn:
        claimantConfirmedReturn ?? this.claimantConfirmedReturn,
    returnedAt: returnedAt ?? this.returnedAt,
    finderName: finderName ?? this.finderName,
    recipientName: recipientName ?? this.recipientName,
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
    ownerConfirmedReturn,
    claimantConfirmedReturn,
    returnedAt,
    finderName,
    recipientName,
  ];
}
