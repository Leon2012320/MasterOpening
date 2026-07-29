import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/app.dart';

void main() {
  testWidgets('die App startet ohne Fehler', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MasterOpeningApp()));
    await tester.pumpAndSettle();

    expect(find.text('MasterOpening'), findsOneWidget);
  });
}
