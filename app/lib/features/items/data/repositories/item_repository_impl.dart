import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/error/result.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../datasources/item_remote_data_source.dart';
import '../models/item_model.dart';

class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl(this._remote, this._storage);
  final ItemRemoteDataSource _remote;
  final FlutterSecureStorage _storage;
  static const _cacheKey = 'lostfound.items.cache';

  @override
  Future<List<Item>> cachedItems() async {
    try {
      final value = await _storage.read(key: _cacheKey);
      if (value == null) return const [];
      final list = jsonDecode(value) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ItemModel.fromJsonCache)
          .map((e) => e.entity)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Result<List<Item>>> getItems({
    String? search,
    String? category,
    String? type,
  }) => captureApi(() async {
    final items = await _remote.list(
      search: search,
      category: category,
      type: type,
    );
    final cacheable = items
        .map((item) => {...item.toJson()}..remove('imageData'))
        .toList();
    await _storage.write(key: _cacheKey, value: jsonEncode(cacheable));
    return items.map((e) => e.entity).toList();
  });

  @override
  Future<Result<Item>> getItem(String id) =>
      captureApi(() async => (await _remote.get(id)).entity);

  @override
  Future<Result<Item>> createItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required String type,
    String? proofQuestion,
    String? imageData,
  }) => captureApi(
    () async => (await _remote.create({
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'type': type,
      if (proofQuestion != null && proofQuestion.trim().isNotEmpty)
        'proofQuestion': proofQuestion.trim(),
      'imageData': ?imageData,
    })).entity,
  );

  @override
  Future<Result<Item>> closeItem(String id) =>
      captureApi(() async => (await _remote.close(id)).entity);
}
