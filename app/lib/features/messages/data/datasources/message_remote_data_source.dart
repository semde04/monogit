import 'package:dio/dio.dart';

import '../models/message_model.dart';

class MessageRemoteDataSource {
  MessageRemoteDataSource(this._dio);
  final Dio _dio;
  Future<List<MessageModel>> list(String claimId) async {
    final data =
        (await _dio.get<Map<String, dynamic>>('/messages/claims/$claimId'))
                .data!['data']
            as Map<String, dynamic>;
    return (data['messages'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(MessageModel.fromJson)
        .toList();
  }

  Future<MessageModel> send(String claimId, String text) async {
    final data =
        (await _dio.post<Map<String, dynamic>>(
              '/messages',
              data: {'claimId': claimId, 'text': text},
            )).data!['data']
            as Map<String, dynamic>;
    return MessageModel.fromJson(data);
  }
}
