import 'dart:math';

import 'package:dartchess/dartchess.dart' show Move, Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:masteropening/features/training/domain/training_session.dart';

final _now = DateTime(2026, 7, 30, 20);

/// 1. e4 e5 2. Sf3 Sc6 3. Lb5 — drei weisse Zuege, zwei schwarze Antworten.
RepertoireTree _spanish() => const RepertoireTree.empty().withSanLine([
  'e4',
  'e5',
  'Nf3',
  'Nc6',
  'Bb5',
]);

TrainingLine _line({
  RepertoireTree? tree,
  Side side = Side.white,
  double weight = 1,
  int repertoireId = 1,
}) {
  final actual = tree ?? _spanish();
  return TrainingLine(
    repertoireId: repertoireId,
    repertoireName: 'Spanisch',
    side: side,
    startFen: actual.startFen,
    line: actual.lines().first,
    weight: weight,
  );
}

NodeProgressData _progress(
  String pathHash, {
  FsrsState state = FsrsState.review,
  DateTime? due,
  int correct = 0,
  int wrong = 0,
}) {
  return NodeProgressData(
    repertoireId: 1,
    pathHash: pathHash,
    state: state,
    stability: 10,
    difficulty: 5,
    due: due ?? _now,
    reps: correct + wrong,
    lapses: wrong,
    correctCount: correct,
    wrongCount: wrong,
    updatedAt: _now,
  );
}

