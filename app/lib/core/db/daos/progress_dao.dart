import 'package:drift/drift.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/db/tables.dart';

part 'progress_dao.g.dart';

@DriftAccessor(tables: [NodeProgress, Repertoires])
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  Future<List<NodeProgressData>> forRepertoire(int repertoireId) {
    return (select(
      nodeProgress,
    )..where((p) => p.repertoireId.equals(repertoireId))).get();
  }

  /// Fortschritt als Nachschlagetabelle — der Trainingsplaner braucht ihn
  /// zusammen mit dem Baum, und dort wird nach `pathHash` gesucht.
  Future<Map<String, NodeProgressData>> mapForRepertoire(
    int repertoireId,
  ) async {
    final rows = await forRepertoire(repertoireId);
    return {for (final row in rows) row.pathHash: row};
  }

  Future<NodeProgressData?> getOne(int repertoireId, String pathHash) {
    return (select(nodeProgress)..where(
          (p) =>
              p.repertoireId.equals(repertoireId) & p.pathHash.equals(pathHash),
        ))
        .getSingleOrNull();
  }

  /// Alle Züge, die bis [until] fällig sind — über alle Repertoires hinweg.
  Future<List<NodeProgressData>> due({DateTime? until, int? limit}) {
    final query = select(nodeProgress)
      ..where((p) => p.due.isSmallerOrEqualValue(until ?? DateTime.now()))
      ..orderBy([(p) => OrderingTerm(expression: p.due)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  Future<List<NodeProgressData>> dueForRepertoire(
    int repertoireId, {
    DateTime? until,
    int? limit,
  }) {
    final query = select(nodeProgress)
      ..where(
        (p) =>
            p.repertoireId.equals(repertoireId) &
            p.due.isSmallerOrEqualValue(until ?? DateTime.now()),
      )
      ..orderBy([(p) => OrderingTerm(expression: p.due)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  /// Wie viele Züge je Repertoire fällig sind — für die Zahlen auf der
  /// Startseite, ohne jeden Fortschritt einzeln zu laden.
  Stream<Map<int, int>> watchDueCounts({DateTime? until}) {
    final deadline = until ?? DateTime.now();
    final count = nodeProgress.pathHash.count();
    final query = selectOnly(nodeProgress)
      ..addColumns([nodeProgress.repertoireId, count])
      ..where(nodeProgress.due.isSmallerOrEqualValue(deadline))
      ..groupBy([nodeProgress.repertoireId]);

    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.read(nodeProgress.repertoireId)!: row.read(count) ?? 0,
      },
    );
  }

  /// Legt einen Fortschritt an oder ersetzt ihn.
  Future<void> upsert(NodeProgressData data) =>
      into(nodeProgress).insertOnConflictUpdate(data);

  Future<void> upsertAll(Iterable<NodeProgressData> rows) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(nodeProgress, rows.toList());
    });
  }

  /// Legt für neue Züge einen unberührten Fortschritt an. Bestehende Zeilen
  /// bleiben unangetastet — genau dafür ist der `pathHash` da.
  Future<int> ensureRows({
    required int repertoireId,
    required Iterable<String> pathHashes,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final existing = await forRepertoire(repertoireId);
    final known = {for (final row in existing) row.pathHash};
    final missing = pathHashes.where((h) => !known.contains(h)).toList();

    if (missing.isEmpty) return 0;

    await batch((batch) {
      batch.insertAll(nodeProgress, [
        for (final hash in missing)
          NodeProgressCompanion.insert(
            repertoireId: repertoireId,
            pathHash: hash,
            state: FsrsState.newCard,
            // Neue Züge sind sofort fällig: wer eine Eröffnung hinzufügt,
            // will sie jetzt lernen, nicht morgen.
            due: timestamp,
            updatedAt: timestamp,
          ),
      ], mode: InsertMode.insertOrIgnore);
    });

    return missing.length;
  }

  /// Räumt Fortschritt zu Zügen weg, die es nach einer Bearbeitung nicht mehr
  /// gibt.
  Future<int> pruneOrphans({
    required int repertoireId,
    required Set<String> livingHashes,
  }) async {
    final rows = await forRepertoire(repertoireId);
    final orphans = rows
        .map((r) => r.pathHash)
        .where((h) => !livingHashes.contains(h))
        .toList();

    if (orphans.isEmpty) return 0;

    await (delete(nodeProgress)..where(
          (p) => p.repertoireId.equals(repertoireId) & p.pathHash.isIn(orphans),
        ))
        .go();

    return orphans.length;
  }

  /// Setzt den Lernstand eines Repertoires zurück, ohne den Baum anzufassen.
  Future<void> reset(int repertoireId) => (delete(
    nodeProgress,
  )..where((p) => p.repertoireId.equals(repertoireId))).go();
}
