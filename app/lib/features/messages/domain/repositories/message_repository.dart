import '../../../../core/error/result.dart';
import '../entities/chat_message.dart';

abstract interface class MessageRepository {
  Future<Result<List<ChatMessage>>> getMessages(String claimId);
  Future<Result<ChatMessage>> send(String claimId, String text);
}
