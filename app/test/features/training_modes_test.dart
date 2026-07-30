import 'dart:math';

import 'package:dartchess/dartchess.dart' show Move, Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/training/data/trap_repository.dart';
import 'package:masteropening/features/training/domain/opening_trap.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:masteropening/features/training/domain/training_session.dart';

import '../helpers/asset_bundle.dart';

final _now = DateTime(2026, 7, 30, 20);

/// Ein Repertoire mit drei Varianten, jede fünf Halbzüge lang.
RepertoireTree _tree() => const RepertoireTree.empty()
    .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'])
    .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bc4'])
    .withSanLine(['e4', 'c5', 'Nf3', 'd6', 'd4']);

TrainingSource _source({RepertoireTree? tree}) => TrainingSource(
  repertoireId: 1,
  name: 'Weiß',
  side: Side.white,
  tree: tree ?? _tree(),
  progress: const {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Puzzle-Modus', () {
    test('beginnt mitten in der Variante', () {
      final plan = TrainingPlanner.build(
        sources: [_source()],
        options: PlannerOptions(
          mode: TrainingMode.puzzle,
          now: _now,
          random: Random(7),
        ),
      );

      expect(plan, isNotEmpty);
      for (final line in plan) {
        // Der erste eigene Zug wäre kein Puzzle, sondern die Eröffnung selbst.
        expect(line.askFromPly, greaterThan(0));
      }
    });

    test('fragt genau einen Zug ab', () {
      final plan = TrainingPlanner.build(
        sources: [_source()],
        options: PlannerOptions(
          mode: TrainingMode.puzzle,
          now: _now,
          random: Random(3),
        ),
      );

      // Die Aufgabe ist der Zug direkt nach askFromPly; alles davor spielt
      // die App vor.
      final line = plan.first;
      expect(line.ownMoves, hasLength(lessThanOrEqualTo(2)));
      expect(line.ownMoves.first.ply, greaterThan(line.askFromPly));
    });

    test('stellt die vorgespielten Züge schon aufs Brett', () {
      final plan = TrainingPlanner.build(
        sources: [_source()],
        options: PlannerOptions(
          mode: TrainingMode.puzzle,
          now: _now,
          random: Random(11),
        ),
      );
      final session = TrainingSessionState.start(
        mode: TrainingMode.puzzle,
        lines: [plan.first],
        now: _now,
      );

      expect(session.ply, plan.first.askFromPly);
      expect(session.phase, TrainingPhase.awaitingMove);
      expect(session.fen, isNot(RepertoireTree.initialFen));
    });

    test('liefert bei anderem Zufall andere Aufgaben', () {
      List<String> idsWith(int seed) => TrainingPlanner.build(
        sources: [_source()],
        options: PlannerOptions(
          mode: TrainingMode.puzzle,
          now: _now,
          random: Random(seed),
        ),
      ).map((l) => l.id).toList();

      expect(idsWith(1), isNot(idsWith(42)));
    });
  });

  group('Variantentraining', () {
    test('übt genau die Variante, in der der Zug vorkommt', () {
      final tree = _tree();
      final bc4 = tree.nodeAtUciPath([
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
        'f1c4',
      ])!;

      final plan = TrainingPlanner.single(
        source: _source(tree: tree),
        pathHash: bc4.pathHash,
      );

      expect(plan, hasLength(1));
      expect(plan.single.line.nodes.last.san, 'Bc4');
      expect(plan.single.askFromPly, 0);
    });

    test('nimmt die kürzeste Variante durch diesen Zug', () {
      // Zwei Varianten laufen über Sf3, eine kurze und eine lange.
      final tree = const RepertoireTree.empty()
          .withSanLine(['e4', 'e5', 'Nf3', 'd6'])
          .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6', 'Ba4']);
      final nf3 = tree.nodeAtUciPath(['e2e4', 'e7e5', 'g1f3'])!;

      final plan = TrainingPlanner.single(
        source: _source(tree: tree),
        pathHash: nf3.pathHash,
      );

      expect(plan.single.length, 4);
    });

    test('liefert nichts für einen unbekannten Zug', () {
      expect(
        TrainingPlanner.single(source: _source(), pathHash: 'gibt es nicht'),
        isEmpty,
      );
    });
  });

  group('Eröffnungsfallen', () {
    late List<OpeningTrap> traps;

    setUpAll(() async {
      traps = await TrapRepository(bundle: FileAssetBundle()).all();
    });

    test('es sind genug Fallen für beide Farben da', () {
      expect(traps.length, greaterThanOrEqualTo(20));
      expect(traps.where((t) => t.side == Side.white).length, greaterThan(8));
      expect(traps.where((t) => t.side == Side.black).length, greaterThan(8));
    });

    test('jede Kennung kommt nur einmal vor', () {
      expect(traps.map((t) => t.id).toSet(), hasLength(traps.length));
    });

    test('jede Falle ist vollständig legal spielbar', () {
      final broken = <String>[];
      for (final trap in traps) {
        final result = PgnIo.parse(trap.pgn);
        if (result.warnings.isNotEmpty) {
          broken.add('${trap.id}: ${result.warnings.join(' | ')}');
        }
      }
      expect(broken, isEmpty, reason: broken.join('\n'));
    });

    test('nach dem Fallenzug ist der Nutzer am Zug', () {
      for (final trap in traps) {
        final line = PgnIo.parse(trap.pgn).tree.lines().single;

        expect(
          line.length,
          greaterThan(trap.askFromPly),
          reason: '${trap.id}: keine Widerlegung im Baum',
        );

        final firstAsked = line.nodes[trap.askFromPly];
        expect(
          firstAsked.movedBy,
          trap.side,
          reason: '${trap.id}: der erste abgefragte Zug gehört dem Gegner',
        );
      }
    });

    test('jede Falle hat Namen und Erklärung in beiden Sprachen', () {
      for (final trap in traps) {
        expect(trap.name('de'), isNotEmpty, reason: trap.id);
        expect(trap.name('en'), isNotEmpty, reason: trap.id);
        expect(trap.why('de').length, greaterThan(40), reason: trap.id);
        expect(trap.why('en').length, greaterThan(40), reason: trap.id);
        expect(trap.eco, matches(RegExp(r'^[A-E]\d\d$')), reason: trap.id);
      }
    });

    test('werden zu Trainingsaufgaben ohne Lernstand', () async {
      final lines =
          await TrapRepository(
            bundle: FileAssetBundle(),
          ).asTrainingLines(
            sides: {Side.white},
            languageCode: 'de',
            maxLines: 4,
            random: Random(5),
          );

      expect(lines, hasLength(4));
      for (final line in lines) {
        expect(line.side, Side.white);
        expect(line.isTrap, isTrue);
        expect(line.hasProgress, isFalse);
        expect(line.trapExplanation, isNotEmpty);
      }
    });

    test('nur Fallen der gespielten Farben', () async {
      final lines =
          await TrapRepository(
            bundle: FileAssetBundle(),
          ).asTrainingLines(
            sides: {Side.black},
            languageCode: 'de',
            maxLines: 20,
            random: Random(5),
          );

      expect(lines, isNotEmpty);
      expect(lines.every((l) => l.side == Side.black), isTrue);
    });

    test('ohne Farbvorgabe kommen beide', () async {
      final lines =
          await TrapRepository(
            bundle: FileAssetBundle(),
          ).asTrainingLines(
            sides: const {},
            languageCode: 'de',
            maxLines: 25,
            random: Random(5),
          );

      expect(lines.map((l) => l.side).toSet(), hasLength(2));
    });

    test('der Ablauf beginnt bei der Widerlegung', () async {
      final lines =
          await TrapRepository(
            bundle: FileAssetBundle(),
          ).asTrainingLines(
            sides: {Side.white},
            languageCode: 'de',
            maxLines: 1,
            random: Random(5),
          );

      final session = TrainingSessionState.start(
        mode: TrainingMode.trap,
        lines: lines,
        now: _now,
      );

      expect(session.phase, TrainingPhase.awaitingMove);
      expect(session.ply, lines.single.askFromPly);
      expect(session.expectedNode!.movedBy, Side.white);
    });

    test('eine widerlegte Falle wird als gemeistert gezählt', () async {
      final lines =
          await TrapRepository(
            bundle: FileAssetBundle(),
          ).asTrainingLines(
            sides: {Side.white},
            languageCode: 'de',
            maxLines: 1,
            random: Random(5),
          );

      var session = TrainingSessionState.start(
        mode: TrainingMode.trap,
        lines: lines,
        now: _now,
      );

      // Immer den richtigen Zug spielen, bis die Falle durch ist.
      while (session.phase == TrainingPhase.awaitingMove) {
        final expected = Move.parse(session.expectedNode!.uci)!;
        session = session.submitMove(expected, millis: 1200).advance();
      }
      final report = session.nextLine().report(_now);

      expect(report.movesCorrect, report.movesTotal);
      expect(report.masteredCount, 1);
    });
  });

  group('Blitz-Modus', () {
    test('eine abgelaufene Zeit zählt als Fehler', () {
      final plan = TrainingPlanner.build(
        sources: [_source()],
        options: PlannerOptions(mode: TrainingMode.blitz, now: _now),
      );
      final session = TrainingSessionState.start(
        mode: TrainingMode.blitz,
        lines: plan,
        now: _now,
      ).timeOut(millis: 3000);

      expect(session.phase, TrainingPhase.wrong);
      expect(session.attempts.single.correct, isFalse);
      expect(session.attempts.single.playedSan, isNull);
      expect(session.attempts.single.millis, 3000);
    });
  });
}
