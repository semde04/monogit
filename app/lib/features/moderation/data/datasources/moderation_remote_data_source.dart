import 'package:dio/dio.dart';

import '../models/admin_activity_model.dart';
import '../models/admin_item_model.dart';
import '../models/admin_overview_model.dart';
import '../../domain/entities/admin_activity.dart';
import '../../domain/entities/admin_overview.dart';

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

  Future<AdminItemPage> getAdminItems({
    int page = 1,
    int limit = 20,
    String? search,
    String? type,
    bool? isClosed,
    bool? isRemoved,
    bool? isReturned,
  }) async {
    final body = (await _dio.get<Map<String, dynamic>>(
      '/admin/items',
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (isClosed != null) 'isClosed': isClosed.toString(),
        if (isRemoved != null) 'isRemoved': isRemoved.toString(),
        if (isReturned != null) 'isReturned': isReturned.toString(),
      },
    )).data!;
    return AdminItemModel.fromList(body, page: page);
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

  Future<AdminUserSummary> setUserSuspension(
    String userId, {
    required bool isSuspended,
    String? reason,
  }) async {
    final data =
        (await _dio.patch<Map<String, dynamic>>(
              '/admin/users/$userId/suspension',
              data: {'isSuspended': isSuspended, ...?_optionalReason(reason)},
            )).data!['data']
            as Map<String, dynamic>;
    return AdminOverviewModel.userFromJson(data);
  }
}

Map<String, Object>? _optionalReason(String? reason) => switch (reason) {
  final value? => {'reason': value},
  _ => null,
};
