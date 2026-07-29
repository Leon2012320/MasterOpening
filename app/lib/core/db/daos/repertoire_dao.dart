import 'package:dartchess/dartchess.dart' show Side;
import 'package:drift/drift.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/db/tables.dart';

part 'repertoire_dao.g.dart';

@DriftAccessor(tables: [Repertoires, NodeProgress])
class RepertoireDao extends DatabaseAccessor<AppDatabase>
    with _$RepertoireDaoMixin {
  RepertoireDao(super.db);

  /// Alle aktiven Repertoires in Sortierreihenfolge. Als Stream, damit die
  /// Startseite ohne eigenes Nachladen aktuell bleibt.
  Stream<List<Repertoire>> watchAll({bool includeArchived = false}) {
    final query = select(repertoires)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy([
        (r) => OrderingTerm(expression: r.sortOrder),
        (r) => OrderingTerm(expression: r.createdAt),
      ]);
    if (!includeArchived) {
      query.where((r) => r.isArchived.equals(false));
    }
    return query.watch();
  }

  Future<List<Repertoire>> getAll({bool includeArchived = false}) =>
      watchAll(includeArchived: includeArchived).first;

  Stream<Repertoire?> watchById(int id) =>
      (select(repertoires)..where((r) => r.id.equals(id))).watchSingleOrNull();

  Future<Repertoire?> getById(int id) =>
      (select(repertoires)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<Repertoire?> getByUuid(String uuid) => (select(
    repertoires,
  )..where((r) => r.uuid.equals(uuid))).getSingleOrNull();

  /// Ob eine Bibliothekseröffnung schon übernommen wurde.
  Future<Repertoire?> findBySource(RepertoireSource source, String ref) {
    return (select(repertoires)
          ..where(
            (r) =>
                r.source.equalsValue(source) &
                r.sourceRef.equals(ref) &
                r.deletedAt.isNull(),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertRepertoire({
    required String uuid,
    required String name,
    required Side side,
    required String pgn,
    required String startFen,
    required RepertoireSource source,
    String? sourceRef,
    String ecoCodes = '',
    int nodeCount = 0,
    int lineCount = 0,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final nextOrder = await _nextSortOrder();

    return into(repertoires).insert(
      RepertoiresCompanion.insert(
        uuid: uuid,
        createdAt: timestamp,
        updatedAt: timestamp,
        name: name,
        side: side,
        pgn: pgn,
        startFen: startFen,
        source: source,
        sourceRef: Value(sourceRef),
        ecoCodes: Value(ecoCodes),
        sortOrder: Value(nextOrder),
        nodeCount: Value(nodeCount),
        lineCount: Value(lineCount),
      ),
    );
  }

  /// Schreibt den Baum zurück. Jede Änderung erhöht die Revision, damit der
  /// Abgleich später erkennt, welche Seite neuer ist.
  Future<void> updateTree(
    int id, {
    required String pgn,
    required int nodeCount,
    required int lineCount,
    String? ecoCodes,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    await (update(repertoires)..where((r) => r.id.equals(id))).write(
      RepertoiresCompanion(
        pgn: Value(pgn),
        nodeCount: Value(nodeCount),
        lineCount: Value(lineCount),
        ecoCodes: ecoCodes == null ? const Value.absent() : Value(ecoCodes),
        updatedAt: Value(timestamp),
        revision: Value(await _bumpedRevision(id)),
      ),
    );
  }

  Future<void> rename(int id, String name, {DateTime? now}) async {
    await (update(repertoires)..where((r) => r.id.equals(id))).write(
      RepertoiresCompanion(
        name: Value(name),
        updatedAt: Value(now ?? DateTime.now()),
        revision: Value(await _bumpedRevision(id)),
      ),
    );
  }

  Future<void> setArchived(
    int id, {
    required bool archived,
    DateTime? now,
  }) async {
    await (update(repertoires)..where((r) => r.id.equals(id))).write(
      RepertoiresCompanion(
        isArchived: Value(archived),
        updatedAt: Value(now ?? DateTime.now()),
        revision: Value(await _bumpedRevision(id)),
      ),
    );
  }

  Future<void> markTrained(int id, {DateTime? now}) async {
    final timestamp = now ?? DateTime.now();
    await (update(repertoires)..where((r) => r.id.equals(id))).write(
      RepertoiresCompanion(lastTrainedAt: Value(timestamp)),
    );
  }

  /// Weiches Löschen: die Zeile bleibt, damit der Abgleich sie auf anderen
  /// Geräten ebenfalls entfernen kann, statt sie zurückzuspielen.
  Future<void> softDelete(int id, {DateTime? now}) async {
    final timestamp = now ?? DateTime.now();
    await (update(repertoires)..where((r) => r.id.equals(id))).write(
      RepertoiresCompanion(
        deletedAt: Value(timestamp),
        updatedAt: Value(timestamp),
        revision: Value(await _bumpedRevision(id)),
      ),
    );
  }

  /// Bringt die Reihenfolge in den Stand, den der Nutzer im Bearbeitungsmodus
  /// hergestellt hat.
  Future<void> reorder(List<int> idsInOrder, {DateTime? now}) async {
    final timestamp = now ?? DateTime.now();
    await batch((batch) {
      for (var i = 0; i < idsInOrder.length; i++) {
        batch.update(
          repertoires,
          RepertoiresCompanion(
            sortOrder: Value(i),
            updatedAt: Value(timestamp),
          ),
          where: (r) => r.id.equals(idsInOrder[i]),
        );
      }
    });
  }

  /// Entfernt eine Zeile endgültig. Nur für den Datenschutz-Fall „alles
  /// löschen"; der Normalweg ist [softDelete].
  Future<void> purge(int id) async {
    await (delete(repertoires)..where((r) => r.id.equals(id))).go();
  }

  Future<int> _nextSortOrder() async {
    final maxOrder = repertoires.sortOrder.max();
    final row = await (selectOnly(
      repertoires,
    )..addColumns([maxOrder])).getSingleOrNull();
    return (row?.read(maxOrder) ?? -1) + 1;
  }

  Future<int> _bumpedRevision(int id) async {
    final current = await getById(id);
    return (current?.revision ?? 0) + 1;
  }
}
