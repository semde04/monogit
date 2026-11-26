import 'package:dio/dio.dart';

import '../models/admin_overview_model.dart';

class ModerationRemoteDataSource {
  ModerationRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AdminOverviewModel> getOverview() async {
    final data =
        (await _dio.get<Map<String, dynamic>>('/admin/overview')).data!['data']
            as Map<String, dynamic>;
    return AdminOverviewModel.fromJson(data);
  }

  Future<void> setItemRemoved(
    String itemId, {
    required bool isRemoved,
    String? reason,
  }) async {
    await _dio.patch<void>(
      '/admin/items/$itemId/moderation',
      data: {'isRemoved': isRemoved, ...?_optionalReason(reason)},
    );
  }
}

Map<String, Object>? _optionalReason(String? reason) => switch (reason) {
  final value? => {'reason': value},
  _ => null,
};
