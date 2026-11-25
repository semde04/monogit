import 'package:dio/dio.dart';

import '../models/item_model.dart';

class ItemRemoteDataSource {
  ItemRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<ItemModel>> list({
    String? search,
    String? category,
    String? type,
  }) async {
    final query = <String, dynamic>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (type != null && type.isNotEmpty) 'type': type,
    };
    final data =
        (await _dio.get<Map<String, dynamic>>(
              '/items',
              queryParameters: query,
            )).data!['data']
            as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(ItemModel.fromJson)
        .toList();
  }

  Future<ItemModel> get(String id) async {
    final data =
        (await _dio.get<Map<String, dynamic>>('/items/$id')).data!['data']
            as Map<String, dynamic>;
    return ItemModel.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<ItemModel> create(Map<String, dynamic> body) async {
    final data =
        (await _dio.post<Map<String, dynamic>>(
              '/items',
              data: body,
            )).data!['data']
            as Map<String, dynamic>;
    return ItemModel.fromJson(data);
  }

  Future<ItemModel> close(String id) async {
    final data =
        (await _dio.patch<Map<String, dynamic>>('/items/$id/close'))
                .data!['data']
            as Map<String, dynamic>;
    return ItemModel.fromJson(data);
  }
}
