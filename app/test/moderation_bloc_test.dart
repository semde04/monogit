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
    'charge toutes les publications avec leur pagination',
    build: () => ModerationBloc(FakeModerationRepository()),
    act: (bloc) => bloc.add(const AdminItemsRequested()),
    verify: (bloc) {
      expect(bloc.state.adminItemsPage, testAdminItemsPage);
      expect(bloc.state.adminItemsLoading, isFalse);
      expect(bloc.state.adminItemsFailure, isNull);
    },
  );

  final filterRepository = FakeModerationRepository();
  blocTest<ModerationBloc, ModerationState>(
    'filtre les publications sur les objets retrouvés',
    build: () => ModerationBloc(filterRepository),
    act: (bloc) => bloc.add(const AdminItemsRequested(isReturned: true)),
    verify: (bloc) {
      expect(filterRepository.lastItemsReturned, isTrue);
      expect(filterRepository.lastItemsPage, 1);
      expect(bloc.state.adminItemsFilters.isReturned, isTrue);
      expect(bloc.state.adminItemsPage, testAdminItemsPage);
    },
  );

  final suspensionRepository = FakeModerationRepository();
  blocTest<ModerationBloc, ModerationState>(
    'suspend un étudiant et rafraîchit le journal',
    build: () => ModerationBloc(suspensionRepository),
    act: (bloc) {
      bloc.add(const AdminOverviewRequested());
      bloc.add(
        const AdminUserSuspensionChanged(
          userId: 'u1',
          isSuspended: true,
          reason: 'Abus de signalement',
        ),
      );
    },
    verify: (bloc) {
      expect(suspensionRepository.suspendedUserId, 'u1');
      expect(suspensionRepository.suspendedValue, isTrue);
      expect(suspensionRepository.suspensionReason, 'Abus de signalement');
      expect(bloc.state.overview!.users.single.isSuspended, isTrue);
      expect(bloc.state.busyUserId, isNull);
      expect(bloc.state.failure, isNull);
      expect(bloc.state.activityPage, testActivityPage);
    },
  );

  blocTest<ModerationBloc, ModerationState>(
    'signale un échec de suspension',
    build: () => ModerationBloc(
      FakeModerationRepository(suspensionResult: const Err(failure)),
    ),
    act: (bloc) => bloc.add(
      const AdminUserSuspensionChanged(
        userId: 'u1',
        isSuspended: true,
        reason: 'Abus',
      ),
    ),
    verify: (bloc) {
      expect(bloc.state.busyUserId, isNull);
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
