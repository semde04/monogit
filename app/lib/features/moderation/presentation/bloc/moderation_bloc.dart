import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_activity.dart';
import '../../domain/entities/admin_overview.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../../domain/usecases/get_admin_activity.dart';
import '../../domain/usecases/get_admin_overview.dart';
import '../../domain/usecases/set_item_moderation.dart';

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
  });
  final AdminOverview? overview;
  final bool loading;
  final String? busyItemId;
  final Failure? failure;
  final AdminActivityPage? activityPage;
  final bool activityLoading;
  final String? activityType;
  final Failure? activityFailure;

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
  ];
}

class ModerationBloc extends Bloc<ModerationEvent, ModerationState> {
  ModerationBloc(ModerationRepository repository)
    : _getOverview = GetAdminOverview(repository),
      _getActivity = GetAdminActivity(repository),
      _setItemModeration = SetItemModeration(repository),
      super(const ModerationState()) {
    on<AdminOverviewRequested>(_load);
    on<AdminActivityRequested>(_loadActivity);
    on<AdminItemModerationChanged>(_moderate);
  }

  final GetAdminOverview _getOverview;
  final GetAdminActivity _getActivity;
  final SetItemModeration _setItemModeration;

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
        if (overview == null) return;
        final updatedItems = overview.items.map((item) {
          if (item.id != event.itemId) return item;
          return item.copyWith(
            isRemoved: event.isRemoved,
            moderationReason: event.isRemoved ? event.reason : null,
          );
        }).toList();
        emit(
          state.copyWith(
            overview: AdminOverview(
              userCount: overview.userCount,
              itemCount: overview.itemCount,
              claimCount: overview.claimCount,
              pendingClaimCount: overview.pendingClaimCount,
              newUsersToday: overview.newUsersToday,
              actionsToday: overview.actionsToday,
              users: overview.users,
              items: updatedItems,
            ),
            clearBusyItem: true,
          ),
        );
        add(AdminActivityRequested(type: state.activityType));
      },
      (failure) => emit(state.copyWith(clearBusyItem: true, failure: failure)),
    );
  }
}
