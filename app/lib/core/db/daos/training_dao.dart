import 'package:drift/drift.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/db/tables.dart';

part 'training_dao.g.dart';

@DriftAccessor(tables: [TrainingSessions, TrainingAttempts])
class TrainingDao extends DatabaseAccessor<AppDatabase>
    with _$TrainingDaoMixin {
  TrainingDao(super.db);

  /// Legt die Zeile für eine abgeschlossene Einheit an.
  Future<int> insertSession({
    required String uuid,
    required TrainingMode mode,
    required DateTime startedAt,
    required DateTime endedAt,
    required int movesTotal,
    required int movesCorrect,
    required int linesLearned,
    required int linesMastered,
    required int xpEarned,
    int? repertoireId,
  }) {
    return into(trainingSessions).insert(
      TrainingSessionsCompanion.insert(
        uuid: uuid,
        createdAt: startedAt,
        updatedAt: endedAt,
        mode: mode,
        startedAt: startedAt,
        endedAt: Value(endedAt),
        repertoireId: Value(repertoireId),
        movesTotal: Value(movesTotal),
        movesCorrect: Value(movesCorrect),
        linesLearned: Value(linesLearned),
        linesMastered: Value(linesMastered),
        xpEarned: Value(xpEarned),
        durationSeconds: Value(endedAt.difference(startedAt).inSeconds),
      ),
    );
  }

  Future<void> insertAttempts(List<TrainingAttemptsCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((batch) => batch.insertAll(trainingAttempts, rows));
  }

  /// Die letzten Einheiten, neueste zuerst — Grundlage des Genauigkeitsgraphen.
  Future<List<TrainingSession>> recentSessions({int limit = 30}) {
    return (select(trainingSessions)
          ..where((s) => s.endedAt.isNotNull())
          ..orderBy([
            (s) => OrderingTerm(
              expression: s.startedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .get();
  }

  Stream<List<TrainingSession>> watchRecentSessions({int limit = 30}) {
    return (select(trainingSessions)
          ..where((s) => s.endedAt.isNotNull())
          ..orderBy([
            (s) => OrderingTerm(
              expression: s.startedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .watch();
  }

  /// Wie oft ein bestimmter Zug schon danebenging — für die Anzeige der
  /// häufigen Fehler.
  Future<Map<String, int>> wrongCountsFor(int repertoireId) async {
    final count = trainingAttempts.id.count();
    final rows =
        await (selectOnly(trainingAttempts)
              ..addColumns([trainingAttempts.pathHash, count])
              ..where(
                trainingAttempts.repertoireId.equals(repertoireId) &
                    trainingAttempts.correct.equals(false),
              )
              ..groupBy([trainingAttempts.pathHash]))
            .get();

    return {
      for (final row in rows)
        row.read(trainingAttempts.pathHash)!: row.read(count) ?? 0,
    };
  }
}
