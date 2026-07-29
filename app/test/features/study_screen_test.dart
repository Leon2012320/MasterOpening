import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/settings/app_settings.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/settings/settings_store.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/widgets/chess_board.dart';
import 'package:masteropening/features/learn/presentation/study_screen.dart';
import 'package:masteropening/features/learn/presentation/widgets/study_controls.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Ohne Brettanimation muss kein Test auf eine Zuganimation warten.
const _settings = AppSettings(languageCode: 'de', boardAnimations: false);

/// 1. e4 e5 2. Sf3 Sc6 3. Lb5 (3. Lc4), daneben 1. e4 c5 2. Sf3.
RepertoireTree _spanish() => const RepertoireTree.empty()
    .withSanLine(
      ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'],
      leafComment: 'Die spanische Partie.',
    )
    .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bc4'])
    .withSanLine(['e4', 'c5', 'Nf3']);

void main() {
  Future<void> pumpStudy(
    WidgetTester tester, {
    RepertoireTree? tree,
    String title = 'Spanisch',
    Side side = Side.white,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(
            InMemorySettingsStore(_settings),
          ),
          initialSettingsProvider.overrideWithValue(_settings),
        ],
        child: MaterialApp(
          theme: AppTheme.build(AppTokens.dark),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          locale: const Locale('de'),
          home: StudyView(
            title: title,
            tree: tree ?? _spanish(),
            side: side,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Die Knöpfe der Zugleiste stehen in fester Reihenfolge:
  /// 0 Anfang, 1 zurück, 2 abspielen, 3 vor, 4 Ende.
  Future<void> tapControl(WidgetTester tester, int index) async {
    await tester.tap(
      find
          .descendant(
            of: find.byType(StudyControls),
            matching: find.byType(InkWell),
          )
          .at(index),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('zeigt Titel, Brett und Zugliste', (tester) async {
    await pumpStudy(tester);

    expect(find.text('Spanisch'), findsOneWidget);
    expect(find.byType(AppChessboard), findsOneWidget);
    // Die Zugliste notiert deutsch, gespeichert ist englisches SAN.
    expect(find.text('Sf3'), findsWidgets);
    expect(find.text('Lb5'), findsOneWidget);
  });

  testWidgets('zeigt Haupt- und Nebenvarianten', (tester) async {
    await pumpStudy(tester);

    expect(find.text('Lb5'), findsOneWidget);
    expect(find.text('Lc4'), findsOneWidget);
    expect(find.text('c5'), findsOneWidget);
  });

  testWidgets('beginnt an der Grundstellung', (tester) async {
    await pumpStudy(tester);

    expect(find.text('Grundstellung'), findsOneWidget);
  });

  testWidgets('meldet an einer Verzweigung die Zahl der Wege', (tester) async {
    await pumpStudy(tester);

    await tapControl(tester, 3);

    expect(find.text('Hier geht es auf 2 Wegen weiter'), findsOneWidget);
  });

  testWidgets('springt ans Ende und zeigt den Kommentar', (tester) async {
    await pumpStudy(tester);

    await tapControl(tester, 4);

    // Der Kommentar steht sowohl im Streifen unter dem Brett als auch in der
    // Zugliste — beide Stellen sollen ihn zeigen.
    expect(find.text('Die spanische Partie.'), findsNWidgets(2));
  });

  testWidgets('kommt über den Anfang-Knopf zurück', (tester) async {
    await pumpStudy(tester);

    await tapControl(tester, 4);
    expect(find.text('Grundstellung'), findsNothing);

    await tapControl(tester, 0);
    expect(find.text('Grundstellung'), findsOneWidget);
  });

  testWidgets('springt über die Zugliste direkt zu einem Zug', (tester) async {
    await pumpStudy(tester);

    await tester.tap(find.text('Lc4'));
    await tester.pumpAndSettle();

    // Lc4 ist ein Blatt — von dort geht es nicht weiter.
    expect(find.text('Ende der Variante'), findsOneWidget);
  });

  testWidgets('richtet das Brett nach der Farbe des Repertoires aus', (
    tester,
  ) async {
    await pumpStudy(tester, side: Side.black);

    expect(
      tester.widget<AppChessboard>(find.byType(AppChessboard)).orientation,
      Side.black,
    );
  });

  testWidgets('dreht das Brett', (tester) async {
    await pumpStudy(tester);

    expect(
      tester.widget<AppChessboard>(find.byType(AppChessboard)).orientation,
      Side.white,
    );

    await tester.tap(find.byTooltip('Brett drehen'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<AppChessboard>(find.byType(AppChessboard)).orientation,
      Side.black,
    );
  });

  testWidgets('spielt automatisch ab und hält am Ende der Variante an', (
    tester,
  ) async {
    await pumpStudy(tester);

    await tester.tap(find.byTooltip('Automatisch abspielen'));
    await tester.pump();

    // Fünf Halbzüge im Takt von 1,1 s.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 1100));
    }

    // Der Kommentar steht sowohl im Streifen unter dem Brett als auch in der
    // Zugliste — beide Stellen sollen ihn zeigen.
    expect(find.text('Die spanische Partie.'), findsNWidgets(2));
    // Der Knopf steht wieder auf „abspielen" — der Takt läuft nicht weiter.
    expect(find.byTooltip('Automatisch abspielen'), findsOneWidget);
  });

  testWidgets('ein leeres Repertoire erklärt sich, statt leer zu bleiben', (
    tester,
  ) async {
    await pumpStudy(tester, tree: const RepertoireTree.empty(), title: 'Leer');

    expect(find.text('Noch keine Züge'), findsOneWidget);
    expect(find.byType(AppChessboard), findsNothing);
  });
}
