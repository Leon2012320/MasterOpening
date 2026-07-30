import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/lichess/data/lichess_providers.dart';
import 'package:masteropening/features/lichess/data/lichess_repository.dart';
import 'package:masteropening/features/lichess/domain/lichess_account.dart';
import 'package:masteropening/features/lichess/domain/opening_stats.dart';
import 'package:masteropening/features/lichess/presentation/lichess_screen.dart';
import 'package:masteropening/features/lichess/presentation/widgets/game_row.dart';
import 'package:masteropening/features/lichess/presentation/widgets/opening_stat_row.dart';

import '../helpers/pump_app.dart';

final _account = LichessAccount.fromJson(const {
  'id': 'leon',
  'username': 'Leon',
  'title': 'FM',
  'count': {'all': 512},
  'perfs': {
    'blitz': {'games': 400, 'rating': 1850},
    'rapid': {'games': 112, 'rating': 1920},
  },
});

LichessGame _game(String id, {GameOutcome outcome = GameOutcome.win}) {
  return LichessGame(
    id: id,
    pgn: '1. e4 c5',
    side: Side.white,
    outcome: outcome,
    speed: GameSpeed.blitz,
    eco: 'B90',
    openingName: 'Sicilian Defense: Najdorf Variation',
    opponentName: 'gegner',
    opponentRating: 1800,
    ownRating: 1850,
    plyCount: 4,
    rated: true,
    playedAt: DateTime(2026, 7, 20),
    importedAt: DateTime(2026, 7, 30),
  );
}

void main() {
  group('Lichess-Tab', () {
    testWidgets('ohne Konto führt er zum Verbinden und erklärt den Zugriff', (
      tester,
    ) async {
      var connectCalls = 0;

      await pumpWidgetInApp(
        tester,
        LichessView(
          state: const LichessState(),
          games: const [],
          openings: const [],
          onConnect: () async => connectCalls++,
        ),
      );

      expect(find.text('Lichess noch nicht verbunden'), findsOneWidget);
      expect(find.textContaining('liest nur dein Profil'), findsOneWidget);

      await tester.tap(find.text('Mit Lichess verbinden'));
      await tester.pumpAndSettle();
      expect(connectCalls, 1);
    });

    testWidgets('während des Verbindens ist der Knopf gesperrt', (
      tester,
    ) async {
      var connectCalls = 0;

      await pumpWidgetInApp(
        tester,
        LichessView(
          state: const LichessState(status: LichessStatus.connecting),
          games: const [],
          openings: const [],
          onConnect: () async => connectCalls++,
        ),
        // Der Spinner im Knopf dreht sich endlos — `pumpAndSettle` käme nie
        // zur Ruhe.
        settle: false,
      );

      // Der Knopf trägt einen Spinner statt der Beschriftung und nimmt
      // solange keinen Druck an.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(connectCalls, 0);
    });

    testWidgets('zeigt Profil, Wertungen und den Importstand', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpWidgetInApp(
        tester,
        LichessView(
          state: LichessState(
            account: _account,
            lastImport: const LichessImportResult(
              imported: 12,
              skipped: 1,
              total: 30,
            ),
          ),
          games: [for (var i = 0; i < 30; i++) _game('g$i')],
          openings: const [
            OpeningStat(
              family: 'Sicilian Defense',
              side: Side.white,
              eco: 'B90',
              wins: 20,
              draws: 4,
              losses: 6,
            ),
          ],
        ),
      );

      expect(find.text('Leon'), findsOneWidget);
      expect(find.text('FM'), findsOneWidget);
      expect(find.text('Blitz 1850'), findsOneWidget);
      expect(find.text('30 Partien gespeichert'), findsOneWidget);
      expect(find.text('12 neue Partien importiert'), findsOneWidget);

      expect(find.byType(OpeningStatRow), findsOneWidget);
      expect(find.text('Sicilian Defense'), findsOneWidget);
      expect(find.text('73 %'), findsOneWidget, reason: '22 von 30 Punkten');

      // Nur die letzten acht Partien, sonst wird der Tab zur Liste.
      expect(find.byType(GameRow), findsNWidgets(8));
    });

    testWidgets('verbunden, aber ohne Partien: der Importknopf steht bereit', (
      tester,
    ) async {
      var imports = 0;

      await pumpWidgetInApp(
        tester,
        LichessView(
          state: LichessState(account: _account),
          games: const [],
          openings: const [],
          onImport: () async => imports++,
        ),
      );

      expect(find.text('Noch keine Partien'), findsWidgets);

      await tester.tap(find.text('Partien importieren'));
      await tester.pumpAndSettle();
      expect(imports, 1);
    });

    testWidgets('ein Fehler steht sichtbar über dem Inhalt', (tester) async {
      await pumpWidgetInApp(
        tester,
        const LichessView(
          state: LichessState(error: 'Zeitüberschreitung'),
          games: [],
          openings: [],
        ),
      );

      expect(
        find.textContaining('Zeitüberschreitung'),
        findsOneWidget,
      );
    });
  });
}
