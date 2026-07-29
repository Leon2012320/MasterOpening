import 'package:dartchess/dartchess.dart' show Side;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/settings/app_settings.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/settings/settings_store.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/features/home/presentation/home_screen.dart';
import 'package:masteropening/features/home/presentation/widgets/repertoire_card.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

const _settings = AppSettings(languageCode: 'de', boardAnimations: false);

/// Ein Repertoire, wie es die Startseite anzeigt — ohne Datenbank, damit der
/// Test unter der simulierten Uhr nicht auf echte Abfragen wartet.
RepertoireOverview _overview({
  int id = 1,
  String name = 'Spanisch',
  int dueCount = 0,
  Side side = Side.white,
}) {
  final tree = const RepertoireTree.empty().withSanLine([
    'e4',
    'e5',
    'Nf3',
    'Nc6',
    'Bb5',
  ]);
  final now = DateTime(2026, 7, 29);

  return RepertoireOverview(
    row: Repertoire(
      id: id,
      uuid: 'uuid-$id',
      createdAt: now,
      updatedAt: now,
      revision: 0,
      name: name,
      side: side,
      pgn: '',
      startFen: RepertoireTree.initialFen,
      ecoCodes: 'C60',
      source: RepertoireSource.library,
      sortOrder: 0,
      isArchived: false,
      nodeCount: tree.nodeCount,
      lineCount: 1,
    ),
    tree: tree,
    dueCount: dueCount,
  );
}

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    List<RepertoireOverview> overviews = const [],
    Map<int, int> due = const {},
  }) async {
    // Die Startseite leitet ihre Werte aus mehreren Providern ab; hier werden
    // die Blätter vorgegeben, damit keine echte Datenbank nötig ist.
    final db = AppDatabase.withExecutor(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsStoreProvider.overrideWithValue(
            InMemorySettingsStore(_settings),
          ),
          initialSettingsProvider.overrideWithValue(_settings),
          repertoireOverviewsProvider.overrideWithValue(
            AsyncValue.data(overviews),
          ),
          dueCountsProvider.overrideWithValue(AsyncValue.data(due)),
          userProfileProvider.overrideWithValue(
            AsyncValue.data(
              UserProfile(
                id: 1,
                totalXp: 0,
                streakCurrent: 4,
                streakBest: 9,
                streakFreezes: 2,
                updatedAt: DateTime(2026, 7, 29),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(AppTokens.dark),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          locale: const Locale('de'),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('ohne Repertoire erklärt sich der Bildschirm', (tester) async {
    await pumpHome(tester);

    expect(find.text('Noch kein Repertoire'), findsOneWidget);
    expect(find.text('Eröffnung hinzufügen'), findsWidgets);
    expect(find.byType(RepertoireCard), findsNothing);
  });

  testWidgets('zeigt die Serie aus dem Spielerstand', (tester) async {
    await pumpHome(tester);

    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('listet die Repertoires mit Name und Umfang', (tester) async {
    await pumpHome(
      tester,
      overviews: [
        _overview(),
        _overview(id: 2, name: 'Najdorf', side: Side.black),
      ],
    );

    expect(find.byType(RepertoireCard), findsNWidgets(2));
    expect(find.text('Spanisch'), findsOneWidget);
    expect(find.text('Najdorf'), findsOneWidget);
    expect(find.text('Weiß · 5 Züge'), findsOneWidget);
    expect(find.text('Schwarz · 5 Züge'), findsOneWidget);
  });

  testWidgets('zählt die fälligen Züge zusammen', (tester) async {
    await pumpHome(
      tester,
      overviews: [
        _overview(dueCount: 3),
        _overview(id: 2, name: 'Najdorf', dueCount: 5),
      ],
      due: {1: 3, 2: 5},
    );

    // Kachel „Fällig heute" nennt die Summe …
    expect(find.text('8'), findsOneWidget);
    // … und jede Karte ihren eigenen Anteil.
    expect(find.text('3 Züge fällig'), findsOneWidget);
    expect(find.text('5 Züge fällig'), findsOneWidget);
  });

  testWidgets('meldet ein Repertoire ohne Fälligkeiten als erledigt', (
    tester,
  ) async {
    await pumpHome(tester, overviews: [_overview()]);

    expect(find.text('Nichts fällig'), findsOneWidget);
  });

  testWidgets('bietet die Aktionen eines Repertoires an', (tester) async {
    await pumpHome(tester, overviews: [_overview()]);

    await tester.tap(find.byTooltip('Bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.text('Züge bearbeiten'), findsOneWidget);
    expect(find.text('Umbenennen'), findsOneWidget);
    expect(find.text('Lernfortschritt zurücksetzen'), findsOneWidget);
    expect(find.text('Löschen'), findsOneWidget);
  });

  testWidgets('das Hinzufügen-Blatt nennt alle drei Wege', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Eröffnung hinzufügen').last);
    await tester.pumpAndSettle();

    expect(find.text('Aus der Bibliothek'), findsOneWidget);
    expect(find.text('PGN einfügen'), findsOneWidget);
    expect(find.text('Lichess-Studie'), findsOneWidget);
  });
}
