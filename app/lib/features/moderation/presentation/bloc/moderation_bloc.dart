import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_activity.dart';
import '../../domain/entities/admin_overview.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../../domain/usecases/get_admin_activity.dart';
import '../../domain/usecases/get_admin_items.dart';
import '../../domain/usecases/get_admin_overview.dart';
import '../../domain/usecases/set_item_moderation.dart';
import '../../domain/usecases/set_user_suspension.dart';

sealed class ModerationEvent extends Equatable {
  const ModerationEvent();
  @override
  List<Object?> get props => [];
}

final class AdminOverviewRequested extends ModerationEvent {
  const AdminOverviewRequested();
}

final class AdminActivityRequested extends ModerationEvent {
  const AdminActivityRequested({this.page = 1, this.type});
  final int page;
  final String? type;

  @override
  List<Object?> get props => [page, type];
}

final class AdminItemsRequested extends ModerationEvent {
  const AdminItemsRequested({
    this.page = 1,
    this.search,
    this.type,
    this.isClosed,
    this.isRemoved,
    this.isReturned,
  });
  final int page;
  final String? search;
  final String? type;
  final bool? isClosed;
  final bool? isRemoved;
  final bool? isReturned;

  @override
  List<Object?> get props => [
    page,
    search,
    type,
    isClosed,
    isRemoved,
    isReturned,
  ];
}

final class AdminItemModerationChanged extends ModerationEvent {
  const AdminItemModerationChanged({
    required this.itemId,
    required this.isRemoved,
    this.reason,
  });
  final String itemId;
  final bool isRemoved;
  final String? reason;

  @override
  List<Object?> get props => [itemId, isRemoved, reason];
}

final class AdminUserSuspensionChanged extends ModerationEvent {
  const AdminUserSuspensionChanged({
    required this.userId,
    required this.isSuspended,
    this.reason,
  });
  final String userId;
  final bool isSuspended;
  final String? reason;

  @override
  List<Object?> get props => [userId, isSuspended, reason];
}

class ModerationState extends Equatable {
  const ModerationState({
    this.overview,
    this.loading = false,
    this.busyItemId,
    this.failure,
    this.activityPage,
    this.activityLoading = false,
    this.activityType,
    this.activityFailure,
    this.adminItemsPage,
    this.adminItemsLoading = false,
    this.adminItemsFailure,
    this.adminItemsFilters = const AdminItemsFilters(),
    this.busyUserId,
  });
  final AdminOverview? overview;
  final bool loading;
  final String? busyItemId;
  final Failure? failure;
  final AdminActivityPage? activityPage;
  final bool activityLoading;
  final String? activityType;
  final Failure? activityFailure;
  final AdminItemPage? adminItemsPage;
  final bool adminItemsLoading;
  final Failure? adminItemsFailure;
  final AdminItemsFilters adminItemsFilters;
  final String? busyUserId;

  ModerationState copyWith({
    AdminOverview? overview,
    bool? loading,
    String? busyItemId,
    bool clearBusyItem = false,
    Failure? failure,
    bool clearFailure = false,
    AdminActivityPage? activityPage,
    bool? activityLoading,
    String? activityType,
    Failure? activityFailure,
    bool clearActivityFailure = false,
    AdminItemPage? adminItemsPage,
    bool? adminItemsLoading,
    Failure? adminItemsFailure,
    bool clearAdminItemsFailure = false,
    AdminItemsFilters? adminItemsFilters,
    String? busyUserId,
    bool clearBusyUser = false,
  }) => ModerationState(
    overview: overview ?? this.overview,
    loading: loading ?? this.loading,
    busyItemId: clearBusyItem ? null : busyItemId ?? this.busyItemId,
    failure: clearFailure ? null : failure ?? this.failure,
    activityPage: activityPage ?? this.activityPage,
    activityLoading: activityLoading ?? this.activityLoading,
    activityType: activityType ?? this.activityType,
    activityFailure: clearActivityFailure
        ? null
        : activityFailure ?? this.activityFailure,
    adminItemsPage: adminItemsPage ?? this.adminItemsPage,
    adminItemsLoading: adminItemsLoading ?? this.adminItemsLoading,
    adminItemsFailure: clearAdminItemsFailure
        ? null
        : adminItemsFailure ?? this.adminItemsFailure,
    adminItemsFilters: adminItemsFilters ?? this.adminItemsFilters,
    busyUserId: clearBusyUser ? null : busyUserId ?? this.busyUserId,
  );

  @override
  List<Object?> get props => [
    overview,
    loading,
    busyItemId,
    failure,
    activityPage,
    activityLoading,
    activityType,
    activityFailure,
    adminItemsPage,
    adminItemsLoading,
    adminItemsFailure,
    adminItemsFilters,
    busyUserId,
  ];
}

