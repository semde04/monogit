import 'package:dio/dio.dart';

import '../models/admin_activity_model.dart';
import '../models/admin_overview_model.dart';
import '../../domain/entities/admin_activity.dart';

class ModerationRemoteDataSource {
  ModerationRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AdminOverviewModel> getOverview() async {
    final data =
        (await _dio.get<Map<String, dynamic>>('/admin/overview')).data!['data']
            as Map<String, dynamic>;
    return AdminOverviewModel.fromJson(data);
  }

  Future<AdminActivityPage> getActivity({
    required int page,
    required int limit,
    String? type,
  }) async {
    final body = (await _dio.get<Map<String, dynamic>>(
      '/admin/activity',
      queryParameters: {'page': page, 'limit': limit, 'type': ?type},
    )).data!;
    return AdminActivityModel.fromList(body, page: page);
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