void main() {
  group('Planer', () {
    TrainingSource source({
      Map<String, NodeProgressData> progress = const {},
      RepertoireTree? tree,
    }) {
      return TrainingSource(
        repertoireId: 1,
        name: 'Spanisch',
        side: Side.white,
        tree: tree ?? _spanish(),
        progress: progress,
      );
    }

    test('nimmt ungelernte Varianten auf', () {
      final plan = TrainingPlanner.build(
        sources: [source()],
        options: PlannerOptions(mode: TrainingMode.smart, now: _now),
      );

      expect(plan, hasLength(1));
      expect(plan.single.weight, greaterThan(0));
      expect(plan.single.ownMoves.map((n) => n.san), ['e4', 'Nf3', 'Bb5']);
    });

    test('überspringt Varianten ohne eigene Züge', () {
      // Ein Repertoire für Schwarz, dessen einzige Linie mit einem weissen
      // Zug endet, hat trotzdem eigene Züge — hier eine Linie aus nur einem
      // weissen Zug, in der Schwarz nie am Zug ist.
      final tree = const RepertoireTree.empty().withSanLine(['e4']);
      final plan = TrainingPlanner.build(
        sources: [
          TrainingSource(
            repertoireId: 1,
            name: 'Leer',
            side: Side.black,
            tree: tree,
            progress: const {},
          ),
        ],
        options: PlannerOptions(mode: TrainingMode.smart, now: _now),
      );

      expect(plan, isEmpty);
    });

    test('gewichtet fehleranfällige Züge höher', () {
      final tree = const RepertoireTree.empty()
          .withSanLine(['e4', 'e5', 'Nf3'])
          .withSanLine(['d4', 'd5', 'c4']);

      final sauber = tree.nodeAtUciPath(['e2e4'])!;
      final wacklig = tree.nodeAtUciPath(['d2d4'])!;

      final plan = TrainingPlanner.build(
        sources: [
          source(
            tree: tree,
            progress: {
              sauber.pathHash: _progress(sauber.pathHash, correct: 10),
              tree.nodeAtUciPath(['e2e4', 'e7e5', 'g1f3'])!.pathHash: _progress(
                tree.nodeAtUciPath(['e2e4', 'e7e5', 'g1f3'])!.pathHash,
                correct: 10,
              ),
              wacklig.pathHash: _progress(
                wacklig.pathHash,
                correct: 2,
                wrong: 8,
              ),
              tree.nodeAtUciPath(['d2d4', 'd7d5', 'c2c4'])!.pathHash: _progress(
                tree.nodeAtUciPath(['d2d4', 'd7d5', 'c2c4'])!.pathHash,
                correct: 2,
                wrong: 8,
              ),
            },
          ),
        ],
        options: PlannerOptions(mode: TrainingMode.smart, now: _now),
      );

      expect(plan.first.line.nodes.first.san, 'd4');
    });

    test('lässt nicht fällige Varianten weg, wenn man das verlangt', () {
      final tree = _spanish();
      final progress = {
        for (final node in tree.walk())
          if (node.movedBy == Side.white)
            node.pathHash: _progress(
              node.pathHash,
              due: _now.add(const Duration(days: 7)),
              correct: 5,
            ),
      };

      final ohne = TrainingPlanner.build(
        sources: [source(progress: progress)],
        options: PlannerOptions(
          mode: TrainingMode.smart,
          now: _now,
          includeNotDue: false,
        ),
      );
      final mit = TrainingPlanner.build(
        sources: [source(progress: progress)],
        options: PlannerOptions(mode: TrainingMode.smart, now: _now),
      );

      expect(ohne, isEmpty);
      expect(mit, hasLength(1));
    });

    test('hält die Obergrenze ein', () {
      var tree = const RepertoireTree.empty();
      for (final second in ['e5', 'c5', 'e6', 'c6', 'd5', 'd6', 'g6', 'Nf6']) {
        tree = tree.withSanLine(['e4', second]);
      }

      final plan = TrainingPlanner.build(
        sources: [source(tree: tree)],
        options: PlannerOptions(
          mode: TrainingMode.smart,
          now: _now,
          maxLines: 3,
        ),
      );

      expect(plan, hasLength(3));
    });

    test('mischt im Puzzle-Modus', () {
      var tree = const RepertoireTree.empty();
      for (final second in ['e5', 'c5', 'e6', 'c6', 'd5', 'd6', 'g6', 'Nf6']) {
        tree = tree.withSanLine(['e4', second, 'Nf3']);
      }

      List<String> idsWith(int seed) => TrainingPlanner.build(
        sources: [source(tree: tree)],
        options: PlannerOptions(
          mode: TrainingMode.puzzle,
          now: _now,
          maxLines: 4,
          random: Random(seed),
        ),
      ).map((l) => l.id).toList();

      expect(idsWith(1), isNot(idsWith(9)));
    });
  });

  group('Ablauf einer Einheit', () {
    TrainingSessionState start({List<TrainingLine>? lines}) =>
        TrainingSessionState.start(
          mode: TrainingMode.smart,
          lines: lines ?? [_line()],
          now: _now,
        );

    test('fragt zuerst den eigenen ersten Zug ab', () {
      final session = start();

      expect(session.phase, TrainingPhase.awaitingMove);
      expect(session.expectedNode!.san, 'e4');
      expect(session.ply, 0);
    });

    test('spielt die Züge des Gegners selbst vor', () {
      var session = start()
          .submitMove(Move.parse('e2e4')!, millis: 1000)
          .advance();

      // e5 hat die App gespielt, gefragt ist wieder Weiss.
      expect(session.ply, 2);
      expect(session.expectedNode!.san, 'Nf3');

      session = session.submitMove(Move.parse('g1f3')!, millis: 1000).advance();
      expect(session.expectedNode!.san, 'Bb5');
    });

    test('beginnt bei einem Schwarz-Repertoire mit dem Gegnerzug', () {
      final session = TrainingSessionState.start(
        mode: TrainingMode.smart,
        lines: [_line(side: Side.black)],
        now: _now,
      );

      // 1. e4 steht schon auf dem Brett, gefragt ist 1…e5.
      expect(session.ply, 1);
      expect(session.expectedNode!.san, 'e5');
    });

    test('erkennt den richtigen Zug', () {
      final session = start().submitMove(Move.parse('e2e4')!, millis: 800);

      expect(session.phase, TrainingPhase.correct);
      expect(session.movesCorrect, 1);
      expect(session.lastPlayedSan, isNull);
    });

    test('merkt sich bei einem Fehler, was gespielt wurde', () {
      final session = start().submitMove(Move.parse('d2d4')!, millis: 800);

      expect(session.phase, TrainingPhase.wrong);
      expect(session.movesCorrect, 0);
      expect(session.movesTotal, 1);
      expect(session.lastPlayedSan, 'd4');
      expect(session.attempts.single.expectedSan, 'e4');
    });

    test(
      'zeigt nach einem Fehler trotzdem den richtigen Zug und macht weiter',
      () {
        final session = start()
            .submitMove(Move.parse('d2d4')!, millis: 800)
            .advance();

        // Auf dem Brett steht e4 und die Antwort e5 — nicht der Fehlzug.
        expect(session.ply, 2);
        expect(session.expectedNode!.san, 'Nf3');
      },
    );

    test('zählt eine abgelaufene Zeit wie einen Fehler', () {
      final session = start().timeOut(millis: 3000);

      expect(session.phase, TrainingPhase.wrong);
      expect(session.attempts.single.correct, isFalse);
      expect(session.attempts.single.playedSan, isNull);
    });

    test('ignoriert Züge, solange die Rückmeldung steht', () {
      final after = start().submitMove(Move.parse('e2e4')!, millis: 800);
      final again = after.submitMove(Move.parse('d2d4')!, millis: 800);

      expect(again.movesTotal, 1);
    });

    test('meldet das Ende der Variante', () {
      var session = start();
      for (final uci in ['e2e4', 'g1f3', 'f1b5']) {
        session = session.submitMove(Move.parse(uci)!, millis: 800).advance();
      }

      expect(session.phase, TrainingPhase.lineComplete);
      expect(session.movesCorrect, 3);
    });

    test('geht zur nächsten Variante und setzt die Zähler zurück', () {
      final zweite = _line(
        tree: const RepertoireTree.empty().withSanLine(['d4', 'd5', 'c4']),
        repertoireId: 2,
      );

      var session = start(lines: [_line(), zweite]);
      for (final uci in ['e2e4', 'g1f3', 'f1b5']) {
        session = session.submitMove(Move.parse(uci)!, millis: 800).advance();
      }
      session = session.nextLine();

      expect(session.lineIndex, 1);
      expect(session.ply, 0);
      expect(session.lineCorrect, 0);
      expect(session.expectedNode!.san, 'd4');
      expect(session.results, hasLength(1));
    });

    test('ist nach der letzten Variante fertig', () {
      var session = start();
      for (final uci in ['e2e4', 'g1f3', 'f1b5']) {
        session = session.submitMove(Move.parse(uci)!, millis: 800).advance();
      }
      session = session.nextLine();

      expect(session.isFinished, isTrue);
      expect(session.results, hasLength(1));
    });

    test('ein leerer Plan ist sofort fertig', () {
      expect(start(lines: []).isFinished, isTrue);
    });

    test('der Fortschritt läuft von null auf eins', () {
      var session = start();
      expect(session.progress, 0);

      for (final uci in ['e2e4', 'g1f3', 'f1b5']) {
        session = session.submitMove(Move.parse(uci)!, millis: 800).advance();
      }
      expect(session.nextLine().progress, 1);
    });
  });

  group('Report', () {
    TrainingReport reportFor(List<String> moves) {
      var session = TrainingSessionState.start(
        mode: TrainingMode.smart,
        lines: [_line()],
        now: _now,
      );
      for (final uci in moves) {
        session = session.submitMove(Move.parse(uci)!, millis: 1000).advance();
      }
      return session.nextLine().report(_now.add(const Duration(minutes: 4)));
    }

    test('rechnet die Genauigkeit in Zügen', () {
      final report = reportFor(['e2e4', 'a2a3', 'f1b5']);

      expect(report.movesTotal, 3);
      expect(report.movesCorrect, 2);
      expect(report.accuracyPercent, 67);
    });

    test('zählt eine fehlerfreie Variante als gemeistert und gelernt', () {
      final report = reportFor(['e2e4', 'g1f3', 'f1b5']);

      expect(report.masteredCount, 1);
      expect(report.learnedCount, 1);
    });

    test('zwei von drei Zügen sind noch nicht gelernt', () {
      final report = reportFor(['e2e4', 'a2a3', 'f1b5']);

      // 67 % liegt unter der Schwelle von 75 %.
      expect(report.learnedCount, 0);
      expect(report.masteredCount, 0);
    });

    test('nennt die schwächsten Varianten', () {
      final report = reportFor(['e2e4', 'a2a3', 'a1a2']);

      expect(report.weakest, hasLength(1));
      expect(report.weakest.single.accuracy, closeTo(1 / 3, 0.001));
    });

    test('vergibt Erfahrungspunkte für Züge, Einheit und Meisterschaft', () {
      final sauber = reportFor(['e2e4', 'g1f3', 'f1b5']);
      final mitFehler = reportFor(['e2e4', 'a2a3', 'f1b5']);

      // 3 × 2 + 20 + 50 für die gemeisterte Variante.
      expect(sauber.xpEarned, 76);
      // 2 × 2 + 20, kein Meisterschaftsbonus.
      expect(mitFehler.xpEarned, 24);
    });

    test('merkt sich die Dauer', () {
      expect(reportFor(['e2e4']).duration, const Duration(minutes: 4));
    });
  });
}
