import 'package:drift/drift.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/tables.dart';

part 'lichess_dao.g.dart';

/// Die von Lichess importierten Partien.
@DriftAccessor(tables: [LichessGames])
class LichessDao extends DatabaseAccessor<AppDatabase> with _$LichessDaoMixin {
  LichessDao(super.db);

  /// Schreibt einen Schwung Partien; bereits vorhandene werden überschrieben.
  ///
  /// Der Import läuft absichtlich idempotent: Lichess liefert bei
  /// überlappenden Zeitfenstern dieselbe Partie erneut, und ein zweiter
  /// Import darf die Statistik nicht verdoppeln.
  Future<void> upsertAll(List<LichessGame> games) async {
    if (games.isEmpty) return;

    await batch((batch) {
      batch.insertAllOnConflictUpdate(lichessGames, games);
    });
  }

  /// Alle Partien, neueste zuerst.
  Future<List<LichessGame>> all() => (select(
    lichessGames,
  )..orderBy([_newestFirst])).get();

  Stream<List<LichessGame>> watchAll({int? limit}) {
    final query = select(lichessGames)..orderBy([_newestFirst]);
    if (limit != null) query.limit(limit);
    return query.watch();
  }

  Future<int> count() async {
    final expression = lichessGames.id.count();
    final row = await (selectOnly(
      lichessGames,
    )..addColumns([expression])).getSingle();
    return row.read(expression) ?? 0;
  }

  /// Der Zeitpunkt der jüngsten gespeicherten Partie — die Marke, ab der
  /// weiterimportiert wird.
  Future<DateTime?> latestPlayedAt() async {
    final row =
        await (select(lichessGames)
              ..orderBy([_newestFirst])
              ..limit(1))
            .getSingleOrNull();
    return row?.playedAt;
  }

  /// Beim Trennen des Kontos: die Partien gehören dem Konto, nicht der App.
  Future<void> clear() => delete(lichessGames).go();

  static OrderingTerm _newestFirst($LichessGamesTable t) =>
      OrderingTerm(expression: t.playedAt, mode: OrderingMode.desc);
}
