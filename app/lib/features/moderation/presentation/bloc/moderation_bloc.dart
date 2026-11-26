import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_overview.dart';
import '../../domain/repositories/moderation_repository.dart';
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
  });
  final AdminOverview? overview;
  final bool loading;
  final String? busyItemId;
  final Failure? failure;

  ModerationState copyWith({
    AdminOverview? overview,
    bool? loading,
    String? busyItemId,
    bool clearBusyItem = false,
    Failure? failure,
    bool clearFailure = false,
  }) => ModerationState(
    overview: overview ?? this.overview,
    loading: loading ?? this.loading,
    busyItemId: clearBusyItem ? null : busyItemId ?? this.busyItemId,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [overview, loading, busyItemId, failure];
}

class ModerationBloc extends Bloc<ModerationEvent, ModerationState> {
  ModerationBloc(ModerationRepository repository)
    : _getOverview = GetAdminOverview(repository),
      _setItemModeration = SetItemModeration(repository),
      super(const ModerationState()) {
    on<AdminOverviewRequested>(_load);
    on<AdminItemModerationChanged>(_moderate);
  }

  final GetAdminOverview _getOverview;
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
              users: overview.users,
              items: updatedItems,
            ),
            clearBusyItem: true,
          ),
        );
      },
      (failure) => emit(state.copyWith(clearBusyItem: true, failure: failure)),
    );
  }
}
