import 'package:dartchess/dartchess.dart' show Move, Side;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/activity_dao.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/repertoire/data/repertoire_repository.dart';
import 'package:masteropening/features/training/data/training_repository.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:masteropening/features/training/domain/training_session.dart';

final _now = DateTime(2026, 7, 30, 20);

void main() {
  late AppDatabase db;
  late RepertoireRepository repertoires;
  late TrainingRepository training;
  late int repertoireId;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    repertoires = RepertoireRepository(db);
    training = TrainingRepository(db);

    repertoireId = await repertoires.create(
      name: 'Spanisch',
      side: Side.white,
      tree: const RepertoireTree.empty().withSanLine([
        'e4',
        'e5',
        'Nf3',
        'Nc6',
        'Bb5',
      ]),
      source: RepertoireSource.manual,
      now: _now.subtract(const Duration(days: 1)),
    );
  });

  tearDown(() => db.close());

  /// Spielt eine Einheit durch und schreibt sie fort.
  Future<TrainingReport> play(List<String> uciMoves) async {
    final sources = await training.loadSources(repertoires: repertoires);
    final plan = TrainingPlanner.build(
      sources: sources,
      options: PlannerOptions(mode: TrainingMode.smart, now: _now),
    );

    var session = TrainingSessionState.start(
      mode: TrainingMode.smart,
      lines: plan,
      now: _now,
    );
    for (final uci in uciMoves) {
      session = session.submitMove(Move.parse(uci)!, millis: 1500).advance();
    }
    session = session.nextLine();

    final report = session.report(_now.add(const Duration(minutes: 3)));
    await training.saveSession(
      session: session,
      report: report,
      now: _now.add(const Duration(minutes: 3)),
    );
    return report;
  }

  test('der Planer findet die Variante des Repertoires', () async {
    final sources = await training.loadSources(repertoires: repertoires);
    final plan = TrainingPlanner.build(
      sources: sources,
      options: PlannerOptions(mode: TrainingMode.smart, now: _now),
    );

    expect(plan, hasLength(1));
    expect(plan.single.repertoireName, 'Spanisch');
    expect(plan.single.ownMoves.map((n) => n.san), ['e4', 'Nf3', 'Bb5']);
  });

  test('lädt nur das verlangte Repertoire', () async {
    await repertoires.create(
      name: 'Najdorf',
      side: Side.black,
      tree: const RepertoireTree.empty().withSanLine(['e4', 'c5']),
      source: RepertoireSource.manual,
    );

    final alle = await training.loadSources(repertoires: repertoires);
    final eines = await training.loadSources(
      repertoires: repertoires,
      repertoireId: repertoireId,
    );

    expect(alle, hasLength(2));
    expect(eines, hasLength(1));
    expect(eines.single.name, 'Spanisch');
  });

  test('schreibt jeden Versuch in die Datenbank', () async {
    await play(['e2e4', 'a2a3', 'f1b5']);

    final attempts = await db.select(db.trainingAttempts).get();
    expect(attempts, hasLength(3));
    expect(attempts.where((a) => a.correct), hasLength(2));

    final falsch = attempts.firstWhere((a) => !a.correct);
    expect(falsch.expectedSan, 'Nf3');
    expect(falsch.playedSan, 'a3');
    expect(falsch.msTaken, 1500);
  });

  test('legt die Zeile der Einheit mit allen Kennzahlen an', () async {
    final report = await play(['e2e4', 'g1f3', 'f1b5']);

    final sessions = await db.trainingDao.recentSessions();
    expect(sessions, hasLength(1));

    final row = sessions.single;
    expect(row.mode, TrainingMode.smart);
    expect(row.movesTotal, 3);
    expect(row.movesCorrect, 3);
    expect(row.linesMastered, 1);
    expect(row.xpEarned, report.xpEarned);
    expect(row.durationSeconds, 180);
    expect(row.repertoireId, repertoireId);
  });

  test('rückt den Lernstand richtiger Züge in die Zukunft', () async {
    final vorher = await db.progressDao.mapForRepertoire(repertoireId);
    final e4 = RepertoireTree.hashFor(RepertoireTree.initialFen, ['e2e4']);
    expect(vorher[e4]!.state, FsrsState.newCard);

    await play(['e2e4', 'g1f3', 'f1b5']);

    final nachher = await db.progressDao.mapForRepertoire(repertoireId);
    expect(nachher[e4]!.state, isNot(FsrsState.newCard));
    expect(nachher[e4]!.due.isAfter(_now), isTrue);
    expect(nachher[e4]!.correctCount, 1);
    expect(nachher[e4]!.wrongCount, 0);
    expect(nachher[e4]!.reps, 1);
  });

  test('holt einen falschen Zug sofort zurück', () async {
    await play(['e2e4', 'a2a3', 'f1b5']);

    final nf3 = RepertoireTree.hashFor(RepertoireTree.initialFen, [
      'e2e4',
      'e7e5',
      'g1f3',
    ]);
    final row = (await db.progressDao.mapForRepertoire(repertoireId))[nf3]!;

    expect(row.wrongCount, 1);
    expect(row.lapses, 1);
    // Nicht auf Tage vertagt, sondern in Minuten wieder dran.
    expect(row.due.difference(_now).inHours, lessThan(1));
  });

  test('zählt den Tageswert hoch', () async {
    final report = await play(['e2e4', 'g1f3', 'f1b5']);

    final day = await db.activityDao.forDay(
      ActivityDao.dayKey(_now.add(const Duration(minutes: 3))),
    );

    expect(day, isNotNull);
    expect(day!.movesTrained, 3);
    expect(day.movesCorrect, 3);
    expect(day.sessions, 1);
    expect(day.linesMastered, 1);
    expect(day.xp, report.xpEarned);
    expect(day.secondsStudied, 180);
  });

  test('summiert zwei Einheiten am selben Tag', () async {
    await play(['e2e4', 'g1f3', 'f1b5']);
    await play(['e2e4', 'g1f3', 'f1b5']);

    final day = await db.activityDao.forDay(
      ActivityDao.dayKey(_now.add(const Duration(minutes: 3))),
    );

    expect(day!.sessions, 2);
    expect(day.movesTrained, 6);
  });

  test('vermerkt, wann das Repertoire zuletzt trainiert wurde', () async {
    expect(
      (await db.repertoireDao.getById(repertoireId))!.lastTrainedAt,
      isNull,
    );

    await play(['e2e4', 'g1f3', 'f1b5']);

    expect(
      (await db.repertoireDao.getById(repertoireId))!.lastTrainedAt,
      isNotNull,
    );
  });

  test('eine Einheit ohne Züge wird nicht verbucht', () async {
    final session = TrainingSessionState.start(
      mode: TrainingMode.smart,
      lines: const [],
      now: _now,
    );
    await training.saveSession(
      session: session,
      report: session.report(_now),
      now: _now,
    );

    expect(await db.trainingDao.recentSessions(), isEmpty);
    expect(await db.activityDao.forDay(ActivityDao.dayKey(_now)), isNull);
  });

  test('zählt die Fehler je Zug für die Fehlerstatistik', () async {
    await play(['e2e4', 'a2a3', 'f1b5']);
    await play(['e2e4', 'a2a3', 'f1b5']);

    final counts = await db.trainingDao.wrongCountsFor(repertoireId);
    final nf3 = RepertoireTree.hashFor(RepertoireTree.initialFen, [
      'e2e4',
      'e7e5',
      'g1f3',
    ]);

    expect(counts[nf3], 2);
  });
}
