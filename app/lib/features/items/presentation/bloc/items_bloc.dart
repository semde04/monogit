import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../../domain/usecases/close_item.dart';
import '../../domain/usecases/create_item.dart';
import '../../domain/usecases/get_item.dart';
import '../../domain/usecases/get_items.dart';

sealed class ItemsEvent extends Equatable {
  const ItemsEvent();
  @override
  List<Object?> get props => [];
}

final class ItemsRequested extends ItemsEvent {
  const ItemsRequested();
}

final class ItemDetailRequested extends ItemsEvent {
  const ItemDetailRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class ItemSearchChanged extends ItemsEvent {
  const ItemSearchChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

final class ItemFiltersChanged extends ItemsEvent {
  const ItemFiltersChanged({this.category, this.type});
  final String? category, type;
  @override
  List<Object?> get props => [category, type];
}

final class ItemCreated extends ItemsEvent {
  const ItemCreated({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.type,
    this.proofQuestion,
    this.imageData,
  });
  final String title, description, category, location, type;
  final String? proofQuestion;
  final String? imageData;
  @override
  List<Object?> get props => [
    title,
    description,
    category,
    location,
    type,
    proofQuestion,
    imageData,
  ];
}

final class ItemClosed extends ItemsEvent {
  const ItemClosed(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ItemsState extends Equatable {
  const ItemsState({
    this.items = const [],
    this.selected,
    this.loading = false,
    this.saving = false,
    this.failure,
    this.createdItem,
    this.search = '',
    this.category,
    this.type,
  });
  final List<Item> items;
  final Item? selected, createdItem;
  final bool loading, saving;
  final Failure? failure;
  final String search;
  final String? category, type;
  ItemsState copyWith({
    List<Item>? items,
    Item? selected,
    bool clearSelected = false,
    bool? loading,
    bool? saving,
    Failure? failure,
    bool clearFailure = false,
    Item? createdItem,
    bool clearCreated = false,
    String? search,
    String? category,
    bool clearCategory = false,
    String? type,
    bool clearType = false,
  }) => ItemsState(
    items: items ?? this.items,
    selected: clearSelected ? null : selected ?? this.selected,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    failure: clearFailure ? null : failure ?? this.failure,
    createdItem: clearCreated ? null : createdItem ?? this.createdItem,
    search: search ?? this.search,
    category: clearCategory ? null : category ?? this.category,
    type: clearType ? null : type ?? this.type,
  );
  @override
  List<Object?> get props => [
    items,
    selected,
    loading,
    saving,
    failure,
    createdItem,
    search,
    category,
    type,
  ];
}

class ItemsBloc extends Bloc<ItemsEvent, ItemsState> {
  ItemsBloc(this._repository)
    : _getItems = GetItems(_repository),
      _getItem = GetItem(_repository),
      _createItem = CreateItem(_repository),
      _closeItem = CloseItem(_repository),
      super(const ItemsState()) {
    on<ItemsRequested>(_load);
    on<ItemSearchChanged>(_searchChanged);
    on<ItemFiltersChanged>(_filtersChanged);
    on<ItemDetailRequested>(_detail);
    on<ItemCreated>(_create);
    on<ItemClosed>(_close);
  }
  final ItemRepository _repository;
  final GetItems _getItems;
  final GetItem _getItem;
  final CreateItem _createItem;
  final CloseItem _closeItem;
  Timer? _debounce;

  Future<void> _load(ItemsRequested event, Emitter<ItemsState> emit) async {
    if (state.items.isEmpty) {
      final cached = await _repository.cachedItems();
      if (cached.isNotEmpty) {
        emit(state.copyWith(items: cached, loading: true, clearFailure: true));
      }
    }
    emit(state.copyWith(loading: true, clearFailure: true, clearCreated: true));
    final result = await _getItems(
      search: state.search,
      category: state.category,
      type: state.type,
    );
    result.fold(
      (items) => emit(state.copyWith(items: items, loading: false)),
      (failure) => emit(state.copyWith(loading: false, failure: failure)),
    );
  }

  void _searchChanged(ItemSearchChanged event, Emitter<ItemsState> emit) {
    emit(state.copyWith(search: event.value));
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => add(const ItemsRequested()),
    );
  }

  void _filtersChanged(ItemFiltersChanged event, Emitter<ItemsState> emit) {
    emit(
      state.copyWith(
        category: event.category,
        type: event.type,
        clearCategory: event.category == null,
        clearType: event.type == null,
      ),
    );
    add(const ItemsRequested());
  }

  Future<void> _detail(
    ItemDetailRequested event,
    Emitter<ItemsState> emit,
  ) async {
    emit(
      state.copyWith(loading: true, clearFailure: true, clearSelected: true),
    );
    final result = await _getItem(event.id);
    result.fold(
      (item) => emit(state.copyWith(selected: item, loading: false)),
      (failure) => emit(state.copyWith(loading: false, failure: failure)),
    );
  }

  Future<void> _create(ItemCreated event, Emitter<ItemsState> emit) async {
    emit(state.copyWith(saving: true, clearFailure: true, clearCreated: true));
    final result = await _createItem(
      title: event.title,
      description: event.description,
      category: event.category,
      location: event.location,
      type: event.type,
      proofQuestion: event.proofQuestion,
      imageData: event.imageData,
    );
    result.fold(
      (item) => emit(
        state.copyWith(
          saving: false,
          createdItem: item,
          items: [item, ...state.items],
        ),
      ),
      (failure) => emit(state.copyWith(saving: false, failure: failure)),
    );
  }

  Future<void> _close(ItemClosed event, Emitter<ItemsState> emit) async {
    final previous = state.items;
    final optimistic = previous
        .map(
          (item) => item.id == event.id ? item.copyWith(isClosed: true) : item,
        )
        .toList();
    final selectedBefore = state.selected;
    final selected = selectedBefore?.id == event.id
        ? selectedBefore!.copyWith(isClosed: true)
        : selectedBefore;
    emit(
      state.copyWith(items: optimistic, selected: selected, clearFailure: true),
    );
    final result = await _closeItem(event.id);
    result.fold(
      (item) => emit(
        state.copyWith(
          selected: item,
          items: state.items
              .map((entry) => entry.id == item.id ? item : entry)
              .toList(),
        ),
      ),
      (failure) => emit(
        state.copyWith(
          items: previous,
          selected: selectedBefore,
          failure: failure,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
