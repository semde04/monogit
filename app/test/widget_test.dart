import 'package:flutter_test/flutter_test.dart';
import 'package:lostfound_app/features/auth/presentation/pages/login_page.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('BrandMark affiche le nom de l’application', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BrandMark())),
    );
    expect(find.text('LostFound'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
