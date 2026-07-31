import 'package:dartchess/dartchess.dart' show Side;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/analysis/data/analysis_repository.dart';
import 'package:masteropening/features/analysis/domain/deviation.dart';
import 'package:masteropening/features/analysis/domain/gap.dart';
import 'package:masteropening/features/repertoire/data/repertoire_repository.dart';

/// Ein Weiß-Repertoire: 1.e4 e5 2.Nf3 Nc6 3.Bb5 (Spanisch), dazu 2...Nf6.
RepertoireTree whiteTree() => const RepertoireTree.empty()
    .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'])
    .withSanLine(['e4', 'e5', 'Nf3', 'Nf6', 'Nxe5']);

String gamePgn(List<String> sanMoves) {
  final buffer = StringBuffer('[Event "Test"]\n\n');
  for (var i = 0; i < sanMoves.length; i++) {
    if (i.isEven) buffer.write('${i ~/ 2 + 1}. ');
    buffer.write('${sanMoves[i]} ');
  }
  return '$buffer*';
}

void main() {
  group('Abweichungserkennung', () {
    test('erkennt, wenn der Gegner das Buch verlässt', () {
      final result = DeviationFinder.match(
        tree: whiteTree(),
        side: Side.white,
        // 1.e4 c5 — Sizilianisch steht nicht im Repertoire.
        sanMoves: ['e4', 'c5'],
      );

      expect(result.matchedPly, 1);
      expect(result.deviation, isNotNull);
      expect(result.deviation!.ply, 2);
      expect(result.deviation!.byUser, isFalse);
      expect(result.deviation!.playedSan, 'c5');
      expect(result.deviation!.expectedSan, 'e5');
    });

    test('erkennt einen eigenen Abweicher', () {
      final result = DeviationFinder.match(
        tree: whiteTree(),
        side: Side.white,
        // 1.e4 e5 2.Bc4 — das steht nicht im eigenen Repertoire.
        sanMoves: ['e4', 'e5', 'Bc4'],
      );

      expect(result.deviation!.byUser, isTrue);
      expect(result.deviation!.ply, 3);
      expect(result.deviation!.expectedSan, 'Nf3');
    });

    test('das Ende des Repertoires ist keine Abweichung', () {
      final result = DeviationFinder.match(
        tree: whiteTree(),
        side: Side.white,
        sanMoves: ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6', 'Ba4'],
      );

      expect(result.stayedInBook, isTrue);
      expect(result.matchedPly, 5, reason: 'so weit reicht das Buch');
    });

    test('eine Partie, die ganz im Buch bleibt, hat keine Abweichung', () {
      final result = DeviationFinder.match(
        tree: whiteTree(),
        side: Side.white,
        sanMoves: ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'],
      );

      expect(result.stayedInBook, isTrue);
      expect(result.matchedPly, 5);
    });

    test('ein unlesbarer Zug beendet den Vergleich, statt zu scheitern', () {
      final result = DeviationFinder.match(
        tree: whiteTree(),
        side: Side.white,
        sanMoves: ['e4', 'Qh9', 'Nf3'],
      );

      expect(result.matchedPly, 1);
      expect(result.deviation, isNull);
    });

    test('nimmt das Repertoire, dem die Partie am längsten folgt', () {
      final short = const RepertoireTree.empty().withSanLine(['e4']);

      final best = DeviationFinder.best(
        repertoires: [
          (tree: short, side: Side.white),
          (tree: whiteTree(), side: Side.white),
        ],
        side: Side.white,
        sanMoves: ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'],
      );

      expect(best!.index, 1);
      expect(best.match.matchedPly, 5);
    });

    test('ein Repertoire der falschen Farbe zählt nicht', () {
      final best = DeviationFinder.best(
        repertoires: [(tree: whiteTree(), side: Side.white)],
        side: Side.black,
        sanMoves: ['e4', 'e5'],
      );

      expect(best, isNull);
    });
  });

  group('Lückenbewertung', () {
    test('Punktverlust je Ausgang', () {
      expect(GapRanking.pointsLostFor(GameOutcome.loss), 1.0);
      expect(GapRanking.pointsLostFor(GameOutcome.draw), 0.5);
      expect(GapRanking.pointsLostFor(GameOutcome.win), 0.0);
    });

    test('die teuerste Lücke steht oben, nicht die häufigste', () {
      const oftenButHarmless = GapCandidate(
        repertoireId: 1,
        parentPathHash: 'a',
        fen: '-',
        missingSan: 'c5',
        missingUci: 'c7c5',
        occurrences: 20,
        pointsLost: 1,
      );
      const rareButCostly = GapCandidate(
        repertoireId: 1,
        parentPathHash: 'b',
        fen: '-',
        missingSan: 'g6',
        missingUci: 'g7g6',
        occurrences: 4,
        pointsLost: 4,
      );

      final sorted = GapRanking.sorted([oftenButHarmless, rareButCostly]);
      expect(sorted.first.missingSan, 'g6');
    });
  });

  group('PGN-Hauptvariante', () {
    test('liest die Züge einer Partie', () {
      expect(
        PgnIo.mainlineSan(gamePgn(['e4', 'c5', 'Nf3'])),
        ['e4', 'c5', 'Nf3'],
      );
    });

    test('unlesbarer Text ergibt eine leere Liste', () {
      expect(PgnIo.mainlineSan(''), isEmpty);
    });
  });

  group('Analyse gegen die Datenbank', () {
    late AppDatabase db;
    late RepertoireRepository repertoires;
    late AnalysisRepository analysis;
    late int repertoireId;

    setUp(() async {
      db = AppDatabase.withExecutor(NativeDatabase.memory());
      repertoires = RepertoireRepository(db);
      analysis = AnalysisRepository(db, repertoires);

      repertoireId = await repertoires.create(
        name: 'Offene Spiele',
        side: Side.white,
        tree: whiteTree(),
        source: RepertoireSource.manual,
      );
    });

    tearDown(() => db.close());

    Future<void> addGame(
      String id,
      List<String> moves, {
      GameOutcome outcome = GameOutcome.loss,
      Side side = Side.white,
    }) {
      return db.lichessDao.upsertAll([
        LichessGame(
          id: id,
          pgn: gamePgn(moves),
          side: side,
          outcome: outcome,
          speed: GameSpeed.blitz,
          plyCount: moves.length,
          rated: true,
          playedAt: DateTime(2026, 7, 20),
          importedAt: DateTime(2026, 7, 30),
        ),
      ]);
    }

    test('findet eine Lücke und merkt sie sich', () async {
      await addGame('g1', ['e4', 'c5', 'Nf3', 'd6']);

      final summary = await analysis.analyse();

      expect(summary.gamesAnalysed, 1);
      expect(summary.gapsFound, 1);

      final gaps = await analysis.openGaps();
      expect(gaps, hasLength(1));
      expect(gaps.first.missingSan, 'c5');
      expect(gaps.first.pointsLost, 1.0);
      expect(gaps.first.repertoireId, repertoireId);
    });

    test('zählt dieselbe Lücke hoch, statt sie zu verdoppeln', () async {
      await addGame('g1', ['e4', 'c5']);
      await analysis.analyse();

      await addGame('g2', ['e4', 'c5', 'Nf3'], outcome: GameOutcome.draw);
      await analysis.analyse();

      final gaps = await analysis.openGaps();
      expect(gaps, hasLength(1));
      expect(gaps.first.occurrences, 2);
      expect(gaps.first.pointsLost, 1.5);
    });

    test('eigene Abweichungen sind keine Lücken', () async {
      await addGame('g1', ['e4', 'e5', 'Bc4']);

      final summary = await analysis.analyse();

      expect(summary.ownDeviations, 1);
      expect(summary.gapsFound, 0);
      expect(await analysis.openGaps(), isEmpty);
    });

    test('markiert die Partie mit Halbzug und Repertoire', () async {
      await addGame('g1', ['e4', 'c5']);
      await analysis.analyse();

      final game = (await db.lichessDao.all()).single;
      expect(game.deviationPly, 2);
      expect(game.matchedRepertoireId, repertoireId);
    });

    test('eine Partie im Buch bekommt die Marke -1', () async {
      await addGame('g1', ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5']);
      await analysis.analyse();

      final game = (await db.lichessDao.all()).single;
      expect(game.deviationPly, -1);
    });

    test('beim zweiten Lauf bleiben geprüfte Partien liegen', () async {
      await addGame('g1', ['e4', 'c5']);
      await analysis.analyse();

      final second = await analysis.analyse();
      expect(second.gamesAnalysed, 0);
    });

    test('trägt eine Lücke ins Repertoire ein', () async {
      await addGame('g1', ['e4', 'c5']);
      await analysis.analyse();

      final gap = (await analysis.openGaps()).single;
      final hash = await analysis.addGapToRepertoire(gap);

      expect(hash, isNotNull);

      final row = (await db.repertoireDao.getById(repertoireId))!;
      final tree = repertoires.treeOf(row);
      expect(tree.nodeAtUciPath(['e2e4', 'c7c5']), isNotNull);

      // Erledigt: sie steht nicht mehr auf der Liste.
      expect(await analysis.openGaps(), isEmpty);
    });

    test('eine ausgeblendete Lücke kommt nicht zurück', () async {
      await addGame('g1', ['e4', 'c5']);
      await analysis.analyse();

      final gap = (await analysis.openGaps()).single;
      await analysis.dismissGap(gap.id);

      expect(await analysis.openGaps(), isEmpty);
    });

    test('ohne Repertoire passiert nichts', () async {
      await repertoires.delete(repertoireId);
      await addGame('g1', ['e4', 'c5']);

      final summary = await analysis.analyse();
      expect(summary.isEmpty, isTrue);
    });
  });

  group('Häufige Fehler', () {
    late AppDatabase db;
    late RepertoireRepository repertoires;
    late AnalysisRepository analysis;
    late int repertoireId;

    setUp(() async {
      db = AppDatabase.withExecutor(NativeDatabase.memory());
      repertoires = RepertoireRepository(db);
      analysis = AnalysisRepository(db, repertoires);

      repertoireId = await repertoires.create(
        name: 'Offene Spiele',
        side: Side.white,
        tree: whiteTree(),
        source: RepertoireSource.manual,
      );
    });

    tearDown(() => db.close());

    Future<void> attempt({
      required String pathHash,
      required bool correct,
      String expected = 'Bb5',
      String? played,
    }) async {
      final sessionId = await db.trainingDao.insertSession(
        uuid: 'session-${DateTime.now().microsecondsSinceEpoch}',
        mode: TrainingMode.smart,
        startedAt: DateTime(2026, 7, 30),
        endedAt: DateTime(2026, 7, 30, 0, 5),
        movesTotal: 1,
        movesCorrect: correct ? 1 : 0,
        linesLearned: 0,
        linesMastered: 0,
        xpEarned: 2,
        repertoireId: repertoireId,
      );

      await db.trainingDao.insertAttempts([
        TrainingAttemptsCompanion.insert(
          sessionId: sessionId,
          repertoireId: repertoireId,
          pathHash: pathHash,
          expectedSan: expected,
          playedSan: Value(played),
          correct: correct,
          msTaken: 2000,
          attemptedAt: DateTime(2026, 7, 30),
        ),
      ]);
    }

    test('zählt Versuche und Fehler je Zug', () async {
      final tree = whiteTree();
      final node = tree.nodeAtUciPath([
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
        'f1b5',
      ])!;

      await attempt(pathHash: node.pathHash, correct: false, played: 'Bc4');
      await attempt(pathHash: node.pathHash, correct: false, played: 'Bc4');
      await attempt(pathHash: node.pathHash, correct: true, played: 'Bb5');

      final mistakes = await analysis.mistakes();

      expect(mistakes, hasLength(1));
      expect(mistakes.first.attempts, 3);
      expect(mistakes.first.wrong, 2);
      expect(mistakes.first.expectedSan, 'Bb5');
      expect(mistakes.first.commonWrongSan, 'Bc4');
      expect(mistakes.first.sanLine, contains('Bb5'));
    });

    test('fehlerfreie Züge stehen nicht auf der Liste', () async {
      final tree = whiteTree();
      final node = tree.nodeAtUciPath([
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
        'f1b5',
      ])!;

      await attempt(pathHash: node.pathHash, correct: true, played: 'Bb5');

      expect(await analysis.mistakes(), isEmpty);
    });
  });
}
