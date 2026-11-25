import '../../../../core/error/result.dart';
import '../entities/chat_message.dart';
import '../repositories/message_repository.dart';

class GetMessages {
  const GetMessages(this.repository);
  final MessageRepository repository;
  Future<Result<List<ChatMessage>>> call(String claimId) =>
      repository.getMessages(claimId);
}
