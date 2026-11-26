import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/claim.dart';
import '../../domain/repositories/claim_repository.dart';
import '../../domain/usecases/create_claim.dart';
import '../../domain/usecases/get_claims.dart';
import '../../domain/usecases/update_claim_status.dart';
import '../../domain/usecases/confirm_claim_return.dart';

sealed class ClaimsEvent extends Equatable {
  const ClaimsEvent();
  @override
  List<Object?> get props => [];
}

final class ClaimsRequested extends ClaimsEvent {
  const ClaimsRequested();
}

final class ClaimCreated extends ClaimsEvent {
  const ClaimCreated(this.itemId, this.answer);
  final String itemId, answer;
  @override
  List<Object?> get props => [itemId, answer];
}

final class ClaimStatusChanged extends ClaimsEvent {
  const ClaimStatusChanged(this.id, this.status);
  final String id, status;
  @override
  List<Object?> get props => [id, status];
}

final class ClaimReturnConfirmed extends ClaimsEvent {
  const ClaimReturnConfirmed(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ClaimsState extends Equatable {
  const ClaimsState({
    this.claims = const [],
    this.loading = false,
    this.saving = false,
    this.busyId,
    this.failure,
    this.created,
  });
  final List<Claim> claims;
  final bool loading, saving;
  final String? busyId;
  final Failure? failure;
  final Claim? created;
  ClaimsState copyWith({
    List<Claim>? claims,
    bool? loading,
    bool? saving,
    String? busyId,
    bool clearBusy = false,
    Failure? failure,
    bool clearFailure = false,
    Claim? created,
    bool clearCreated = false,
  }) => ClaimsState(
    claims: claims ?? this.claims,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    busyId: clearBusy ? null : busyId ?? this.busyId,
    failure: clearFailure ? null : failure ?? this.failure,
    created: clearCreated ? null : created ?? this.created,
  );
  @override
  List<Object?> get props => [
    claims,
    loading,
    saving,
    busyId,
    failure,
    created,
  ];
}

class ClaimsBloc extends Bloc<ClaimsEvent, ClaimsState> {
  ClaimsBloc(ClaimRepository repository)
    : _getClaims = GetClaims(repository),
      _createClaim = CreateClaim(repository),
      _updateStatus = UpdateClaimStatus(repository),
      _confirmReturn = ConfirmClaimReturn(repository),
      super(const ClaimsState()) {
    on<ClaimsRequested>(_load);
    on<ClaimCreated>(_create);
    on<ClaimStatusChanged>(_changeStatus);
    on<ClaimReturnConfirmed>(_confirmReturnEvent);
  }
  final GetClaims _getClaims;
  final CreateClaim _createClaim;
  final UpdateClaimStatus _updateStatus;
  final ConfirmClaimReturn _confirmReturn;
  Future<void> _load(ClaimsRequested event, Emitter<ClaimsState> emit) async {
    emit(state.copyWith(loading: true, clearFailure: true));
    final result = await _getClaims();
    result.fold(
      (claims) => emit(state.copyWith(claims: claims, loading: false)),
      (failure) => emit(state.copyWith(loading: false, failure: failure)),
    );
  }

  Future<void> _create(ClaimCreated event, Emitter<ClaimsState> emit) async {
    emit(state.copyWith(saving: true, clearFailure: true, clearCreated: true));
    final result = await _createClaim(event.itemId, event.answer);
    result.fold(
      (claim) => emit(state.copyWith(saving: false, created: claim)),
      (failure) => emit(state.copyWith(saving: false, failure: failure)),
    );
  }

  Future<void> _changeStatus(
    ClaimStatusChanged event,
    Emitter<ClaimsState> emit,
  ) async {
    emit(state.copyWith(busyId: event.id, clearFailure: true));
    final result = await _updateStatus(event.id, event.status);
    result.fold(
      (claim) => emit(
        state.copyWith(
          busyId: event.id,
          claims: state.claims
              .map(
                (item) => item.id == claim.id
                    ? claim
                    : item,
              )
              .toList(),
        ),
      ),
      (failure) => emit(state.copyWith(clearBusy: true, failure: failure)),
    );
    emit(state.copyWith(clearBusy: true));
  }

  Future<void> _confirmReturnEvent(
    ClaimReturnConfirmed event,
    Emitter<ClaimsState> emit,
  ) async {
    emit(state.copyWith(busyId: event.id, clearFailure: true));
    final result = await _confirmReturn(event.id);
    result.fold(
      (claim) => emit(state.copyWith(
        claims: state.claims.map((item) => item.id == claim.id ? claim : item).toList(),
      )),
      (failure) => emit(state.copyWith(clearBusy: true, failure: failure)),
    );
    emit(state.copyWith(clearBusy: true));
  }
}
