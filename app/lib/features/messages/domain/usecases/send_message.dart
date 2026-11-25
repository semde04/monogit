import '../../../../core/error/result.dart';
import '../entities/chat_message.dart';
import '../repositories/message_repository.dart';

class SendMessage {
  const SendMessage(this.repository);
  final MessageRepository repository;
  Future<Result<ChatMessage>> call(String claimId, String text) =>
      repository.send(claimId, text);
}
