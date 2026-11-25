import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested(this.email, this.password);
  final String email, password;
  @override
  List<Object?> get props => [email, password];
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested(this.name, this.email, this.matricule, this.password);
  final String name, email, matricule, password;
  @override
  List<Object?> get props => [name, email, matricule, password];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

enum AuthStatus { checking, unauthenticated, authenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.loading = false,
    this.failure,
  });
  final AuthStatus status;
  final AppUser? user;
  final bool loading;
  final Failure? failure;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [status, user, loading, failure];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository)
    : _login = Login(_repository),
      _register = Register(_repository),
      _logout = Logout(_repository),
      super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    add(const AuthStarted());
  }

  final AuthRepository _repository;
  final Login _login;
  final Register _register;
  final Logout _logout;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final result = await _repository.currentUser();
    result.fold(
      (user) => emit(AuthState(status: AuthStatus.authenticated, user: user)),
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
    );
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearFailure: true));
    final result = await _login(event.email.trim(), event.password);
    await result.fold<Future<void>>(
      (session) async {
        final current = await _repository.currentUser();
        current.fold(
          (user) =>
              emit(AuthState(status: AuthStatus.authenticated, user: user)),
          (_) => emit(
            AuthState(status: AuthStatus.authenticated, user: session.user),
          ),
        );
      },
      (failure) async => emit(state.copyWith(loading: false, failure: failure)),
    );
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearFailure: true));
    final result = await _register(
      event.name.trim(),
      event.email.trim(),
      event.matricule.trim().toUpperCase(),
      event.password,
    );
    await result.fold<Future<void>>(
      (session) async {
        final current = await _repository.currentUser();
        current.fold(
          (user) =>
              emit(AuthState(status: AuthStatus.authenticated, user: user)),
          (_) => emit(
            AuthState(status: AuthStatus.authenticated, user: session.user),
          ),
        );
      },
      (failure) async => emit(state.copyWith(loading: false, failure: failure)),
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _logout();
    } catch (_) {}
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
