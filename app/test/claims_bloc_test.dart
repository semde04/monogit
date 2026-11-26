import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lostfound_app/core/error/result.dart';
import 'package:lostfound_app/features/claims/presentation/bloc/claims_bloc.dart';

import 'fakes/fake_repositories.dart';

void main() {
  blocTest<ClaimsBloc, ClaimsState>(
    'charge les réclamations de l’utilisateur',
    build: () => ClaimsBloc(FakeClaimRepository()),
    act: (bloc) => bloc.add(const ClaimsRequested()),
    verify: (bloc) {
      expect(bloc.state.claims, [testClaim]);
      expect(bloc.state.loading, isFalse);
    },
  );

  blocTest<ClaimsBloc, ClaimsState>(
    'signale une erreur de chargement',
    build: () =>
        ClaimsBloc(FakeClaimRepository(claimsResult: const Err(failure))),
    act: (bloc) => bloc.add(const ClaimsRequested()),
    verify: (bloc) => expect(bloc.state.failure, failure),
  );

  blocTest<ClaimsBloc, ClaimsState>(
    'met à jour le statut puis libère l’état d’occupation',
    build: () => ClaimsBloc(
      FakeClaimRepository(
        statusResult: Ok(testClaim.copyWith(status: 'accepted')),
      ),
    ),
    act: (bloc) {
      bloc.add(const ClaimsRequested());
      bloc.add(const ClaimStatusChanged('c1', 'accepted'));
    },
    verify: (bloc) {
      expect(bloc.state.busyId, isNull);
      expect(bloc.state.claims.single.status, 'accepted');
    },
  );

  blocTest<ClaimsBloc, ClaimsState>(
    'conserve la réclamation et affiche l’erreur si le statut échoue',
    build: () =>
        ClaimsBloc(FakeClaimRepository(statusResult: const Err(failure))),
    act: (bloc) => bloc.add(const ClaimStatusChanged('c1', 'accepted')),
    verify: (bloc) {
      expect(bloc.state.busyId, isNull);
      expect(bloc.state.failure, failure);
    },
  );
}
