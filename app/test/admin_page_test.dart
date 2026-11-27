import 'package:flutter_test/flutter_test.dart';
import 'package:lostfound_app/core/di/injection.dart';
import 'package:lostfound_app/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:lostfound_app/features/moderation/presentation/bloc/moderation_bloc.dart';
import 'package:lostfound_app/features/moderation/presentation/pages/admin_page.dart';
import 'package:material_ui/material_ui.dart';

import 'fakes/fake_repositories.dart';

void main() {
  setUp(() {
    getIt.reset();
    getIt.registerFactory<ModerationRepository>(
      () => FakeModerationRepository(),
    );
    getIt.registerFactory(() => ModerationBloc(getIt<ModerationRepository>()));
  });

  tearDown(() => getIt.reset());

  Future<void> prepareTester(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('affiche un tableau de bord admin complet', (tester) async {
    await prepareTester(tester);
    await tester.pumpWidget(const MaterialApp(home: AdminPage()));
    await tester.pumpAndSettle();

    expect(find.text('Centre de supervision'), findsOneWidget);
    expect(find.text('Vue d’ensemble'), findsWidgets);
    expect(find.text('Nouveau compte créé : Ada'), findsOneWidget);
    expect(find.text('Sac'), findsOneWidget);
    expect(find.text('ada@univ.fr'), findsOneWidget);
  });

  testWidgets('filtre les annonces et les comptes depuis la recherche', (
    tester,
  ) async {
    await prepareTester(tester);
    await tester.pumpWidget(const MaterialApp(home: AdminPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'introuvable');
    await tester.pumpAndSettle();

    expect(find.text('Sac'), findsNothing);
    expect(find.text('ada@univ.fr'), findsNothing);
  });
}
