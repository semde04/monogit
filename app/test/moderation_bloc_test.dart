import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lostfound_app/core/error/result.dart';
import 'package:lostfound_app/features/moderation/presentation/bloc/moderation_bloc.dart';

import 'fakes/fake_repositories.dart';

void main() {
  blocTest<ModerationBloc, ModerationState>(
    'charge le tableau de bord administrateur',
    build: () => ModerationBloc(FakeModerationRepository()),
    act: (bloc) => bloc.add(const AdminOverviewRequested()),
    verify: (bloc) {
      expect(bloc.state.overview, testOverview);
      expect(bloc.state.loading, isFalse);
    },
  );

  blocTest<ModerationBloc, ModerationState>(
    'refuse le tableau de bord à un compte non administrateur',
    build: () => ModerationBloc(
      FakeModerationRepository(overviewResult: const Err(failure)),
    ),
    act: (bloc) => bloc.add(const AdminOverviewRequested()),
    verify: (bloc) {
      expect(bloc.state.overview, isNull);
      expect(bloc.state.failure, failure);
    },
  );

  blocTest<ModerationBloc, ModerationState>(
    'reflète le retrait d’une annonce dans le tableau de bord',
    build: () => ModerationBloc(FakeModerationRepository()),
    act: (bloc) {
      bloc.add(const AdminOverviewRequested());
      bloc.add(
        const AdminItemModerationChanged(
          itemId: 'i1',
          isRemoved: true,
          reason: 'Spam',
        ),
      );
    },
    verify: (bloc) {
      expect(bloc.state.busyItemId, isNull);
      expect(bloc.state.overview!.items.single.isRemoved, isTrue);
      expect(bloc.state.overview!.items.single.moderationReason, 'Spam');
    },
  );

  blocTest<ModerationBloc, ModerationState>(
    'libère l’état d’occupation après un échec de modération',
    build: () => ModerationBloc(
      FakeModerationRepository(moderationResult: const Err(failure)),
    ),
    act: (bloc) => bloc.add(
      const AdminItemModerationChanged(itemId: 'i1', isRemoved: true),
    ),
    verify: (bloc) {
      expect(bloc.state.busyItemId, isNull);
      expect(bloc.state.failure, failure);
    },
  );

  blocTest<ModerationBloc, ModerationState>(
    'charge le journal d’activité avec son filtre',
    build: () => ModerationBloc(FakeModerationRepository()),
    act: (bloc) =>
        bloc.add(const AdminActivityRequested(type: 'auth.register')),
    verify: (bloc) {
      expect(bloc.state.activityPage, testActivityPage);
      expect(bloc.state.activityType, 'auth.register');
      expect(bloc.state.activityLoading, isFalse);
      expect(bloc.state.activityFailure, isNull);
    },
  );

  blocTest<ModerationBloc, ModerationState>(
    'signale un échec de chargement du journal d’activité',
    build: () => ModerationBloc(
      FakeModerationRepository(activityResult: const Err(failure)),
    ),
    act: (bloc) => bloc.add(const AdminActivityRequested()),
    verify: (bloc) {
      expect(bloc.state.activityPage, isNull);
      expect(bloc.state.activityFailure, failure);
      expect(bloc.state.activityLoading, isFalse);
    },
  );
}