class ModerationBloc extends Bloc<ModerationEvent, ModerationState> {
  ModerationBloc(ModerationRepository repository)
    : _getOverview = GetAdminOverview(repository),
      _getActivity = GetAdminActivity(repository),
      _getAdminItems = GetAdminItems(repository),
      _setItemModeration = SetItemModeration(repository),
      _setUserSuspension = SetUserSuspension(repository),
      super(const ModerationState()) {
    on<AdminOverviewRequested>(_load);
    on<AdminActivityRequested>(_loadActivity);
    on<AdminItemsRequested>(_loadItems);
    on<AdminItemModerationChanged>(_moderate);
    on<AdminUserSuspensionChanged>(_suspend);
  }

  final GetAdminOverview _getOverview;
  final GetAdminActivity _getActivity;
  final GetAdminItems _getAdminItems;
  final SetItemModeration _setItemModeration;
  final SetUserSuspension _setUserSuspension;

  Future<void> _load(
    AdminOverviewRequested event,
    Emitter<ModerationState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearFailure: true));
    final result = await _getOverview();
    result.fold(
      (overview) => emit(state.copyWith(overview: overview, loading: false)),
      (failure) => emit(state.copyWith(loading: false, failure: failure)),
    );
  }

  Future<void> _loadActivity(
    AdminActivityRequested event,
    Emitter<ModerationState> emit,
  ) async {
    final previousType = state.activityType;
    emit(
      state.copyWith(
        activityLoading: true,
        clearActivityFailure: true,
        activityType: event.type,
      ),
    );
    final result = await _getActivity(page: event.page, type: event.type);
    result.fold(
      (page) {
        final previous = state.activityPage;
        final changedFilter = event.type != previousType;
        final merged = event.page > 1 && previous != null && !changedFilter
            ? AdminActivityPage(
                items: [...previous.items, ...page.items],
                page: page.page,
                totalPages: page.totalPages,
              )
            : page;
        emit(state.copyWith(activityPage: merged, activityLoading: false));
      },
      (failure) => emit(
        state.copyWith(activityLoading: false, activityFailure: failure),
      ),
    );
  }

  Future<void> _loadItems(
    AdminItemsRequested event,
    Emitter<ModerationState> emit,
  ) async {
    final filters = AdminItemsFilters(
      search: event.search,
      type: event.type,
      isClosed: event.isClosed,
      isRemoved: event.isRemoved,
      isReturned: event.isReturned,
    );
    emit(
      state.copyWith(
        adminItemsLoading: true,
        clearAdminItemsFailure: true,
        adminItemsFilters: filters,
      ),
    );
    final result = await _getAdminItems(
      page: event.page,
      search: event.search,
      type: event.type,
      isClosed: event.isClosed,
      isRemoved: event.isRemoved,
      isReturned: event.isReturned,
    );
    result.fold(
      (page) =>
          emit(state.copyWith(adminItemsPage: page, adminItemsLoading: false)),
      (failure) => emit(
        state.copyWith(adminItemsLoading: false, adminItemsFailure: failure),
      ),
    );
  }

  Future<void> _moderate(
    AdminItemModerationChanged event,
    Emitter<ModerationState> emit,
  ) async {
    emit(state.copyWith(busyItemId: event.itemId, clearFailure: true));
    final result = await _setItemModeration(
      event.itemId,
      isRemoved: event.isRemoved,
      reason: event.reason,
    );
    result.fold(
      (_) {
        final overview = state.overview;
        final page = state.adminItemsPage;
        emit(
          state.copyWith(
            overview: overview?.copyWith(
              items: overview.items.map((item) {
                if (item.id != event.itemId) return item;
                return item.copyWith(
                  isRemoved: event.isRemoved,
                  moderationReason: event.isRemoved ? event.reason : null,
                );
              }).toList(),
            ),
            adminItemsPage: page == null
                ? null
                : AdminItemPage(
                    items: page.items.map((item) {
                      if (item.id != event.itemId) return item;
                      return item.copyWith(
                        isRemoved: event.isRemoved,
                        moderationReason: event.isRemoved ? event.reason : null,
                      );
                    }).toList(),
                    page: page.page,
                    totalPages: page.totalPages,
                  ),
            clearBusyItem: true,
          ),
        );
        add(AdminActivityRequested(type: state.activityType));
      },
      (failure) => emit(state.copyWith(clearBusyItem: true, failure: failure)),
    );
  }

  Future<void> _suspend(
    AdminUserSuspensionChanged event,
    Emitter<ModerationState> emit,
  ) async {
    emit(state.copyWith(busyUserId: event.userId, clearFailure: true));
    final result = await _setUserSuspension(
      event.userId,
      isSuspended: event.isSuspended,
      reason: event.reason,
    );
    result.fold(
      (user) {
        final overview = state.overview;
        emit(
          state.copyWith(
            overview: overview?.copyWith(
              users: overview.users
                  .map((current) => current.id == user.id ? user : current)
                  .toList(),
            ),
            clearBusyUser: true,
          ),
        );
        add(AdminActivityRequested(type: state.activityType));
      },
      (failure) => emit(state.copyWith(clearBusyUser: true, failure: failure)),
    );
  }
}
