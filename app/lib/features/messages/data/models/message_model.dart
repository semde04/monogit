import '../../domain/entities/chat_message.dart';

class MessageModel {
  const MessageModel(this.entity);
  final ChatMessage entity;
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final senderMap = sender is Map<String, dynamic>
        ? sender
        : const <String, dynamic>{};
    return MessageModel(
      ChatMessage(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        senderId: (senderMap['_id'] ?? senderMap['id'] ?? sender ?? '')
            .toString(),
        senderName: senderMap['name']?.toString() ?? 'Utilisateur',
        text: (json['body'] ?? json['text'] ?? '').toString(),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      ),
    );
  }
}
