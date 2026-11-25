import '../../../../core/error/result.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_data_source.dart';

class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl(this._remote);
  final MessageRemoteDataSource _remote;
  @override
  Future<Result<List<ChatMessage>>> getMessages(String claimId) => captureApi(
    () async => (await _remote.list(claimId)).map((e) => e.entity).toList(),
  );
  @override
  Future<Result<ChatMessage>> send(String claimId, String text) =>
      captureApi(() async => (await _remote.send(claimId, text)).entity);
}
