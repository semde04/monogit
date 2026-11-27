import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lostfound_app/core/error/result.dart';
import 'package:lostfound_app/features/auth/presentation/bloc/auth_bloc.dart';

import 'fakes/fake_repositories.dart';

void main() {
  blocTest<AuthBloc, AuthState>(
    'une connexion réussie authentifie l’utilisateur',
    build: () => AuthBloc(FakeAuthRepository()),
    act: (bloc) async {
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthLoginRequested('ada@univ.fr', 'Password123!'));
    },
    verify: (bloc) {
      expect(bloc.state.status, AuthStatus.authenticated);
      expect(bloc.state.user, testUser);
      expect(bloc.state.loading, isFalse);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'une connexion refusée reste non authentifiée avec une erreur',
    build: () => AuthBloc(
      FakeAuthRepository(
        currentResult: const Err(failure),
        loginResult: const Err(failure),
      ),
    ),
    act: (bloc) async {
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthLoginRequested('ada@univ.fr', 'wrong'));
    },
    verify: (bloc) {
      expect(bloc.state.status, AuthStatus.unauthenticated);
      expect(bloc.state.failure, isNotNull);
      expect(bloc.state.loading, isFalse);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'une déconnexion révoque la session',
    build: () => AuthBloc(FakeAuthRepository()),
    act: (bloc) async {
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AuthLogoutRequested());
    },
    verify: (bloc) => expect(bloc.state.status, AuthStatus.unauthenticated),
  );

  blocTest<AuthBloc, AuthState>(
    'masque les erreurs de lecture de session au démarrage',
    build: () => AuthBloc(FakeAuthRepository(throwOnCurrent: true)),
    act: (bloc) async => Future<void>.delayed(Duration.zero),
    verify: (bloc) {
      expect(bloc.state.status, AuthStatus.unauthenticated);
      expect(bloc.state.failure, isNull);
    },
  );
}
