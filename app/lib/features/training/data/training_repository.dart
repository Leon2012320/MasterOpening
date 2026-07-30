import 'package:drift/drift.dart' show Value;
// Die Datenbank erzeugt aus der Tabelle TrainingAttempts ebenfalls eine
// Klasse TrainingAttempt. Gebraucht wird hier nur der Companion.
import 'package:masteropening/core/db/app_database.dart' hide TrainingAttempt;
import 'package:masteropening/core/db/daos/activity_dao.dart';
import 'package:masteropening/features/repertoire/data/repertoire_repository.dart';
import 'package:masteropening/features/training/domain/fsrs.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:masteropening/features/training/domain/training_session.dart';

/// Verbindet den Trainingsablauf mit der Datenbank.
///
/// Der Ablauf selbst kennt keine Datenbank — er liefert am Ende eine Liste von
/// Versuchen und einen Report. Hier wird daraus alles, was bleiben soll:
/// Lernstand je Zug, die Zeile der Einheit, die Versuche und der Tageswert.
class TrainingRepository {
  TrainingRepository(this._db);

  final AppDatabase _db;

  /// Lädt, woraus der Planer schöpfen kann.
  ///
  /// [repertoireId] `null` heisst: über alle Repertoires hinweg — das ist der
  /// Fall, wenn das Training von der Startseite aus beginnt.
  Future<List<TrainingSource>> loadSources({
    required RepertoireRepository repertoires,
    int? repertoireId,
  }) async {
    final rows = await _db.repertoireDao.getAll();
    final selected = repertoireId == null
        ? rows
        : rows.where((r) => r.id == repertoireId);

    final sources = <TrainingSource>[];
    for (final row in selected) {
      sources.add(
        TrainingSource(
          repertoireId: row.id,
          name: row.name,
          side: row.side,
          tree: repertoires.treeOf(row),
          progress: await _db.progressDao.mapForRepertoire(row.id),
        ),
      );
    }
    return sources;
  }

  /// Schreibt das Ergebnis einer Einheit fort.
  ///
  /// Läuft in einer Transaktion: entweder zählt die Einheit ganz oder gar
  /// nicht. Ein halb verbuchter Lernstand wäre schlimmer als keiner.
  Future<void> saveSession({
    required TrainingSessionState session,
    required TrainingReport report,
    required DateTime now,
    int? blitzSecondsPerMove,
  }) async {
    if (report.movesTotal == 0) return;

    // Fallen gehören zu keinem Repertoire; ihre Versuche zählen für Statistik
    // und Tageswert, bekommen aber keinen Lernstand.
    final tracked = session.attempts
        .where((a) => a.repertoireId != TrainingLine.noRepertoire)
        .toList();

    await _db.transaction(() async {
      await _applyProgress(tracked, now, blitzSecondsPerMove);

      final sessionId = await _db.trainingDao.insertSession(
        uuid: RepertoireRepository.newUuid(),
        mode: report.mode,
        startedAt: session.startedAt,
        endedAt: now,
        movesTotal: report.movesTotal,
        movesCorrect: report.movesCorrect,
        linesLearned: report.learnedCount,
        linesMastered: report.masteredCount,
        xpEarned: report.xpEarned,
        repertoireId: _singleRepertoire(session),
      );

      await _db.trainingDao.insertAttempts([
        for (final attempt in session.attempts)
          TrainingAttemptsCompanion.insert(
            sessionId: sessionId,
            repertoireId: attempt.repertoireId,
            pathHash: attempt.pathHash,
            expectedSan: attempt.expectedSan,
            playedSan: Value(attempt.playedSan),
            correct: attempt.correct,
            msTaken: attempt.millis,
            attemptedAt: now,
          ),
      ]);

      for (final id in tracked.map((a) => a.repertoireId).toSet()) {
        await _db.repertoireDao.markTrained(id, now: now);
      }

      await _db.activityDao.addToDay(
        day: ActivityDao.dayKey(now),
        xp: report.xpEarned,
        movesTrained: report.movesTotal,
        movesCorrect: report.movesCorrect,
        secondsStudied: report.duration.inSeconds,
        sessions: 1,
        linesMastered: report.masteredCount,
      );
    });
  }

  /// Rechnet jeden Versuch durch das FSRS-Verfahren und schreibt den neuen
  /// Lernstand zurück.
  Future<void> _applyProgress(
    List<TrainingAttempt> attempts,
    DateTime now,
    int? blitzSecondsPerMove,
  ) async {
    // Ein Zug kann in einer Einheit mehrfach vorkommen; die Versuche werden
    // der Reihe nach verrechnet, damit der Lernstand dem Verlauf folgt.
    final cache = <(int, String), FsrsCard>{};

    for (final attempt in attempts) {
      final key = (attempt.repertoireId, attempt.pathHash);
      var card = cache[key];

      if (card == null) {
        final row = await _db.progressDao.getOne(
          attempt.repertoireId,
          attempt.pathHash,
        );
        card = row == null
            ? FsrsCard.fresh(now)
            : FsrsCard(
                state: row.state,
                stability: row.stability,
                difficulty: row.difficulty,
                due: row.due,
                lastReview: row.lastReview,
                reps: row.reps,
                lapses: row.lapses,
              );
      }

      final rating = Fsrs.ratingFor(
        correct: attempt.correct,
        millis: attempt.millis,
        // Im Blitz-Modus ist die Zeitvorgabe der Massstab, nicht die
        // gewohnten vier Sekunden.
        expectedMillis: blitzSecondsPerMove == null
            ? 4000
            : blitzSecondsPerMove * 1000,
      );

      cache[key] = Fsrs.review(card, rating, now: now);
    }

    for (final entry in cache.entries) {
      final (repertoireId, pathHash) = entry.key;
      final card = entry.value;
      final previous = await _db.progressDao.getOne(repertoireId, pathHash);

      final correct = attempts
          .where(
            (a) =>
                a.repertoireId == repertoireId &&
                a.pathHash == pathHash &&
                a.correct,
          )
          .length;
      final wrong = attempts
          .where(
            (a) =>
                a.repertoireId == repertoireId &&
                a.pathHash == pathHash &&
                !a.correct,
          )
          .length;

      await _db.progressDao.upsert(
        NodeProgressData(
          repertoireId: repertoireId,
          pathHash: pathHash,
          state: card.state,
          stability: card.stability,
          difficulty: card.difficulty,
          due: card.due,
          lastReview: card.lastReview,
          reps: card.reps,
          lapses: card.lapses,
          correctCount: (previous?.correctCount ?? 0) + correct,
          wrongCount: (previous?.wrongCount ?? 0) + wrong,
          updatedAt: now,
        ),
      );
    }
  }

  /// Die Repertoire-ID, wenn die Einheit nur eines betraf — sonst `null`.
  static int? _singleRepertoire(TrainingSessionState session) {
    final ids = session.attempts
        .map((a) => a.repertoireId)
        .where((id) => id != TrainingLine.noRepertoire)
        .toSet();
    return ids.length == 1 ? ids.single : null;
  }
}
