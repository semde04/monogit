import 'package:dio/dio.dart';

import '../models/claim_model.dart';

class ClaimRemoteDataSource {
  ClaimRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<ClaimModel>> list() async {
    final data =
        (await _dio.get<Map<String, dynamic>>('/claims')).data!['data']
            as Map<String, dynamic>;
    return (data['claims'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ClaimModel.fromJson)
        .toList();
  }

  Future<ClaimModel> create(String itemId, String proofAnswer) async {
    final data =
        (await _dio.post<Map<String, dynamic>>(
              '/claims',
              data: {'itemId': itemId, 'proofAnswer': proofAnswer},
            )).data!['data']
            as Map<String, dynamic>;
    return ClaimModel.fromJson(data);
  }

  Future<ClaimModel> update(String id, String status) async {
    final data =
        (await _dio.patch<Map<String, dynamic>>(
              '/claims/$id/status',
              data: {'status': status},
            )).data!['data']
            as Map<String, dynamic>;
    return ClaimModel.fromJson(data);
  }
}
